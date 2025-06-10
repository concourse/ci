#!/usr/bin/env bash

set -euo pipefail -x

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

function permit_device_control() {
  local devices_mount_info=$(grep devices < /proc/self/cgroup)

  if [ -z "$devices_mount_info" ]; then
    # cgroups not set up; must not be in a container
    return
  fi

  local devices_subsytems=$(echo $devices_mount_info | cut -d: -f2)
  local devices_subdir=$(echo $devices_mount_info | cut -d: -f3)

  if [ "$devices_subdir" = "/" ]; then
    # we're in the root devices cgroup; must not be in a container
    return
  fi

  cgroup_dir=/tmp/devices-cgroup

  if [ ! -e ${cgroup_dir} ]; then
    # mount our container's devices subsystem somewhere
    mkdir ${cgroup_dir}
  fi

  if ! mountpoint -q ${cgroup_dir}; then
    if ! mount -t cgroup -o $devices_subsytems none ${cgroup_dir}; then
      return 1
    fi
  fi

  # permit our cgroup to do everything with all devices
  # ignore failure in case something has already done this; echo appears to
  # return EINVAL, possibly because devices this affects are already in use
  echo a > ${cgroup_dir}${devices_subdir}/devices.allow || true
}

function setup_loop_devices() {
  for i in $(seq 0 3); do
    mknod -m 0660 /scratch/loop$i b 7 $i
    ln -s /scratch/loop$i /dev/loop$i
  done
}

function salt_earth() {
  for i in $(seq 0 3); do
    losetup -d /dev/loop$i > /dev/null 2>&1 || true
  done
}

permit_device_control
setup_loop_devices
trap salt_earth EXIT

cd concourse/worker/baggageclaim

# /tmp is sometimes overlay (it doesn't have a dedicated mountpoint so it's
# whatever / is), so point $TMPDIR to /scratch which we can trust to be
# non-overlay for the overlay driver tests
export TMPDIR=/scratch

go mod download
go install github.com/onsi/ginkgo/v2/ginkgo

ginkgo -r -race -nodes 4 --fail-on-pending -flake-attempts=3 --randomize-all --keep-going -skip=":skip" "$@"
