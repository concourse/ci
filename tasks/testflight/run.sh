#!/usr/bin/env bash

set -uo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

cd concourse

go mod download

go install github.com/onsi/ginkgo/v2/ginkgo

if ! ginkgo -r -nodes=4 --race --keep-going --poll-progress-after=15s --flake-attempts=3 ./testflight "$@"; then
  echo "Tests failed. Saving docker compose logs..."
  docker compose logs web > ../web.log
  docker compose logs worker > ../worker.log
  docker compose logs db > ../db.log
  exit 1
fi
