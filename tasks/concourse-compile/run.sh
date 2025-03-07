#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$PWD/gopath/bin:$PATH
export CGO_ENABLED=0

if [ -z "${PLATFORM}" ]; then
  echo "usage: PLATFORM=<platform> $0" >&2
  exit 1
fi

export GOOS="${PLATFORM:-$(go env GOOS)}"
export GOARCH="${ARCH:-amd64}"

final_version=""
ldflags=""
if [ -e final-version/version ]; then
  final_version="$(cat final-version/version)"
  ldflags="-X github.com/concourse/concourse.Version=$final_version"
fi

pushd concourse
  bin_name="concourse"
  extra_flags=""
  if [ "$GOOS" = "windows" ]; then
    bin_name+=".exe"
  fi

  if [ "$GOOS" = "darwin" ]; then
    extra_flags="-buildvcs=false"
  fi

  go build -o "$bin_name" -ldflags "$ldflags" $extra_flags ./cmd/concourse

  if [ -n "$final_version" ]; then
    if [ "$GOOS" = "linux" ]; then
      test "$(./concourse --version)" = "$final_version"
    else
      echo "skipping --version check for platform $GOOS"
    fi
  fi
popd

mv concourse/$bin_name concourse-binary/
