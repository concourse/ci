#!/usr/bin/env bash

# k8s-delete - deletes a helm deployment.

set -euo pipefail

# name of the release to be deleted and purged.
readonly RELEASE_NAME="${RELEASE_NAME:-concourse-smoke}"
readonly DIR=$(cd $(dirname $0) && pwd)

source "ci/tasks/scripts/k8s-helpers.sh"

main() {
  gke_auth
  delete_release
}

delete_release() {
  helm version
  helm delete "$RELEASE_NAME" --namespace "$RELEASE_NAME"
  kubectl delete "pvc/data-$RELEASE_NAME-postgresql-0" -n "$RELEASE_NAME" || true
}

main "$@"
