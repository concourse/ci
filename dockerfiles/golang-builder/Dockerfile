ARG base_image
FROM ${base_image:-cgr.dev/chainguard/wolfi-base}

RUN apk --update-cache add \
    ca-certificates \
    git \
    go-1.24
RUN apk cache purge

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/lib/go/bin:$PATH

# disable cgo; we don't want to depend on or statically link libc
ENV CGO_ENABLED=0

# strip file system paths from built executables
ENV GOFLAGS=-trimpath

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH
