#!/bin/bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <remote/branch> [local-branch]"
  echo "Example: $0 origin/main"
  echo "Example: $0 origin/main my-feature"
  exit 1
fi

REMOTE_BRANCH="$1"
LOCAL_BRANCH="${2:-$(git rev-parse --abbrev-ref HEAD)}"

echo "Resetting '$LOCAL_BRANCH' to '$REMOTE_BRANCH'..."

git fetch "${REMOTE_BRANCH%%/*}"
git checkout "$LOCAL_BRANCH"
git reset --hard "$REMOTE_BRANCH"
git clean -fd

echo "Done. '$LOCAL_BRANCH' is now at $(git rev-parse --short HEAD)"
