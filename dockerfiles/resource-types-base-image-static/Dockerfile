ARG base_image

FROM busybox:uclibc as busybox

FROM ${base_image}
USER root
COPY --from=busybox /bin/sh /bin/sh
COPY --from=busybox /bin/chmod /bin/chmod
COPY --from=busybox /bin/cat /bin/cat
COPY --from=busybox /bin/echo /bin/echo
COPY --from=busybox /bin/cp /bin/cp
COPY --from=busybox /bin/ls /bin/ls
COPY --from=busybox /bin/pwd /bin/pwd
COPY --from=busybox /bin/mv /bin/mv
COPY --from=busybox /bin/wget /bin/wget
COPY --from=busybox /bin/kill /bin/kill
COPY --from=busybox /bin/ping /bin/ping
COPY --from=busybox /bin/vi /bin/vi
