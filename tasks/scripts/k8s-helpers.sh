#!/bin/bash

ensure_kube_config() {
  mkdir -p ~/.kube

  if [[ -f ~/.kube/config ]]; then
    return 0
  fi

  if [[ -z $KUBE_CONFIG ]]; then
    echo "Error: KUBE_CONFIG must be specified when ~/.kube/config doesnt exist"
    exit 1
  fi

  echo "$KUBE_CONFIG" >~/.kube/config

  # Our kube config uses the gcp auth-provider to fetch an access token
  # dynamically using a service account, so this must be set.
  echo "$SERVICE_ACCOUNT_KEY" > ~/service-account.json
  export GOOGLE_APPLICATION_CREDENTIALS=~/service-account.json
}

gke_auth() {
  echo "$SERVICE_ACCOUNT_KEY" > ~/service-account.json
  export GOOGLE_APPLICATION_CREDENTIALS=~/service-account.json

  gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
  gcloud container clusters get-credentials k8s-topgun --project cf-concourse-production --zone us-central1-a
}
