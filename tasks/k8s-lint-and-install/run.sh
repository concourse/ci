#!/usr/bin/env bash

set -euo pipefail

readonly DIR=$(cd $(dirname $0) && pwd)

source "ci/tasks/scripts/k8s-helpers.sh"

releasename="pr-$(cat concourse/.git/resource/pr)-$(head -c 6 concourse/.git/resource/base_sha)"

function cleanup {
    sleep 10
    helm delete "$releasename" --namespace "$releasename" || true
    kubectl delete --ignore-not-found=true namespace "$releasename"
}
trap cleanup EXIT

gke_auth

helm lint concourse
helm dependency update ./concourse
helm install \
  "$releasename" \
  ./concourse \
  --set=concourse.web.kubernetes.keepNamespaces=false \
  --namespace "$releasename" \
  --create-namespace
# TODO: actually poke concourse to see that it's up. For now this just ensures helm doesn't exit 1 when installing
