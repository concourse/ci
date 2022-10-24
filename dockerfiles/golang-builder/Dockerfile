ARG base_image_tag
FROM ubuntu:${base_image_tag}

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

ARG golang_version
RUN wget https://storage.googleapis.com/golang/go${golang_version}.linux-${BUILDARCH}.tar.gz
COPY ./golang-linux/go*.linux-*.tar.gz /go.linux-*.tgz

RUN tar -C /usr/local -xzf /go.linux-*.tgz \
  && rm /go.linux-*.tgz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

# disable cgo; we don't want to depend on or statically link libc
ENV CGO_ENABLED=0

# strip file system paths from built executables
ENV GOFLAGS=-trimpath

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH
