#!/bin/bash

set -euo pipefail

apk add --no-cache --no-progress \
    kubectl \
    google-cloud-sdk \
    gke-gcloud-auth-plugin

source "ci/tasks/scripts/k8s-helpers.sh"

gke_auth

echo "Deleting any topgun-* namespaces older than 4hrs"
cutoff=$(date -d @$(( $(date +%s) - 4*3600 )) +%s)
kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.creationTimestamp}{"\n"}{end}' \
  | while read -r name ts; do
      [[ "$name" == topgun-* ]] || continue
      [[ -n "$ts" ]] || continue
      created=$(date -d "$ts" +%s) || continue
      if (( created < cutoff )); then
        kubectl delete ns "$name"
      fi
    done
