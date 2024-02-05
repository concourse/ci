# used for building concourse/dev. this shortens the dev feedback loop by:
#
# * baking in the gdn binary
# * baking in the containerd binaries (+ runc, cni plugins, iptables)
# * baking in fly binaries
# * baking in resource types
# * build init executable for containerd
# * warming the module cache
# * warming the build cache

ARG base_image=concourse/golang-builder
FROM ${base_image}

RUN apt-get update && apt-get -y install \
      iproute2 \
      ca-certificates \
      curl \
      file \
      tree \
      btrfs-progs

COPY dumb-init/dumb-init_*_x86_64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

# Add container runtime dependencies
#
# For guardian backend:
#   - gdn
# For containerd backend:
#   - containerd binaries
#   - runc
#   - cni plugins
#   - iptables (needed by cni plugins)
COPY gdn/gdn-linux-amd64-[0-9]*.*.* /usr/local/concourse/bin/gdn

# Copies files from the bin directory of the tarball to /usr/local/concourse/bin
ADD containerd/containerd-*-linux-amd64.tar.gz /usr/local/concourse

COPY runc/runc.amd64 /usr/local/concourse/bin/runc

ADD cni/cni-plugins-linux-amd64-*.tgz /usr/local/concourse/bin
RUN apt install -y iptables

RUN chmod -R +x /usr/local/concourse/bin

# add fly executables
RUN mkdir /usr/local/concourse/fly-assets
COPY fly-linux/fly-*.tgz /usr/local/concourse/fly-assets
COPY fly-windows/fly-*.zip /usr/local/concourse/fly-assets
COPY fly-darwin/fly-*.tgz /usr/local/concourse/fly-assets

# add resource types
COPY ./resource-types-image/rootfs/usr/local/concourse/resource-types/ /usr/local/concourse/resource-types/

# install concourse, leaving the module cache populated
#
# nuke /src after to ensure dev builds build from a clean slate (otherwise this
# can cause build failures if e.g. files are removed locally)
COPY concourse /src

# build the init executable for containerd
RUN gcc -O2 -static -o /usr/local/concourse/bin/init /src/cmd/init/init.c

RUN cd /src && \
      go mod download && \
      go build -gcflags=all="-N -l" -o /usr/local/concourse/bin/concourse \
        ./cmd/concourse && \
      rm -rf /src

# volume for non-aufs/etc. mount for baggageclaim's driver
VOLUME /worker-state
ENV CONCOURSE_WORK_DIR /worker-state

# set $PATH for convenience
ENV PATH /usr/local/concourse/bin:${PATH}

# make `ctr` target the default concourse namespace
ENV CONTAINERD_NAMESPACE=concourse

ENTRYPOINT ["dumb-init", "concourse"]
