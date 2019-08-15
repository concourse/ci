FROM ubuntu AS base

  ARG distro

  COPY bosh-io-release-resource/bosh-io-release-resource-*${distro}.tgz    /concourse-resource-types/bosh-io-release.tgz
  COPY bosh-io-stemcell-resource/bosh-io-stemcell-resource-*${distro}.tgz  /concourse-resource-types/bosh-io-stemcell.tgz
  COPY cf-resource/cf-resource-*${distro}.tgz                              /concourse-resource-types/cf.tgz
  COPY docker-image-resource/docker-image-resource-*${distro}.tgz          /concourse-resource-types/docker-image.tgz
  COPY git-resource/git-resource-*${distro}.tgz                            /concourse-resource-types/git.tgz
  COPY github-release-resource/github-release-resource-*${distro}.tgz      /concourse-resource-types/github-release.tgz
  COPY hg-resource/hg-resource-*${distro}.tgz                              /concourse-resource-types/hg.tgz
  COPY mock-resource/mock-resource-*${distro}.tgz                          /concourse-resource-types/mock.tgz
  COPY pool-resource/pool-resource-*${distro}.tgz                          /concourse-resource-types/pool.tgz
  COPY registry-image-resource/registry-image-resource-*${distro}.tgz      /concourse-resource-types/registry-image.tgz
  COPY s3-resource/s3-resource-*${distro}.tgz                              /concourse-resource-types/s3.tgz
  COPY semver-resource/semver-resource-*${distro}.tgz                      /concourse-resource-types/semver.tgz
  COPY time-resource/time-resource-*${distro}.tgz                          /concourse-resource-types/time.tgz
  COPY tracker-resource/tracker-resource-*${distro}.tgz                    /concourse-resource-types/tracker.tgz

  RUN set -e; \
        for tgz in /concourse-resource-types/*.tgz; do \
          file=$(basename $tgz); \
          dir=/usr/local/concourse/resource-types/${file%.*}; \
          mkdir -p $dir; \
          tar -C $dir -zxf $tgz; \
        done;


FROM busybox

  COPY --from=base /usr/local/concourse/resource-types/ /usr/local/concourse/resource-types/

