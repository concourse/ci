#!/usr/bin/env bash

set -euo pipefail

#TODO: use minio to manually upload to blobstore without director
bosh upload-release concourse-release/*.tgz
bosh upload-release postgres-release/*.tgz
bosh upload-release bpm-release/*.tgz
