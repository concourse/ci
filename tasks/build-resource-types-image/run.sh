#!/usr/bin/env bash

set -euo pipefail

for resource in ./*-resource; do
    echo repacking "${resource}"
    pushd "${resource}"
        resource=${resource%-resource}
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

build
