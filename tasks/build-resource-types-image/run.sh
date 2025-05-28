#!/usr/bin/env bash

set -euo pipefail

for resource in $(ls | grep resource); do
    echo repacking ${resource}
    cd ${resource}
        resource=$(echo ${resource%-resource})
        tar czf rootfs.tgz --directory=rootfs/ .
        rm -rf ./rootfs/

        vr=$(cat tag)
        version=$(echo ${vr%%-*})
        privileged=$(if [[ ${resource} == "docker-image" ]]; then echo true; else echo false; fi;)
        version_history=$(if [[ ${resource} == "time" ]]; then echo true; else echo false; fi;)

        # TODO: use jq instead once we switch oci-build-task to use wolfi-base
        # which will allow us to easily pull in jq
        echo { >> resource_metadata.json
        echo \ \ \"type\": \"${resource}\", >> resource_metadata.json
        echo \ \ \"version\": \"${version}\", >> resource_metadata.json
        echo \ \ \"privileged\": ${privileged}, >> resource_metadata.json
        echo \ \ \"unique_version_history\": ${version_history} >> resource_metadata.json
        echo } >> resource_metadata.json

        rm metadata.json repository digest tag
    cd -
done;

build
