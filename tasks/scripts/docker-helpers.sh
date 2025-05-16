#!/usr/bin/env bash

set -euo pipefail

source ci/tasks/scripts/cgroup-helpers.sh

function start_docker() {
  mkdir -p /var/log
  mkdir -p /var/run

  sanitize_cgroups

  # check for /proc/sys being mounted readonly, as systemd does
  if grep '/proc/sys\s\+\w\+\s\+ro,' /proc/mounts >/dev/null; then
    mount -o remount,rw /proc/sys
  fi

  local mtu=$(cat /sys/class/net/"$(ip route get 8.8.8.8|awk '{ print $5 }')"/mtu)
  local server_args="--mtu ${mtu}"

  dockerd --data-root /scratch/docker ${server_args} >/tmp/docker.log 2>&1 &
  echo $! > /tmp/docker.pid

  sleep 1

  until docker info >/dev/null 2>&1; do
    echo waiting for docker to come up...
    sleep 1
  done
}

function stop_docker() {
  local pid=$(cat /tmp/docker.pid)
  if [ -z "$pid" ]; then
    return 0
  fi

  # if the process has already exited, kill will error, in which case we
  # shouldn't try to wait for it
  if kill -TERM "$pid"; then
    wait "$pid"
  fi
}
