#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

export CONCOURSE_RELEASE_VERSION="$(cat concourse-release/version)"
export BPM_RELEASE_VERSION="$(cat bpm-release/version)"
export POSTGRES_RELEASE_VERSION="$(cat postgres-release/version)"
export VAULT_RELEASE_VERSION="$(cat vault-release/version)"
export CREDHUB_RELEASE_VERSION="$(cat credhub-release/version)"
export UAA_RELEASE_VERSION="$(cat uaa-release/version)"
export BACKUP_AND_RESTORE_SDK_RELEASE_VERSION="$(cat bbr-sdk-release/version)"
export STEMCELL_VERSION="$(cat stemcell/version)"

RELEASE_NAME_SUFFIX=${RELEASE_NAME_SUFFIX:-$SUITE}

function upload_release() {
  release_dir=$PWD/$1
  release="$release_dir/*.tgz"
  if [[ -n "$RELEASE_NAME_SUFFIX" ]]; then
    mkdir -p release-unzipped
    tar -C release-unzipped -xzf $release
    rm $release
    sed -i "s/^name: concourse$/name: concourse-$RELEASE_NAME_SUFFIX/" release-unzipped/release.MF
    pushd release-unzipped
      tar -czf "$release_dir/release.tgz" *
    popd
    rm -rf release-unzipped
  fi
  bosh upload-release $release
}

upload_release concourse-release
bosh upload-release bpm-release/*.tgz
bosh upload-release postgres-release/*.tgz
bosh upload-release vault-release/*.tgz
bosh upload-release credhub-release/*.tgz
bosh upload-release uaa-release/*.tgz
bosh upload-release bbr-sdk-release/*.tgz
bosh upload-stemcell stemcell/*.tgz

tar xf ./bbr/bbr-*.tar
install ./releases/bbr /usr/local/bin/

cd concourse

go mod download

go install github.com/onsi/ginkgo/v2/ginkgo

ginkgo -nodes=4 -race -keep-going -poll-progress-after=300s -timeout=24h -flake-attempts=6 -skip="$SKIP" --show-node-events -r --skip-package="$SKIP_PACKAGES" "$@" "./topgun/$SUITE"
