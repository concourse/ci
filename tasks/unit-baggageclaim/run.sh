#!/bin/bash
# vim: set ft=sh

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

dir=${0%/*}

function permit_device_control() {
  cgroup_id=$(cat /proc/self/cgroup | grep -oP '(?<=^0::).*')

  if [[ -z "$cgroup_id" ]]; then
    echo "cgroups not set up; must not be in a container"
    return
  fi

  clang -O2 -target bpf -c "${dir}/allow_device_control.c" -o allow_device_control.o

  # remove any currently attached cgroup_device programs
  attached_id=$(./bpftool cgroup list /sys/fs/cgroup${cgroup_id} | grep 'cgroup_device' | awk '{print $1}')
  if [[ -n "${attached_id}" ]]; then
    bpftool cgroup detach \
      /sys/fs/cgroup${cgroup_id} \
      cgroup_device id ${attached_id}
  fi

  bpftool prog load \
    allow_device_control.o \
    /sys/fs/bpf/allow_device_control

  bpftool cgroup attach \
    /sys/fs/cgroup${cgroup_id} \
    cgroup_device pinned /sys/fs/bpf/allow_device_control
}

function setup_loop_devices() {
  for i in $(seq 4 7); do
    mknod -m 0660 /scratch/loop$i b 7 $i
    ln -s /scratch/loop$i /dev/loop$i
  done
}

function salt_earth() {
  for i in $(seq 4 7); do
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

ginkgo -r -race -nodes 4 --failOnPending -flake-attempts=3 --randomizeAllSpecs --keep-going -skip=":skip" "$@"

