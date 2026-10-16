#!/usr/bin/env bash

set -euo pipefail -x

apk add --no-progress --no-cache cmd:sha256sum

helm plugin install --verify=false https://github.com/helm-unittest/helm-unittest.git

cd chart
helm unittest -f test/unittest/**/*.yaml .
