#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

mkdir /tmp/concourse-pg-runner
if ! mount -t tmpfs none /tmp/concourse-pg-runner 2>/dev/null; then
  if grep '/dev/shm.*tmpfs' /proc/mounts >/dev/null; then
    mkdir /dev/shm/concourse-pg-runner
    rmdir /tmp/concourse-pg-runner
    ln -s /dev/shm/concourse-pg-runner /tmp/concourse-pg-runner
  else
    echo 'failed to mount tmpfs for pg. this is OK, db suite will just be slow'
  fi
fi

cd concourse

go mod download

go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo

ginkgo -r -p -flake-attempts=3 -race -skip-package ./integration,testflight,topgun,./worker/runtime/integration,./worker/baggageclaim "$@"
