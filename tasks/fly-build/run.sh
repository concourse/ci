#!/usr/bin/env bash
# vim: set ft=sh

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$PWD/gopath/bin:$PATH

export GOOS="${PLATFORM:-$(go env GOOS)}"
export GOARCH="${ARCH:-$(go env GOARCH)}"

output="$PWD/fly"

ldflags=""
if [ -e final-version/version ]; then
  final_version="$(cat final-version/version)"
  ldflags="-X github.com/concourse/concourse.Version=${final_version}"
fi

if [ "$GOOS" = "linux" ] || [ "$GOOS" = "darwin" ]; then
  ldflags+=' -extldflags "-static"'
fi

bin="$output/fly"
if [ "$GOOS" = "windows" ]; then
  bin+=".exe"
fi

pushd concourse
  go build -a -ldflags "$ldflags" -o "$bin" ./fly
popd

pushd $output
  if [ "$GOOS" = "windows" ]; then
    archive=fly-$GOOS-$GOARCH.zip
    apt-get update && apt-get install -y zip
    zip "$archive" fly.exe
  else
    archive=fly-$GOOS-$GOARCH.tgz
    tar -czf $archive fly
  fi
  shasum "$archive" > "${archive}.sha1"
popd
