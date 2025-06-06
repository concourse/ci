#!/usr/bin/env bash

set -euo pipefail

apk --no-cache --no-progress add zip cmd:shasum

export GOPATH=$PWD/gopath
export PATH=$PWD/gopath/bin:$PATH

version="$(cat version/version)"

final_version=""
ldflags=""
if [ -e final-version/version ]; then
  final_version="$(cat final-version/version)"
  ldflags="-X github.com/concourse/concourse.Version=$final_version"
fi

PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "windows/amd64"
  "darwin/amd64"
  "darwin/arm64"
)

for platform in "${PLATFORMS[@]}"; do
    # Split the platform into OS and architecture
    IFS="/" read -r GOOS GOARCH <<< "$platform"

    echo "==================================="
    echo "Packaging for ${GOOS}-${GOARCH}"
    echo "==================================="

    pushd concourse
        bin_name="concourse"
        extra_flags=""
        if [ "$GOOS" = "windows" ]; then
            bin_name+=".exe"
        fi

        if [ "$GOOS" = "darwin" ]; then
            extra_flags="-buildvcs=false"
        fi

        GOOS=$GOOS GOARCH=$GOARCH go build -o "$bin_name" -ldflags "$ldflags" $extra_flags ./cmd/concourse

        if [[ -n "$final_version" ]]; then
            # Right now all our workers are amd64 so we can only do version checks for that arch
            if [[ "$GOOS" == "linux" && "$GOARCH" == "amd64" ]]; then
                test "$(./concourse --version)" = "$final_version"
            else
                echo "skipping version check for platform ${GOOS}/${GOARCH}"
            fi
        fi
    popd

    output=concourse-tarballs/${GOOS}_${GOARCH}
    mkdir -p "$output/concourse"

    bin=$output/concourse/bin
    mkdir -p "$bin"

    mv concourse/$bin_name "$bin"

    fly_assets=$output/concourse/fly-assets
    mkdir -p "$fly_assets"
    cp -a fly-builds/fly-*.{tgz,zip} "$fly_assets"

    if [[ "$GOOS" == "linux" ]]; then
        cp -a "dev-${GOARCH}/rootfs/usr/local/concourse/bin/*" "$bin"
        cp -a "resource-types-${GOARCH}/rootfs/usr/local/concourse/resource-types" "$output/concourse"
    fi

    pushd "$output"
        if [ "$GOOS" = "windows" ]; then
            archive=concourse-${version}.${GOOS}.${GOARCH}.zip
            zip -r "$archive" concourse
        else
            archive=concourse-${version}.${GOOS}.${GOARCH}.tgz
            tar -czf "$archive" concourse
        fi
        shasum "$archive" > "${archive}.sha1"
        echo -n "${archive}:"
        cat "${archive}.sha1"

        rm -r concourse
    popd

    mv "$output/*" concourse-tarballs/
done
