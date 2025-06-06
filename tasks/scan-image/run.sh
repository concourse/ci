#!/bin/sh

set -euo

apk add --quiet --no-progress trivy

echo "unpacking vulnerability db"
cache_dir=`pwd`
mkdir -p "${cache_dir}/db"
tar -xvf trivy-db/db.tar.gz -C "${cache_dir}/db"

ignore_policy=""
if [ -f "$IGNORE_POLICY_FILE" ]; then
  ignore_policy="--ignore-policy $IGNORE_POLICY_FILE"
fi

echo "scanning base os"
trivy \
  --cache-dir "${cache_dir}" \
  --quiet \
  image \
  --severity "HIGH,CRITICAL" \
  --ignore-unfixed \
  --exit-code 1 \
  --input image/image.tar \
  --ignorefile ./ci/.trivyignore.yaml \
  $ignore_policy
