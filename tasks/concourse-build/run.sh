#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

apk --no-progress add cmd:shasum

export GOPATH=$PWD/gopath
export PATH=$PWD/gopath/bin:$PATH

version="$(cat version/version)"

final_version=""
ldflags=""
if [[ -e final-version/version ]]; then
    final_version="$(cat final-version/version)"
    ldflags="-X github.com/concourse/concourse.Version=${final_version}"
    echo -n "final version detected: $final_version"
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
                echo  "performing version check"
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

    mv concourse/$bin_name "${bin}/"

    fly_assets=$output/concourse/fly-assets
    mkdir -p "$fly_assets"
    cp -a fly-{linux,darwin}/fly-*.tgz "$fly_assets"
    cp -a fly-windows/fly-*.zip "$fly_assets"

    if [[ "$GOOS" == "linux" ]]; then
        cp -a "dev-${GOARCH}/rootfs/usr/local/concourse/bin/"!(concourse) "${bin}/"
        cp -a "resource-types-${GOARCH}/rootfs/usr/local/concourse/resource-types" "$output/concourse"
    fi

    pushd "$output"
        if [ "$GOOS" = "windows" ]; then
            apk --no-progress add zip
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

    mv "$output"/* concourse-tarballs/
done
