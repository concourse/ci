#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

cd concourse

go mod download

go install github.com/onsi/ginkgo/v2/ginkgo

ginkgo -r -nodes=4 --race --keep-going --poll-progress-after=15s --flake-attempts=3 ./testflight "$@"

docker compose logs > ../docker-compose.log
