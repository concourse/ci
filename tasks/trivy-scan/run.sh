#!/bin/sh

set -euo

apk add --quiet --no-progress trivy

ignore_policy=""
if [ -f "$IGNORE_POLICY_FILE" ]; then
  ignore_policy="--ignore-policy $IGNORE_POLICY_FILE"
fi

trivy \
  --cache-dir $(pwd) \
  image \
  --severity "HIGH,CRITICAL" \
  --ignore-unfixed \
  --exit-code 1 \
  --input "${IMAGE_PATH}" \
  $ignore_policy
