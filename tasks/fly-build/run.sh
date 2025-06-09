#!/usr/bin/env bash

set -euo pipefail

apk --no-cache --no-progress add cmd:shasum

export GOPATH=$PWD/gopath
export PATH=$PWD/gopath/bin:$PATH

output="$PWD/fly-builds"
builds="$PWD/builds"
mkdir -p "$builds"

ldflags=""
if [ -e final-version/version ]; then
  final_version="$(cat final-version/version)"
  ldflags="-X github.com/concourse/concourse.Version=${final_version}"
fi

if [[ -z "${PLATFORMS}" ]]; then
    echo "PLATFORMS must be specified"
    exit 1
fi

IFS=',' read -ra platforms <<< "$PLATFORMS"

for platform in "${platforms[@]}"; do
    # Split the platform into OS and architecture
    IFS="/" read -r GOOS GOARCH <<< "$platform"

    echo "==================================="
    echo "Compiling for ${GOOS}-${GOARCH}"
    echo "==================================="

    # Set platform-specific flags
    tags=""
    platform_flags=""
    export CGO_ENABLED=0

    # Set platform-specific flags
    if [ "$GOOS" = "linux" ] || [ "$GOOS" = "darwin" ]; then
    ldflags+=' -extldflags "-static"'
    fi

    if [ "$GOOS" = "darwin" ]; then
    # This is to ensure on darwin we use the cgo DNS resolver. If we don't then
    # users have DNS resolution errors when using fly
    export CGO_ENABLED=1
    tags="osusergo"
    platform_flags="-buildvcs=false"
    fi

    platform_dir="$builds/${GOOS}_${GOARCH}"
    mkdir -p "$platform_dir"

    bin="$platform_dir/fly"
    if [ "$GOOS" = "windows" ]; then
    bin+=".exe"
    fi

    pushd concourse
    GOOS=$GOOS GOARCH=$GOARCH go build -a -tags "$tags" $platform_flags -ldflags "$ldflags" -o "$bin" ./fly
    popd

    pushd "$platform_dir"
    if [ "$GOOS" = "windows" ]; then
        apk --no-cache --no-progress add zip
        archive=fly-$GOOS-$GOARCH.zip
        zip "$archive" fly.exe
    else
        archive=fly-$GOOS-$GOARCH.tgz
        tar -czf "$archive" fly
    fi

    shasum "$archive" > "${archive}.sha1"
    echo -n "${archive}: "
    cat "${archive}.sha1"

    mv "$archive" "$archive".sha1 "$output/"
    popd
done
