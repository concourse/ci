#!/usr/bin/env bash

set -euo pipefail

readonly HELPERS_DIR="ci/tasks/scripts"

export MAX_TICKS="${MAX_TICKS:-120}"
export ATC_URL="${ATC_URL:-"$(cat endpoint-info/instance_url)"}"

if [ -e endpoint-info/admin_username ]; then
  export ATC_ADMIN_USERNAME="$(cat endpoint-info/admin_username)"
else
  export ATC_ADMIN_USERNAME=admin
fi
if [ -e endpoint-info/admin_password ]; then
  export ATC_ADMIN_PASSWORD="$(cat endpoint-info/admin_password)"
else
  export ATC_ADMIN_PASSWORD=admin
fi

if [ -e endpoint-info/guest_username ]; then
  export ATC_GUEST_USERNAME="$(cat endpoint-info/guest_username)"
else
  export ATC_GUEST_USERNAME=guest
fi
if [ -e endpoint-info/guest_password ]; then
  export ATC_GUEST_PASSWORD="$(cat endpoint-info/guest_password)"
else
  export ATC_GUEST_PASSWORD=guest
fi

$HELPERS_DIR/wait-atc

if curl "$ATC_URL/api/v1/cli?arch=amd64&platform=linux" --fail -o /usr/local/bin/fly; then
  chmod +x /usr/local/bin/fly
else
  pushd concourse/fly
    go build -o /usr/local/bin/fly
  popd
fi

fly --version

$HELPERS_DIR/wait-worker

ci/tasks/watsjs/run.sh --serial --timeout="${MAX_TICKS}s" test/smoke.js
