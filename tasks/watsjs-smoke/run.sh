#!/usr/bin/env bash
# vim: set ft=sh

set -euo pipefail

export MAX_TICKS="${MAX_TICKS:-120}"

if [[ -z "${ATC_URL}" ]]; then
  echo "ATC_URL must be provided"
fi

./ci/tasks/helpers/wait-atc

if curl "$ATC_URL/api/v1/cli?arch=amd64&platform=linux" --fail -o /usr/local/bin/fly; then
  chmod +x /usr/local/bin/fly
else
  pushd concourse/fly
    go build -o /usr/local/bin/fly
  popd
fi

fly --version

./ci/tasks/helpers/wait-worker

./ci/tasks/helpers/watsjs --serial --timeout="${MAX_TICKS}s" test/smoke.js
