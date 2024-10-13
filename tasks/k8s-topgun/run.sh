#!/usr/bin/env bash

set -euo pipefail

BUILD_DIR=$(pwd)
script_dir=${0%/*}
readonly SKIP="${SKIP:-}"

export GOPATH="${BUILD_DIR}/gopath"
export PATH=$GOPATH/bin:$PATH

mkdir -p "${HOME}/.kube"
cp "${BUILD_DIR}/kubeconfig/config" "${HOME}/.kube/config"

mkdir -p helm-charts/stable
cp -r prometheus-chart/prometheus helm-charts/stable
cp -r postgresql-chart/postgresql helm-charts/stable

export CONCOURSE_IMAGE_DIGEST="$(cat concourse-rc-image/digest)"
export CONCOURSE_IMAGE_TAG="$(cat concourse-rc-image/tag)"
export HELM_CHARTS_DIR="$(realpath ./helm-charts)"
export CONCOURSE_CHART_DIR="$(realpath ./concourse-chart)"

cd concourse

go mod download

ginkgo -nodes=8 \
  -race \
  -keep-going \
  -poll-progress-after=900s \
  -flake-attempts=3 \
  -skip="$SKIP" \
  ./topgun/k8s/ "$@"
