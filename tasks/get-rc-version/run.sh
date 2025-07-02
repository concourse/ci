#!/usr/bin/env bash

set -euo pipefail -x

apk --no-cache --no-progress add git

current_ref="$(git -C concourse rev-parse --short HEAD)"
printf "+%s" "${current_ref}" >> version/version
