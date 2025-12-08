#!/usr/bin/env bash

set -euo pipefail -x

apk --no-cache --no-progress add git

current_ref="$(git -C concourse rev-parse --short HEAD)"

latest_tag="$(git tag --sort=-v:refname | head -n 1)"
timestamp="$(date +%s)"

echo "${latest_tag//v/}+dev.${timestamp}.${current_ref}" > version/version
