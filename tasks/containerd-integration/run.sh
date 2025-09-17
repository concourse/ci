#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

source ci/tasks/scripts/cgroup-helpers.sh

main() {
  sanitize_cgroups
  run_test
}

run_test() {
  cd concourse

  go mod download

  # CGO is required for go test -race
  CGO_ENABLED=1 go test -v -race ./worker/runtime/integration
}

main
