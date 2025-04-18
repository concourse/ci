ARG base_image=cgr.dev/chainguard/wolfi-base:latest
FROM ${base_image}

RUN apk --no-cache add \
    ca-certificates \
    git \
    go-1.24 && \
    rm -rf /var/cache/apk/*

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/lib/go/bin:$PATH

# disable cgo; we don't want to depend on or statically link libc
ENV CGO_ENABLED=0

# strip file system paths from built executables
ENV GOFLAGS=-trimpath

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH
