#!/usr/bin/env bash

set -euo pipefail

# for better yarn output
stty columns 80

retry() {
  local max_attempts=5
  local attempt=1
  local cmd="$@"

  until "$@"; do
    if (( attempt >= max_attempts )); then
      echo "Command '$cmd' failed after $max_attempts attempts"
      exit 1
    fi
    echo "Command '$cmd' failed (attempt $attempt/$max_attempts). Retrying..."
    ((attempt++))
  done
}

pushd concourse
  corepack enable
  retry yarn install
  retry yarn test
  retry yarn build
popd

cp -a ./concourse/. ./built-concourse
