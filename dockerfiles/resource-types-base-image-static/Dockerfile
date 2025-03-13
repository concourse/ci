ARG base_image

FROM busybox:glibc AS busybox

FROM ${base_image}
USER root
COPY --from=busybox /bin/cat /bin/cat
COPY --from=busybox /bin/chmod /bin/chmod
COPY --from=busybox /bin/cp /bin/cp
COPY --from=busybox /bin/df /bin/df
COPY --from=busybox /bin/echo /bin/echo
COPY --from=busybox /bin/find /bin/find
COPY --from=busybox /bin/free /bin/free
COPY --from=busybox /bin/grep /bin/grep
COPY --from=busybox /bin/kill /bin/kill
COPY --from=busybox /bin/ls /bin/ls
COPY --from=busybox /bin/mkdir /bin/mkdir
COPY --from=busybox /bin/mv /bin/mv
COPY --from=busybox /bin/netstat /bin/netstat
COPY --from=busybox /bin/ping /bin/ping
COPY --from=busybox /bin/ps /bin/ps
COPY --from=busybox /bin/pwd /bin/pwd
COPY --from=busybox /bin/rm /bin/rm
COPY --from=busybox /bin/sh /bin/sh
COPY --from=busybox /bin/tar /bin/tar
COPY --from=busybox /bin/top /bin/top
COPY --from=busybox /bin/vi /bin/vi
COPY --from=busybox /bin/wget /bin/wget