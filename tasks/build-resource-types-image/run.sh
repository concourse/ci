#!/usr/bin/env bash

set -euo pipefail

for arch in amd64 arm64; do
for resource in ./*-"${arch}"; do
    echo repacking "${resource}"
    pushd "${resource}"
        resource=${resource%-"$arch"}
        tar czf rootfs.tgz --directory=rootfs/ .
        rm -rf ./rootfs/

        vr=$(cat tag)
        version=${vr%%-*}
        privileged=$(if [[ ${resource} == "docker-image" ]]; then echo true; else echo false; fi;)
        version_history=$(if [[ ${resource} == "time" ]]; then echo true; else echo false; fi;)

        jq -n \
          --arg type "${resource}" \
          --arg version "${version}" \
          --argjson privileged "${privileged}" \
          --argjson unique_version_history "${version_history}" \
          '{
            "type": $type,
            "version": $version,
            "privileged": $privileged,
            "unique_version_history": $unique_version_history
          }' > resource_metadata.json

        rm metadata.json repository digest tag
    popd
done;
done;

build
