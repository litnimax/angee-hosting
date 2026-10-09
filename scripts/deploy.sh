#!/usr/bin/env bash
# Copy this repository to a host and apply its Salt states there, masterless.
#
#   scripts/deploy.sh root@192.168.139.180
#
# Ships the working tree's files that git does not ignore (tracked and new), so
# a host's stack state (.env, data/, sources/, workspaces/, runtime/, the
# compose file) is never sent and never touched. Nothing is deleted on the host:
# a file removed from the repository stays there until removed by hand.
# DEST must match the stack root declared in salt/pillar/angee.sls.
set -euo pipefail

target="${1:?usage: scripts/deploy.sh <ssh-target>}"
dest="${DEST:-/srv/angee-hosting}"
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

git -C "$repo_dir" ls-files -z --cached --others --exclude-standard \
  | while IFS= read -r -d '' path; do
      # Skip tracked files deleted from the working tree.
      if [ -e "$repo_dir/$path" ] || [ -L "$repo_dir/$path" ]; then printf '%s\0' "$path"; fi
    done \
  | tar -C "$repo_dir" --null -T - -czf - \
  | ssh "$target" "install -d -m 0755 '$dest' && tar -xzf - --no-same-owner -C '$dest'"
ssh "$target" "bash '$dest/scripts/bootstrap-salt.sh' && salt-call --local --state-output=mixed --state-verbose=False state.apply"
