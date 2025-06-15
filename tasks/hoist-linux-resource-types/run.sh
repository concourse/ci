#!/usr/bin/env bash

set -euo pipefail -x

mkdir -p resource-types/amd64
mkdir -p resource-types/arm64

cp -a resource-types-amd64/rootfs/usr/local/concourse/resource-types/* resource-types/amd64
cp -a resource-types-arm64/rootfs/usr/local/concourse/resource-types/* resource-types/arm64
