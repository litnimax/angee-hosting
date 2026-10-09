{%- from "angee/map.jinja" import angee with context %}
{%- set user = angee.user.name %}

include:
  - angee.docker
  - angee.cli
  - angee.images

angee-user:
  user.present:
    - name: {{ user }}
    - uid: {{ angee.user.uid }}
    - usergroup: True
    - groups:
      - docker
    - shell: /bin/bash
    - require:
      - pkg: angee-packages

{%- for name, stack in angee.stacks | dictsort %}

angee-stack-{{ name }}-manifest:
  file.exists:
    - name: {{ stack.root }}/angee.yaml

{#- Container-written state keeps the owner its writer gave it: data/ (Postgres
    and media), runtime/ (the image entrypoint owns it), node_modules/ (the deps job). #}
{%- set pruned = [] %}
{%- for state_dir in ("data", "runtime", "node_modules") %}
{%-   do pruned.append("-path " ~ stack.root ~ "/" ~ state_dir) %}
{%- endfor %}
{%- set find_foreign = "find " ~ stack.root ~ " -xdev \\( " ~ pruned | join(" -o ") ~ " \\) -prune -o ! -user " ~ user %}

# Everything else under the root belongs to the stack user: the project files a
# deploy copies in as root, and anything an earlier run left behind.
angee-stack-{{ name }}-ownership:
  cmd.run:
    - name: {{ (find_foreign ~ " -exec chown -h " ~ user ~ ": {} +") | yaml_squote }}
    - onlyif: {{ (find_foreign ~ " -print -quit | grep -q .") | yaml_squote }}
    - require:
      - user: angee-user
      - file: angee-stack-{{ name }}-manifest

{%- set up = angee.cli.bin_dir ~ "/angee --root " ~ stack.root ~ " dev -d" %}

# `angee dev -d` converges the whole stack: it renders the compose file,
# materializes sources and workspaces, starts every service, and waits for the
# job chain (provision, codegen, frontend build). It exits non-zero when a job
# fails, which fails this state.
angee-stack-{{ name }}-up:
  cmd.run:
    - name: {{ up }}
    - cwd: {{ stack.root }}
    - runas: {{ user }}
    - env:
      - ANGEE_JOB_TIMEOUT: {{ angee.job_timeout }}
    - require:
      - cmd: angee-stack-{{ name }}-ownership
      - sls: angee.docker
      - sls: angee.cli
      - sls: angee.images

# The operator's compose services carry no restart policy, so a boot unit runs
# the same convergence after Docker starts. Salt enables it; it does not start it.
angee-stack-{{ name }}-unit:
  file.managed:
    - name: /etc/systemd/system/angee-stack-{{ name }}.service
    - contents: |
        [Unit]
        Description=Angee stack {{ name }} ({{ stack.root }})
        Requires=docker.service
        After=docker.service network-online.target
        Wants=network-online.target

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        User={{ user }}
        WorkingDirectory={{ stack.root }}
        Environment=ANGEE_JOB_TIMEOUT={{ angee.job_timeout }}
        ExecStart={{ up }}
        TimeoutStartSec=infinity

        [Install]
        WantedBy=multi-user.target

# Salt's systemd module reloads the daemon when the unit file changed.
angee-stack-{{ name }}-boot:
  service.enabled:
    - name: angee-stack-{{ name }}
    - require:
      - file: angee-stack-{{ name }}-unit
      - cmd: angee-stack-{{ name }}-up
{%- endfor %}
