#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

install -m 0755 bbr-cli/bbr-*-linux-amd64       /usr/local/bin/bbr
install -m 0755 bosh-cli/bosh-cli-*-linux-amd64 /usr/local/bin/bosh

bosh -d $BOSH_DEPLOYMENT deployment | \
  grep concourse/ | \
  awk '{print $1}' | head -n 1 \
  > bbr_artifacts/concourse_version

bbr deployment backup --artifact-path=bbr_artifacts

tar -cvf bbr_artifacts/bbr_backup.tar bbr_artifacts/*
