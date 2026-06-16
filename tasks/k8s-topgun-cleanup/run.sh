#!/bin/bash

set -euo pipefail

apk --no-cache --no-progress \
    kubectl \
    google-cloud-sdk \
    gke-gcloud-auth-plugin

source "ci/tasks/scripts/k8s-helpers.sh"

gke_auth

echo "Deleting any topgun-* namespaces older than 4hrs"
cutoff=$(date -d '4 hours ago' +%s)
kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.creationTimestamp}{"\n"}{end}' | while read -r name ts; do [[ "$name" == topgun-* ]] && [ "$(date -d "$ts" +%s)" -lt "$cutoff" ] && kubectl delete ns "$name"; done
