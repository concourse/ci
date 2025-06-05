FROM cgr.dev/chainguard/wolfi-base

ARG TARGETARCH

COPY bosh-io-release-${TARGETARCH}/   /usr/local/concourse/resource-types/bosh-io-release/
COPY bosh-io-stemcell-${TARGETARCH}/  /usr/local/concourse/resource-types/bosh-io-stemcell/
COPY docker-image-${TARGETARCH}/      /usr/local/concourse/resource-types/docker-image/
COPY git-${TARGETARCH}/               /usr/local/concourse/resource-types/git/
COPY github-release-${TARGETARCH}/    /usr/local/concourse/resource-types/github-release/
COPY hg-${TARGETARCH}/                /usr/local/concourse/resource-types/hg/
COPY mock-${TARGETARCH}/              /usr/local/concourse/resource-types/mock/
COPY pool-${TARGETARCH}/              /usr/local/concourse/resource-types/pool/
COPY registry-image-${TARGETARCH}/    /usr/local/concourse/resource-types/registry-image/
COPY s3-${TARGETARCH}/                /usr/local/concourse/resource-types/s3/
COPY semver-${TARGETARCH}/            /usr/local/concourse/resource-types/semver/
COPY time-${TARGETARCH}/              /usr/local/concourse/resource-types/time/
