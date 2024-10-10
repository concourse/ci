#!/bin/bash
# vim: set ft=sh

set -e -x

export GOPATH=$PWD/gopath
export PATH=$PWD/gopath/bin:$PATH

if [ -z "${PLATFORM}" ]; then
  echo "usage: PLATFORM=<platform> $0" >&2
  exit 1
fi

export GOOS="${PLATFORM:-$(go env GOOS)}"
export GOARCH="amd64"

version="$(cat version/version)"

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

output=concourse-tarball

mkdir $output/concourse

bin=$output/concourse/bin
mkdir $bin
[ "$GOOS" = "linux" ] && cp -a linux-dependencies/* $bin
mv concourse/$bin_name $bin

[ "$GOOS" = "linux" ] && cp -a resource-types $output/concourse

fly_assets=$output/concourse/fly-assets
mkdir $fly_assets
cp -a fly-linux/fly-*.tgz $fly_assets
cp -a fly-windows/fly-*.zip $fly_assets
cp -a fly-darwin/fly-*.tgz $fly_assets

pushd $output
  if [ "$GOOS" = "windows" ]; then
    archive=concourse-${version}.${GOOS}.${GOARCH}.zip
    apt-get update && apt-get install -y zip
    zip "$archive" concourse
  elif [ "$GOOS" = "darwin" ]; then
    archive=concourse-${version}.${GOOS}.${GOARCH}.tgz
    tar -czf "$archive" concourse
  else
    archive=concourse-${version}.${GOOS}-${VARIANT}.${GOARCH}.tgz
    tar -czf "$archive" concourse
  fi
  shasum "$archive" > "${archive}.sha1"

  rm -r concourse
popd
