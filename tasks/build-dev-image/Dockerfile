ARG base_image=concourse/golang-builder

ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM ${base_image} AS builder

# build concourse, cross-compiling on host platform to avoid emulation slowness
#
# nuke /src after to ensure dev builds build from a clean slate, otherwise this
# can cause build failures if files are removed locally
COPY concourse /src

ARG TARGETOS
ARG TARGETARCH
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH

RUN cd /src && \
    go mod download && \
    go build -gcflags=all="-N -l" -o /usr/local/concourse/bin/concourse \
    ./cmd/concourse && \
    rm -rf /src

FROM ${base_image} AS dev
ARG TARGETARCH

# For some reason, trying to install a lot of packages at once results in a
# flaky SSL error, but only when the container layer is being run on an
# emulated host, like building linux/arm64 on a linux/amd64 host. It doesn't
# always happen either, but right now it's happening more often than it's not.
# The error: error:0A000126:SSL routines::unexpected eof while reading:ssl/record/rec_layer_s3.c:691
RUN apk --no-cache add curl # for tests; installs 20 packages
RUN apk --no-cache add gcc # for cgo; installs 19 packages

RUN apk --no-cache add \
    btrfs-progs \
    ca-certificates \
    dumb-init

RUN mkdir -p /usr/local/concourse/bin

# Container runtime, dependencies
# For containerd backend:
#   - containerd binaries
#   - runc
#   - cni plugins
RUN apk --no-cache add \
    cni-plugins \
    runc \
    containerd

# Copy containerd binaries
RUN cp /usr/bin/containerd* /usr/local/concourse/bin/ && \
    cp /usr/bin/ctr /usr/local/concourse/bin/

# Copy runc
RUN cp /usr/bin/runc /usr/local/concourse/bin/

# Copy CNI plugin binaries
RUN cp /usr/bin/bandwidth /usr/bin/bridge /usr/bin/dhcp /usr/bin/dummy \
       /usr/bin/firewall /usr/bin/host-device /usr/bin/host-local /usr/bin/ipvlan \
       /usr/bin/loopback /usr/bin/macvlan /usr/bin/portmap /usr/bin/ptp \
       /usr/bin/sbr /usr/bin/static /usr/bin/tap /usr/bin/tuning \
       /usr/bin/vlan /usr/bin/vrf \
       /usr/local/concourse/bin/

# Remove cni-plugins since it has a conflicting bridge binary with the one in iproute2
RUN apk --no-cache del \
    cni-plugins

# Add networking tools
RUN apk --no-cache add \
       iproute2 \
       iptables \
       ip6tables \
       # guardian runtime runs some script on startup to create iptable rules and
       # requires the real xargs, not busybox's impl (https://github.com/cloudfoundry/guardian/blob/main/kawasaki/iptables/global_chains.go)
       cmd:xargs

# for worker/runtime/integration tests
RUN apk --no-cache add \
    mount \
    umount

COPY gdn/gdn-linux-${TARGETARCH}-[0-9]*.*.* /usr/local/concourse/bin/gdn
# wolfi does not have /var/run setup, which guardian depends on existing already
RUN ln -sf /run /var/run

RUN chmod -R +x /usr/local/concourse/bin

# add fly executables
RUN mkdir /usr/local/concourse/fly-assets
COPY fly-linux/fly-*.tgz /usr/local/concourse/fly-assets
COPY fly-darwin/fly-*.tgz /usr/local/concourse/fly-assets
COPY fly-windows/fly-*.zip /usr/local/concourse/fly-assets

# add resource types
COPY ./resource-types-${TARGETARCH}/rootfs/usr/local/concourse/resource-types/ /usr/local/concourse/resource-types/

# install concourse
COPY --from=builder /usr/local/concourse/bin/concourse /usr/local/concourse/bin/concourse

# nuke /src after to ensure dev builds build from a clean slate (otherwise this
# can cause build failures if e.g. files are removed locally)
COPY concourse /src

# If not link, gcc will fail with a "/go/bin/as not found" error
RUN ln -s /usr/sbin/as /go/bin/as
# build the init executable for containerd
RUN gcc -O2 -static -o /usr/local/concourse/bin/init /src/cmd/init/init.c

# populate go module cache
RUN cd /src && \
    go mod download && \
    rm -rf /src

# volume for non-aufs/etc. mount for baggageclaim's driver
VOLUME /worker-state
ENV CONCOURSE_WORK_DIR /worker-state

# set $PATH for convenience
ENV PATH /usr/local/concourse/bin:${PATH}

# make `ctr` target the default concourse namespace
ENV CONTAINERD_NAMESPACE=concourse

ENTRYPOINT ["dumb-init", "concourse"]
