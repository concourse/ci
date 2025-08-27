#!/usr/bin/env bash

set -euo pipefail -x

helm plugin install https://github.com/helm-unittest/helm-unittest.git

cd chart
helm unittest -f test/unittest/**/*.yaml .
