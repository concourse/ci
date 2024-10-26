#!/usr/bin/env bash
# vim: set ft=bash

set -euo pipefail

git clone concourse-release-repo bumped-concourse-release-repo

pushd bumped-concourse-release-repo/
  # work-around Go BOSH CLI trying to rename blobs downloaded into ~/.root/tmp
  # into release dir, which is invalid cross-device link
  export HOME=$PWD

  git config --global user.email "team@concourse-oss.org"
  git config --global user.name "Concourse Bot"

  # Create config/private.yml with S3 credentials
  echo '
blobstore:
  provider: s3
  options:
    bucket_name: concourse-bosh
  ' > config/private.yml

  yq '.blobstore.options.access_key_id = strenv(access_key_id)' \
    -i config/private.yml
  yq '.blobstore.options.secret_access_key = strenv(secret_access_key)' \
    -i config/private.yml

  for blob in $(bosh blobs --column="path"  | grep concourse/); do
    bosh -n remove-blob $blob
  done

  for blob in ../linux-rc/concourse-*.tgz ../windows-rc/concourse-*.zip; do
    bosh -n add-blob $blob concourse/$(basename $blob)
  done

  # Upload blobs to S3 bucket
  bosh -n upload-blobs

  git add -A
  git commit -m "bump concourse" --signoff
popd
