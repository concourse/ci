# TODO (vito): rolling forward to bionic or fossa breaks watsjs - pending
# investigation
#
# concourse/concourse#6427
FROM ubuntu:xenial

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY ./golang-linux/go*.linux-amd64.tar.gz /go.linux-amd64.tgz

RUN tar -C /usr/local -xzf /go.linux-amd64.tgz \
  && rm /go.linux-amd64.tgz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

# disable cgo; we don't want to depend on or statically link libc
ENV CGO_ENABLED=0

# strip file system paths from built executables
# TODO: once go 1.16 hits, uncomment this. currently, it's breaking packr
# when running unit tests that run migrations
# ENV GOFLAGS=-trimpath

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH
