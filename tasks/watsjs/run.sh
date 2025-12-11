#!/usr/bin/env bash

set -euo pipefail

retry() {
  local max_attempts=5
  local attempt=1
  local cmd="$@"

  until "$@"; do
    if (( attempt >= max_attempts )); then
      echo "command '$cmd' failed after $max_attempts attempts"
      exit 1
    fi
    echo "command '$cmd' failed (attempt $attempt/$max_attempts). retrying..."
    ((attempt++))
  done
}

cd concourse

# check if smoke tests already downloaded fly
if ! [ -e /usr/local/bin/fly ]; then
  go install ./fly
fi

cd web/wats

stty columns 80 # for better yarn output
corepack enable
retry yarn install

retry yarn test -v --color "$@"
