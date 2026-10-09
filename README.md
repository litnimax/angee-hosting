# angee-hosting

Hosting control panel for [Angee](https://github.com/ang-ee/angee-django)
stacks, built on angee-django, and the masterless SaltStack formula that
deploys it.

The repository root is an Angee stack root **and** the project host
(`ANGEE_ROOT=.`), rendered from angee-django's `stacks/dev` template in Docker
mode with a production serve path:

```sh
angee init . -t dev -y \
  --input project_name=angee-hosting --input "project_title=Angee Hosting" \
  --input addon_namespace=angee_hosting \
  --input runtime_mode=docker --input serve_mode=production
```

## Layout

```text
angee.yaml, manage.py, settings.yaml,     # the rendered project host + stack manifest
pyproject.toml, package.json, web/
addons/angee_hosting/hosting/             # the hosting addon (consumer addon)
salt/states/angee/                        # Salt formula: docker, angee CLI, stacks
salt/pillar/angee.sls                     # which stacks this host runs
scripts/bootstrap-salt.sh                 # install Salt, configure masterless minion
scripts/deploy.sh                         # copy the repo to a host and apply Salt
```

## The hosting addon

`angee_hosting.hosting` adds a **Hosting** menu with two console resources:

- **Servers** — hosts the Salt formula manages: SSH address/user/port, CPU
  architecture, the pinned angee CLI version, lifecycle status.
- **Stacks** — Angee stack roots on a server: name, `ANGEE_ROOT`, domain,
  lifecycle status.

Both are admin-only (`permissions.zed`: platform admins and `hosting_admin`
role members). A server renders its stacks as the formula's pillar:

```sh
python manage.py hosting_salt_pillar angee-host-1
```

```yaml
angee:
  cli:
    version: v0.18.0
  stacks:
    angee-hosting:
      root: /srv/angee-hosting
```

The demo tier seeds the local VM (`angee-host-1`) and this panel's own stack.

## Deploy (masterless Salt)

Requirements on the target: Ubuntu (tested on 26.04 arm64), root SSH access.

```sh
scripts/deploy.sh root@192.168.139.180
```

`deploy.sh` streams the working tree's non-ignored files (`git ls-files
--cached --others --exclude-standard`) to `/srv/angee-hosting` over SSH, runs
`scripts/bootstrap-salt.sh`, then `salt-call --local state.apply`. The host's
stack state (`.env`, `data/`, `sources/`, `workspaces/`, `runtime/`) is never
sent and never touched; nothing is deleted on the host, so a file removed from
the repository must be removed there by hand. (It deliberately avoids
`rsync --delete`: macOS's bundled openrsync deletes receiver files excluded by
a `.gitignore` filter, which wipes the stack's secrets and database.)

`bootstrap-salt.sh` installs Salt's onedir packages from the Salt Project
repository, masks the `salt-minion` daemon (there is no master), and points
`file_roots`/`pillar_roots` at the checkout's `salt/` directory. Re-run states
on the host with:

```sh
salt-call --local state.apply
```

Each apply re-runs the stack's job chain and restarts Django, so expect a short
interruption (about a minute).

The `angee` formula (`salt/states/angee`, defaults in `defaults.yaml`):

| state | does |
|---|---|
| `angee.docker` | installs git, `docker.io`, `docker-compose-v2`, `docker-buildx`; runs Docker |
| `angee.cli` | installs the `angee` and `angee-operator` release binaries (checksum-verified) |
| `angee.images` | on non-amd64 hosts, pulls amd64-only images (`django-angee-base`) with an explicit platform and ensures binfmt emulation |
| `angee.stacks` | creates the stack user `angee` (uid 1000, `docker` group); for every pillar stack hands the root to it, runs `angee --root <root> dev -d` as it, and enables a boot unit `angee-stack-<name>.service` |

`angee dev -d` brings the whole stack up in containers and waits for its job
chain (provision, operator schema, codegen, frontend build); a failed job fails
the state. The stack user's uid must be 1000: the Python images run as uid 1000
and write both the project root and the framework workspace the CLI cuts. On a
host where uid 1000 already belongs to another account, set `angee:user:name`
in the pillar to that account.

## After deploy

- App: `http://<host>:5173` (Caddy serving the built SPA).
- Login: `admin` / `admin` (demo data from `angee provision --demo`). Change
  it on anything reachable by others.
- Operator: `http://127.0.0.1:9000` on the host. Run the CLI as the stack user:
  `sudo -u angee angee --root /srv/angee-hosting secret reveal operator-token`.
- Restart the application through the operator:
  `sudo -u angee angee --root /srv/angee-hosting job run deps --chained-restart`.

## Known constraints

- `ghcr.io/ang-ee/django-angee-base` is published for amd64 only, so arm64
  hosts run the Python services under emulation.
- `stacks/local` (the "instance" template) does not work with the published
  `ghcr.io/ang-ee/angee-web:latest` image (it ships no `@angee/*` packages), which
  is why this project uses the `dev` template in Docker mode.
- The operator re-serializes `angee.yaml`; a block scalar that begins with a
  blank line comes back as invalid YAML (`yaml: line N: did not find expected
  '-' indicator`). The committed manifest has that blank line removed from the
  `frontend` command.
- `sources.angee.default_ref` tracks angee-django `main`, and no lockfiles are
  committed: each host resolves `uv.lock` and `pnpm-lock.yaml` fresh.
- `angee.images` pulls an amd64-only image once; to refresh `:latest`,
  `docker rmi` it and re-apply.
- `settings.yaml` keeps the template's `DEBUG: true`; override with
  `YAMLCONF_DEBUG` on the Django service once static serving with DEBUG off is
  verified.
- The operator only allows the `http://localhost:5173` origin; the operator
  console opened through the host's IP may be rejected.
