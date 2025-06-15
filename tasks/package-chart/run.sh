#!/usr/bin/env bash

set -euo pipefail -x

helm package -u -d ./packaged-chart ./concourse-chart
helm repo index --merge chart-repo-index/index.yaml ./packaged-chart
