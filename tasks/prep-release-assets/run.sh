#!/usr/bin/env bash

set -euo pipefail -x

apk add --quiet --no-progress cmd:shasum

version=$(cat version/version)

mv linux-amd64-rc/*.tgz   "concourse-linux/concourse-${version}-linux-amd64.tgz"
mv linux-arm64-rc/*.tgz   "concourse-linux/concourse-${version}-linux-arm64.tgz"
mv windows-amd64-rc/*.zip "concourse-windows/concourse-${version}-windows-amd64.zip"
mv darwin-amd64-rc/*.tgz  "concourse-darwin/concourse-${version}-darwin-amd64.tgz"
mv darwin-arm64-rc/*.tgz  "concourse-darwin/concourse-${version}-darwin-arm64.tgz"

tar -zxf "concourse-linux/concourse-${version}-linux-amd64.tgz" concourse/fly-assets --strip-components=2

mv fly-linux-amd64.tgz   "fly-linux/fly-${version}-linux-amd64.tgz"
mv fly-linux-arm64.tgz   "fly-linux/fly-${version}-linux-arm64.tgz"
mv fly-windows-*.zip "fly-windows/fly-${version}-windows-amd64.zip"
mv fly-darwin-amd64.tgz  "fly-darwin/fly-${version}-darwin-amd64.tgz"
mv fly-darwin-arm64.tgz  "fly-darwin/fly-${version}-darwin-arm64.tgz"

for dir in {concourse,fly}-{linux,windows,darwin}; do
  pushd "$dir"
    for file in *; do
        # ensure .sha1 file just has the filename so shasum -c works
        shasum "$file" > "${file}.sha1"
    done
  popd
done
