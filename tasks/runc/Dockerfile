ARG base_image=concourse/golang-builder
FROM ${base_image}

RUN apk --no-cache --no-progress add \
    libseccomp-dev \
    libseccomp-static \
    gcc \
    git \
    make \
    pkgconf

ENV PKG_CONFIG_PATH=/usr/lib/pkgconfig/

WORKDIR /src
COPY . /src
# libpathrs was added in v1.5.0. In the future, review if we should enable it
# in our builds of runc
RUN make RUNC_BUILDTAGS="-libpathrs" static
RUN mkdir -p /output && cp runc /output/
RUN /output/runc --version
