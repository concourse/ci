#!/usr/bin/env bash

set -euo pipefail

source ci/tasks/scripts/docker-helpers.sh

start_docker

# load in concourse/concourse-dev:latest
[ -d concourse-rc-image ] && docker load -i concourse-rc-image/image.tar

docker compose -f docs/docs/docker-compose.yml -f ci/overrides/docker-compose.latest-rc.yml up -d

# now run the watjs/smoke tests
mkdir -p endpoint-info
pushd endpoint-info
  echo "http://localhost:8080" > instance_url
  echo "test" > admin_username
  echo "test" > admin_password
popd

ci/tasks/smoke-test/run.sh

pushd docs/docs
  docker compose down
popd

stop_docker
