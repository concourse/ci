#!/usr/bin/env bash

set -euo pipefail -x

helm plugin install --verify=false https://github.com/helm-unittest/helm-unittest.git

cd chart
helm unittest -f test/unittest/**/*.yaml .
