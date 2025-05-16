#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$PWD/gopath/bin:$PATH

export GOOS="${PLATFORM:-$(go env GOOS)}"
export GOARCH="${ARCH:-$(go env GOARCH)}"

echo "compiling for ${GOOS}-${GOARCH}"

output="$PWD/fly"

ldflags=""
if [ -e final-version/version ]; then
  final_version="$(cat final-version/version)"
  ldflags="-X github.com/concourse/concourse.Version=${final_version}"
fi

if [ "$GOOS" = "linux" ] || [ "$GOOS" = "darwin" ]; then
  ldflags+=' -extldflags "-static"'
fi

tags=""
platform_flags=""
if [ "$GOOS" = "darwin" ]; then
  # This is to ensure on darwin we use the cgo DNS resolver. If we don't then
  # users have DNS resolution errors when using fly
  export CGO_ENABLED=1
  tags+='osusergo'
  platform_flags+='-buildvcs=false'
fi

bin="$output/fly"
if [ "$GOOS" = "windows" ]; then
  bin+=".exe"
fi

pushd concourse
  go build -a -tags "$tags" $platform_flags -ldflags "$ldflags" -o "$bin" ./fly
popd

pushd "$output"
  if [ "$GOOS" = "windows" ]; then
    archive=fly-$GOOS-$GOARCH.zip
    zip "$archive" fly.exe
  else
    archive=fly-$GOOS-$GOARCH.tgz
    tar -czf "$archive" fly
  fi

  shasum "$archive" > "${archive}.sha1"
  echo -n "${archive}: "
  cat "${archive}.sha1"
popd
