#!/usr/bin/env bash

set -euo pipefail

readonly RELEASE_NAME="$RELEASE_NAME"

source "ci/tasks/scripts/k8s-helpers.sh"

main () {
  gke_auth
  forward_atc_port
  run_test
}

forward_atc_port () {
  ulimit -n 65536
  kubectl port-forward \
    --namespace $RELEASE_NAME \
    deployment/$RELEASE_NAME-web \
    --pod-running-timeout=5m \
    8080:8080 >/dev/null &
}

run_test () {
  ATC_URL="http://127.0.0.1:8080" "ci/tasks/smoke-test/run.sh"
}

main
