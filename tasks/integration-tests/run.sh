#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

source ci/tasks/scripts/docker-helpers.sh

start_docker

image_ref () {
  dir=$1

  # note: tag must take precedence, since the digest returned by the
  # registry-image resource is not the same as the image id in the docker CLI.
  # the oci-build-task, however, gives a digest that can be used
  if [ -f "${dir}/tag" ]; then
    echo "$(cat ${dir}/repository):$(cat ${dir}/tag)"
  else
    cat ${dir}/digest
  fi
}

docker load -i dev-image/image.tar
export TEST_CONCOURSE_DEV_IMAGE="$(image_ref dev-image)"

if [ -d concourse-image ]; then
  docker load -i concourse-image/image.tar
  export TEST_CONCOURSE_LATEST_IMAGE="$(image_ref concourse-image)"
fi

if [ -d postgres-image ]; then
  docker load -i postgres-image/image.tar
  export TEST_POSTGRES_IMAGE="$(image_ref postgres-image)"
fi

if [ -d vault-image ]; then
  docker load -i vault-image/image.tar
  export TEST_VAULT_IMAGE="$(image_ref vault-image)"
fi

cd concourse

go mod download

go test -parallel=2 -skip=Ops ./integration/... "$@"
go test ./integration/ops "$@"
