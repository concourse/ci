#!/usr/bin/env bash

set -euo -x pipefail

current_ref="$(git -C concourse rev-parse --short HEAD)"

latest_tag="$(git -C concourse describe --tags --abbrev=0 HEAD)"
timestamp="$(date +%s)"

echo "${latest_tag//v/}+dev.${timestamp}.${current_ref}" > version/version
