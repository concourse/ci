#!/usr/bin/env bash

set -euo -x pipefail

mkdir -p linux-dependencies/amd64
mkdir -p linux-dependencies/arm64

cp -a dev-amd64/rootfs/usr/local/concourse/bin/* linux-dependencies/amd64
cp -a dev-arm64/rootfs/usr/local/concourse/bin/* linux-dependencies/arm64
