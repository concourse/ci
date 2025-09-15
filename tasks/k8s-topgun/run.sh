#!/usr/bin/env bash

set -euo pipefail

readonly SKIP="${SKIP:-}"
readonly DIR=$(cd $(dirname $0) && pwd)

source "ci/tasks/scripts/k8s-helpers.sh"

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

gke_auth

mkdir -p helm-charts/stable
cp -r prometheus-chart/prometheus helm-charts/stable

export CONCOURSE_IMAGE_DIGEST="$(cat concourse-rc-image/digest)"
export CONCOURSE_IMAGE_TAG="$(cat concourse-rc-image/tag)"
export HELM_CHARTS_DIR="$(realpath ./helm-charts)"
export CONCOURSE_CHART_DIR="$(realpath ./concourse-chart)"

cd concourse

go mod download

go install github.com/onsi/ginkgo/v2/ginkgo

ginkgo -nodes=8 -race -keep-going -poll-progress-after=900s -flake-attempts=3 -skip="$SKIP" ./topgun/k8s/ "$@"
