#!/bin/sh

set -e

apk --no-progress add git

cd runc
git checkout "$RUNC_TAG"
cd ..

mkdir -p ./image

export UNPACK_ROOTFS=true
export IMAGE_ARG_base_image="golang-builder-image/oci"
export DOCKERFILE="ci/tasks/runc/Dockerfile"
export CONTEXT="runc"

export IMAGE_PLATFORM=linux/amd64
build
cp ./image/rootfs/output/runc ./runc-bin/runc.amd64
rm -rf ./image/*

export IMAGE_PLATFORM=linux/arm64
build
cp ./image/rootfs/output/runc ./runc-bin/runc.arm64

