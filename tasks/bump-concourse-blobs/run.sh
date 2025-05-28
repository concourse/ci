#!/usr/bin/env bash

set -euo pipefail

git clone concourse-release-repo bumped-concourse-release-repo

# authenticate us to upload to GCS bucket
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp.key.json
cat > $GOOGLE_APPLICATION_CREDENTIALS <<EOF
$GCP_JSON_KEY
EOF

pushd bumped-concourse-release-repo/
  # work-around Go BOSH CLI trying to rename blobs downloaded into ~/.root/tmp
  # into release dir, which is invalid cross-device link
  export HOME=$PWD

  git config --global user.email "concourseteam+concourse-github-bot@gmail.com"
  git config --global user.name "Concourse Bot"

  for blob in $(bosh blobs --column="path"  | grep concourse/); do
    bosh -n remove-blob $blob
  done

  for blob in ../linux-rc/concourse-*.tgz ../windows-rc/concourse-*.zip; do
    bosh -n add-blob "$blob" concourse/$(basename $blob)
  done

  # Upload blobs to GCS bucket
  bosh -n upload-blobs

  git add -A
  git commit -m "bump concourse" --signoff
popd
