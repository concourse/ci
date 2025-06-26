#!/usr/bin/env bash

# k8s-deploy - deploys Concourse on a K8S cluster using
# a helm charts provided under `./charts`.

set -euo pipefail

# Variables that can be either be configured
# by making use of environment variables when
# executing `k8s-deploy` or the default values.
readonly RELEASE_NAME="${RELEASE_NAME:-concourse-smoke}"
readonly CONCOURSE_DIGEST="${CONCOURSE_DIGEST:-$(cat ./image-info/digest)}"

source "ci/tasks/scripts/k8s-helpers.sh"

main() {
  gke_auth
  run_helm_deploy
}

run_helm_deploy() {
  local chart=./concourse-chart

  helm version
  helm dependency update $chart

  # Construct Helm command dynamically based on CONCOURSE_IMAGE presence
  helm_args=(
    --install
    --wait
    --namespace "$RELEASE_NAME"
    --create-namespace
    --set "concourse.web.auth.mainTeam.localUser=admin"
    --set "concourse.web.kubernetes.enabled=false"
    --set "concourse.worker.baggageclaim.driver=overlay"
    --set "persistence.enabled=false"
    --set "postgresql.persistence.enabled=false"
    --set "secrets.localUsers=admin:admin\,guest:guest"
    --set "web.livenessProbe.failureThreshold=3"
    --set "web.livenessProbe.initialDelaySeconds=10"
    --set "web.livenessProbe.periodSeconds=10"
    --set "web.livenessProbe.timeoutSeconds=3"
    --set "worker.replicas=1"
    "$RELEASE_NAME"
    "$chart"
  )

  # Add image parameters **only if CONCOURSE_IMAGE is set**
  if [[ -n "$CONCOURSE_IMAGE" ]]; then
    helm_args+=(--set "image=$CONCOURSE_IMAGE")
    helm_args+=(--set "imageDigest=$CONCOURSE_DIGEST")
  fi

  # Helm's --recreate-pods flag is deprecated and removed in helm v3. Using
  # kubectl to delete any pre-existing pods
  echo "Removing any pre-existing pods in namespace ${RELEASE_NAME}"
  kubectl \
    --namespace "$RELEASE_NAME" \
    delete namespace \
    --now=true --wait=true \
    --ignore-not-found=true

  # Run Helm upgrade with dynamically built arguments
  helm upgrade "${helm_args[@]}"

  kubectl \
    --namespace "$RELEASE_NAME" \
    rollout status deployment \
    "$RELEASE_NAME-web"
}

main "$@"
