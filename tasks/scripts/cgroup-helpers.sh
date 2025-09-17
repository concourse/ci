#!/usr/bin/env bash

set -euo pipefail

# ensure that we have the all of the enabled cgroup controllers mounted under
# `/sys/fs/cgroup` read-write.
#
function sanitize_cgroups() {
    if [[ -f '/sys/fs/cgroup/cgroup.controllers' ]]; then
        echo "cgroups V2 detected. No sanitization of cgroups required."
        return 0
    fi

    mkdir -p /sys/fs/cgroup

    # check if the `/sys/fs/cgroup` directory is a mountpoint or not.
    #
    # inside garden privileged containers, this evaluate to `false` by default,
    # thus, we need to go ahead and mount the` cgroup` filesystem here.
    #
    # remembering the `mount(8)` syntax:
    #
    #     mount -t <type> -o <opts> <device> <mountpoint>
    #
    # so, we start by creating a `tmpfs` mount on `/sys/fs/cgroup` naming the
    # "source device" as "cgroup" (it could be named anything as the "device"
    # backing `tmpfs` is just memory).
    #
    mountpoint -q /sys/fs/cgroup || \
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

    # ensure that we have `/sys/fs/cgroup` as `read-write` so that we can mutate
    # it (assuming in the case above, we got a positive for the mountpoint check)
    #
    mount -o remount,rw /sys/fs/cgroup

    # go over each of the controllers that are enabled in this kernel
    #
    sed -e 1d /proc/cgroups | while read sys hierarchy num enabled; do
    if [ "$enabled" != "1" ]; then
        # subsystem disabled; skip
        continue
    fi

    # it could be that the controller we're looking at is already mounted
    # somewhere.
    grouping="$(cat /proc/self/cgroup | cut -d: -f2 | grep "\\<$sys\\>")"
    if [ -z "$grouping" ]; then
        # subsystem not mounted anywhere; mount it on its own
        grouping="$sys"
    fi

    mountpoint="/sys/fs/cgroup/$grouping"

    mkdir -p "$mountpoint"

    # clear out existing mount to make sure new one is read-write
    #
    if mountpoint -q "$mountpoint"; then
        umount "$mountpoint"
    fi

    # mount the grouping under mountpoint (e.g., `/sys/fs/cgroup/pids`)
    #
    mount -n -t cgroup -o "$grouping" cgroup "$mountpoint"

    # ensure that each controller get its path (e.g., `cpu,cpuacct` --> `cpu` and
    # `cpuacct` symlinks pointing to `cpu,cpuacct`).
    #
    if [ "$grouping" != "$sys" ]; then
        if [ -L "/sys/fs/cgroup/$sys" ]; then
        rm "/sys/fs/cgroup/$sys"
        fi

        ln -s "$mountpoint" "/sys/fs/cgroup/$sys"
    fi
    done

    # mount the named `systemd` cgroup hierarchy with no attached controllers
    #
    if ! test -e /sys/fs/cgroup/systemd ; then
    mkdir /sys/fs/cgroup/systemd
    mount -t cgroup -o none,name=systemd none /sys/fs/cgroup/systemd
    fi
}
