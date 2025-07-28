#!/usr/bin/env sh

set -euo pipefail

apk add --quiet --no-progress jq ytt

echo "$RESOURCES" | jq -r '.[]' | while read -r resource; do
  echo "rendering '$resource' pipeline config..."
  ytt --data-value resource_name="$resource" -f pipelines/pipelines/resources/ \
    > "rendered_pipelines/$resource.yml"
  echo ""
done
