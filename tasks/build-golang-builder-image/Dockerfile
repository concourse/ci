ARG base_image=cgr.dev/chainguard/wolfi-base:latest
ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM ${base_image} AS go_downloader

RUN apk --no-cache add \
    ca-certificates \
    curl \
    gzip

ARG golang_version
ARG TARGETARCH
RUN curl https://storage.googleapis.com/golang/go${golang_version}.linux-${TARGETARCH}.tar.gz -o go.linux.tar.gz
RUN gzip -d go.linux.tar.gz
RUN tar -C /usr/local -xf go.linux.tar && rm go.linux.tar

FROM ${base_image}

RUN apk --no-cache add \
    ca-certificates \
    bash

COPY --from=go_downloader /usr/local/go /usr/local/
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

# disable cgo; we don't want to depend on or statically link libc
ENV CGO_ENABLED=0

# strip file system paths from built executables
ENV GOFLAGS=-trimpath

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH
