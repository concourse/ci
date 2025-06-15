#!/usr/bin/env bash

set -euo pipefail -x

version=$(cat version/version)

mv linux-rc/*.tgz   "concourse-linux/concourse-${version}-linux-amd64.tgz"
mv windows-rc/*.zip "concourse-windows/concourse-${version}-windows-amd64.zip"
mv darwin-rc/*.tgz  "concourse-darwin/concourse-${version}-darwin-amd64.tgz"

tar -zxf concourse-linux/*.tgz concourse/fly-assets --strip-components=2

mv fly-linux-*.tgz   "fly-linux/fly-${version}-linux-amd64.tgz"
mv fly-windows-*.zip "fly-windows/fly-${version}-windows-amd64.zip"
mv fly-darwin-*.tgz  "fly-darwin/fly-${version}-darwin-amd64.tgz"

for asset in {concourse,fly}-{linux,windows,darwin}/*; do
  dir=$(dirname "$asset")
  file=$(basename "$asset")

  # ensure .sha1 file just has the filename so shasum -c works
  pushd "$dir"
    shasum "$file" > "${file}.sha1"
  popd
done
