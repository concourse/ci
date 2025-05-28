#!/usr/bin/env bash

set -euox pipefail

bosh upload-release concourse-release/*.tgz
bosh upload-release postgres-release/*.tgz
bosh upload-release bpm-release/*.tgz
