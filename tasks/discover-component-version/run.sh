#!/usr/bin/env bash

set -euo pipefail

if [ "$COMPONENT_NAME" == "helm" ]; then
  helm version --template "{{.Version}}" > "./component-version/helm-version-${CONCOURSE_VERSION}.txt"
else
  dpkg -l | grep "${COMPONENT_NAME}-[0-9]\.*.*[0-9]*" | awk '$1=="ii" { print $3 }' | cut -d. -f1,2 \
    > "./component-version/${COMPONENT_NAME}-version-${CONCOURSE_VERSION}.txt"
fi
