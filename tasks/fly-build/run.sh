#!/usr/bin/env bash

set -euo pipefail

apk --no-cache --no-progress add zip cmd:shasum

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

PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "windows/amd64"
  "darwin/amd64"
  "darwin/arm64"
)

build_platform() {
    local platform=$1
    # Split the platform into OS and architecture
    IFS="/" read -r GOOS GOARCH <<< "$platform"

    echo "==================================="
    echo "Compiling for ${GOOS}-${GOARCH}"
    echo "==================================="

    # Set platform-specific flags
    local tags=""
    local platform_flags=""
    local cgo_enabled=0
    local local_ldflags="$ldflags"

    # Set platform-specific flags
    if [ "$GOOS" = "linux" ] || [ "$GOOS" = "darwin" ]; then
        local_ldflags+=' -extldflags "-static"'
    fi

    if [ "$GOOS" = "darwin" ]; then
        # This is to ensure on darwin we use the cgo DNS resolver. If we don't then
        # users have DNS resolution errors when using fly
        cgo_enabled=1
        tags="osusergo"
        platform_flags="-buildvcs=false"
    fi

    platform_dir="$builds/${GOOS}_${GOARCH}"
    mkdir -p "$platform_dir"

    bin="$platform_dir/fly"
    if [ "$GOOS" = "windows" ]; then
        bin+=".exe"
    fi

    # Use a subshell to avoid issues with pushd/popd across parallel processes
    (
        cd concourse
        CGO_ENABLED=$cgo_enabled GOOS=$GOOS GOARCH=$GOARCH go build -a -tags "$tags" $platform_flags -ldflags "$local_ldflags" -o "$bin" ./fly
    )

    (
        cd "$platform_dir"
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

        mv "$archive" "$archive".sha1 "$output/"
    )
}

for platform in "${PLATFORMS[@]}"; do
    build_platform "$platform" &
done

wait
