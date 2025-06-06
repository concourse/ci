# used for building concourse/dev multi-arch.
#
# * compile gdn binary
# * baking in the containerd binaries (+ runc, cni plugins, iptables)
# * baking in fly binaries
# * baking in resource types
# * build init executable for containerd
# * warming the module cache
# * warming the build cache

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

RUN apk --no-cache add \
    btrfs-progs \
    ca-certificates \
    dumb-init \
    iproute2 \
    iptables

# Add container runtime dependencies
#
# For containerd backend:
#   - containerd binaries
#   - runc
#   - cni plugins
#   - iptables (needed by cni plugins)

# Copies files from the bin directory of the tarball to /usr/local/concourse/bin
ADD containerd/containerd-*-linux-${TARGETARCH}.tar.gz /usr/local/concourse

COPY gdn/gdn-linux-${TARGETARCH}-[0-9]*.*.* /usr/local/concourse/bin/gdn

COPY runc/runc.${TARGETARCH} /usr/local/concourse/bin/runc

ADD cni/cni-plugins-linux-${TARGETARCH}-*.tgz /usr/local/concourse/bin

RUN chmod -R +x /usr/local/concourse/bin

# add fly executables
RUN mkdir /usr/local/concourse/fly-assets
COPY fly-builds/fly-*.tgz /usr/local/concourse/fly-assets

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
