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
RUN make static
RUN mkdir -p /output && cp runc /output/
RUN /output/runc --version
