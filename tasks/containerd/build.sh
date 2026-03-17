#!/bin/sh

set -e

apk --no-progress add git make

cd containerd
git checkout "$CONTAINERD_TAG"

make STATIC=1 GOARCH=amd64

# Log versions
./bin/containerd --version
./bin/containerd-shim-runc-v2 --version
./bin/ctr --version

cd ./bin
rm containerd-stress
tar czvf containerd.amd64.tar.gz ./
mv containerd.amd64.tar.gz ../
cd ..

rm -rf ./bin

make STATIC=1 GOARCH=arm64
cd ./bin
rm containerd-stress
tar czvf containerd.arm64.tar.gz ./
mv containerd.arm64.tar.gz ../
cd ..

mv ./containerd.*.tar.gz ../containerd-tar/
