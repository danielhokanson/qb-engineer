#!/usr/bin/env bash
#
# bootstrap.sh — clone all qb-engineer sibling repos as siblings of this one.
#
# Run from inside the qb-engineer/ directory after a fresh clone.
# Idempotent: skips repos that already exist; runs `git pull` instead.

set -euo pipefail

OWNER="danielhokanson"
SIBLINGS=(qb-engineer-ui qb-engineer-server qb-engineer-deploy qb-engineer-test)

# We expect to be inside qb-engineer/, so siblings go in ../
PARENT_DIR="$(cd .. && pwd)"

echo "Bootstrapping qb-engineer siblings into: $PARENT_DIR"
echo

for repo in "${SIBLINGS[@]}"; do
  target="$PARENT_DIR/$repo"
  if [[ -d "$target/.git" ]]; then
    echo "  $repo: already cloned, pulling latest"
    (cd "$target" && git pull --ff-only) || echo "    (skipped — local changes?)"
  else
    echo "  $repo: cloning"
    git clone "https://github.com/$OWNER/$repo.git" "$target"
  fi
done

echo
echo "Done. Sibling layout:"
ls -d "$PARENT_DIR"/qb-engineer*
echo
echo "Next: cd ../qb-engineer-deploy && ./setup.sh"
