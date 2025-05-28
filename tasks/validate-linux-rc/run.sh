#!/bin/sh

set -euo

# install ldd
apk add --quiet --no-progress posix-libc-utils

tar -xzf concourse-tarball/concourse-*.tgz
cd concourse

# ensure all resource types are bundled
resource_types='bosh-io-release
bosh-io-stemcell
docker-image
git
github-release
hg
mock
pool
registry-image
s3
semver
time'

for resource_type in $resource_types; do
  cat resource-types/$resource_type/resource_metadata.json
  test -f resource-types/$resource_type/rootfs.tgz
done

# test that binaries are statically linked
if ldd bin/concourse; then
  echo "concourse binary is not static; aborting"
  exit 1
fi
./bin/concourse --version

tar -xzf fly-assets/fly-linux-amd64.tgz
if ldd fly; then
  echo "fly binary is not static; aborting"
  exit 1
fi
./fly --version

# sanity check for concourse dependencies
test -f bin/containerd
test -f bin/runc
test -f bin/gdn
test -f bin/init
