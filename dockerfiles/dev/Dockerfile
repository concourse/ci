# used for building concourse/dev. this shortens the dev feedback loop by:
#
# * baking in the gdn binary
# * baking in fly binaries
# * baking in resource types
# * warming the module cache
# * warming the build cache

FROM concourse/golang-builder

RUN apt-get update && apt-get -y install \
      iproute2 \
      curl \
      ca-certificates \
      file \
      btrfs-tools

COPY dumb-init/dumb-init_*_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

# add and install executable dependencies
COPY gdn/gdn-* /usr/local/concourse/bin/gdn
RUN chmod +x /usr/local/concourse/bin/gdn

# containerd executables
ARG RUNC_VERSION=v1.0.0-rc8
ARG CNI_VERSION=v0.8.2
ARG CONTAINERD_VERSION=1.3.0

RUN curl -sSL https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION.linux-amd64.tar.gz \
      | tar -zvxf - -C /usr/local/concourse/bin --strip-components=1
RUN curl -sSL https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-amd64-$CNI_VERSION.tgz \
      | tar -zvxf - -C /usr/local/concourse/bin
RUN curl -sSL https://github.com/opencontainers/runc/releases/download/$RUNC_VERSION/runc.amd64 \
      -o /usr/local/concourse/bin/runc && chmod +x /usr/local/concourse/bin/runc


## add fly executables
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
RUN cd /src && \
      go mod download && \
      go install github.com/gobuffalo/packr/packr && \
      packr build -gcflags=all="-N -l" -o /usr/local/concourse/bin/concourse \
        ./cmd/concourse && \
      rm -rf /src

# volume for non-aufs/etc. mount for baggageclaim's driver
VOLUME /worker-state
ENV CONCOURSE_WORK_DIR /worker-state

# enable DNS proxy to support Docker's 127.x.x.x DNS server
ENV CONCOURSE_GARDEN_DNS_PROXY_ENABLE true

# 'web' keys
ENV CONCOURSE_SESSION_SIGNING_KEY     /concourse-keys/session_signing_key
ENV CONCOURSE_TSA_AUTHORIZED_KEYS     /concourse-keys/authorized_worker_keys
ENV CONCOURSE_TSA_HOST_KEY            /concourse-keys/tsa_host_key

# 'worker' keys
ENV CONCOURSE_TSA_PUBLIC_KEY          /concourse-keys/tsa_host_key.pub
ENV CONCOURSE_TSA_WORKER_PRIVATE_KEY  /concourse-keys/worker_key

# set $PATH for convenience
ENV PATH /usr/local/concourse/bin:${PATH}

ENTRYPOINT ["dumb-init", "concourse"]
