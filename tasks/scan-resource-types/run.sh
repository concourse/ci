#!/bin/sh

set -euo pipefail

apk add --quiet --no-progress trivy

echo "unpacking vulnerability db"
cache_dir=`pwd`
mkdir -p "${cache_dir}/db"
tar -xvf trivy-db/db.tar.gz -C "${cache_dir}/db"

failed=""
cd image/rootfs/usr/local/concourse/resource-types

set +e

ignore_policy=""
if [ -f "$IGNORE_POLICY_FILE" ]; then
  ignore_policy="--ignore-policy $IGNORE_POLICY_FILE"
fi

for resource in *; do
  echo ""
  echo "scanning ${resource}-resource:"

  cd "$resource"
  tar -xzf rootfs.tgz

  trivy \
    --cache-dir "$cache_dir" \
    --quiet \
    filesystem $ignore_policy \
    --severity "HIGH,CRITICAL" \
    --ignore-unfixed \
    --exit-code 1 \
    .

  if [ $? -ne 0 ]; then
    failed="${failed}\n-${resource}"
  fi

  cd ..
done

if [ "$failed" != "" ]; then
  echo "the following resource-types failed the scan: $failed"
  exit 1
fi
