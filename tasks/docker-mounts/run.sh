#!/usr/bin/env bash

set -euo pipefail

cat > expected_docker_mounts <<EOF
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev type tmpfs (rw,seclabel,nosuid,size=65536k,mode=755,inode64)
devpts on /dev/pts type devpts (rw,seclabel,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666)
sysfs on /sys type sysfs (ro,seclabel,nosuid,nodev,noexec,relatime)
cgroup on /sys/fs/cgroup type cgroup2 (ro,seclabel,nosuid,nodev,noexec,relatime)
mqueue on /dev/mqueue type mqueue (rw,seclabel,nosuid,nodev,noexec,relatime)
shm on /dev/shm type tmpfs (rw,seclabel,nosuid,nodev,noexec,relatime,size=65536k,inode64)
/dev/sdb1 on /etc/resolv.conf type ext4 (rw,seclabel,relatime)
/dev/sdb1 on /etc/hostname type ext4 (rw,seclabel,relatime)
/dev/sdb1 on /etc/hosts type ext4 (rw,seclabel,relatime)
devpts on /dev/console type devpts (rw,seclabel,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666)
proc on /proc/bus type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/fs type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/irq type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/sys type proc (ro,nosuid,nodev,noexec,relatime)
proc on /proc/sysrq-trigger type proc (ro,nosuid,nodev,noexec,relatime)
tmpfs on /proc/acpi type tmpfs (ro,seclabel,relatime,inode64)
tmpfs on /proc/kcore type tmpfs (rw,seclabel,nosuid,size=65536k,mode=755,inode64)
tmpfs on /proc/keys type tmpfs (rw,seclabel,nosuid,size=65536k,mode=755,inode64)
tmpfs on /proc/latency_stats type tmpfs (rw,seclabel,nosuid,size=65536k,mode=755,inode64)
tmpfs on /proc/timer_list type tmpfs (rw,seclabel,nosuid,size=65536k,mode=755,inode64)
tmpfs on /proc/scsi type tmpfs (ro,seclabel,relatime,inode64)
tmpfs on /sys/firmware type tmpfs (ro,seclabel,relatime,inode64)
EOF

cat > expected_privileged_docker_mounts <<EOF
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev type tmpfs (rw,seclabel,nosuid,size=65536k,mode=755,inode64)
devpts on /dev/pts type devpts (rw,seclabel,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666)
sysfs on /sys type sysfs (rw,seclabel,nosuid,nodev,noexec,relatime)
cgroup on /sys/fs/cgroup type cgroup2 (rw,seclabel,nosuid,nodev,noexec,relatime)
mqueue on /dev/mqueue type mqueue (rw,seclabel,nosuid,nodev,noexec,relatime)
shm on /dev/shm type tmpfs (rw,seclabel,nosuid,nodev,noexec,relatime,size=65536k,inode64)
/dev/sdb1 on /etc/resolv.conf type ext4 (rw,seclabel,relatime)
/dev/sdb1 on /etc/hostname type ext4 (rw,seclabel,relatime)
/dev/sdb1 on /etc/hosts type ext4 (rw,seclabel,relatime)
devpts on /dev/console type devpts (rw,seclabel,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=666)
EOF

docker pull busybox
docker run -it busybox mount | tail -n +2 > docker-mounts
docker run -it --privileged busybox mount  | tail -n +2 > privileged-docker-mounts

# normalize the /dev/sd* mounts to /dev/sdb, since we don't care what hard disk
# the mounts originated from (sda -> 1st mounted disk, sdb -> 2nd, sdc -> 3rd)
sed -i 's|/dev/sd.|/dev/sdb|g' docker-mounts
sed -i 's|/dev/sd.|/dev/sdb|g' privileged-docker-mounts

# Instructions in case of job failure
cat <<EOF
 This job checks whether the mount configuration in a regular and privileged Docker container have changed.
 The mount configurations Concourse uses for containerd roughly follow Docker with some necessary exceptions. As a
 result we don't check against the containerd mounts directly.

 If this job fails:
 1. Find out why the changes were made in Docker https://github.com/moby/moby/
 Some files to check:
 https://github.com/moby/moby/blob/master/daemon/oci_linux.go
 https://github.com/moby/moby/blob/master/oci/defaults.go
 2. Determine if changes need to made to the mount configurations Concourse uses with containerd
 https://github.com/concourse/concourse/blob/master/worker/runtime/spec/mounts.go
 3. Finally update this file with the latest expected Docker mounts
EOF

diff -Ebw docker-mounts expected_docker_mounts
diff -Ebw privileged-docker-mounts expected_privileged_docker_mounts
