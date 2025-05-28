#!/usr/bin/env bash

set -euo pipefail

FILE=resource-type-versions/versions.yml

echo "untar-ing rc"
tar -zxf ./linux-rc/*.tgz concourse/resource-types --strip-components=1

for r in ./resource-types/*; do
  name=$(basename $r)
  version="v$(jq ".version" -r $r/resource_metadata.json)"
  echo "$name: $version" >> $FILE
done
