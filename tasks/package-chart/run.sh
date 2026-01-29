#!/usr/bin/env bash

set -euo pipefail -x

apk add --no-progress --no-cache helm

helm package -u -d ./packaged-chart ./concourse-chart
helm repo index --merge chart-repo-index/index.yaml ./packaged-chart
