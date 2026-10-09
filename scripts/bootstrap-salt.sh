#!/usr/bin/env bash
# Prepare this host as a masterless Salt minion whose state and pillar trees are
# the salt/ directory of the checkout this script lives in.
#
# Installs Salt's onedir packages from the Salt Project repository (they bundle
# their own Python, so the distro Python version does not matter), keeps the
# salt-minion daemon off (there is no master), and points file_roots and
# pillar_roots at this checkout. Idempotent; run as root.
#
#   SALT_VERSION=3007 scripts/bootstrap-salt.sh   # optional: pin a release line
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
salt_version="${SALT_VERSION:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "bootstrap-salt.sh must run as root" >&2
  exit 1
fi

if ! command -v salt-call >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -q
  apt-get install -y -q ca-certificates curl
  install -d -m 0755 /etc/apt/keyrings
  # The published key is ASCII-armored; apt only reads armored keys named *.asc.
  curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public \
    -o /etc/apt/keyrings/salt-archive-keyring.asc
  cat > /etc/apt/sources.list.d/salt.sources <<'EOF'
Types: deb
URIs: https://packages.broadcom.com/artifactory/saltproject-deb
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/salt-archive-keyring.asc
EOF
  if [ -n "$salt_version" ]; then
    printf 'Package: salt-*\nPin: version %s.*\nPin-Priority: 1001\n' "$salt_version" \
      > /etc/apt/preferences.d/salt-pin-1001
  fi
  # Mask before installing so the package's postinst cannot start a minion that
  # would search for a master.
  systemctl mask salt-minion.service
  apt-get update -q
  apt-get install -y -q salt-minion
fi

systemctl mask salt-minion.service >/dev/null 2>&1 || true

install -d -m 0755 /etc/salt/minion.d
cat > /etc/salt/minion.d/masterless.conf <<EOF
# Managed by ${repo_dir}/scripts/bootstrap-salt.sh
file_client: local
file_roots:
  base:
    - ${repo_dir}/salt/states
pillar_roots:
  base:
    - ${repo_dir}/salt/pillar
EOF

salt-call --version
