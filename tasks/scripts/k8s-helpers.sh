#!/bin/bash

gke_auth() {
  echo "$SERVICE_ACCOUNT_KEY" > ~/service-account.json
  export GOOGLE_APPLICATION_CREDENTIALS=~/service-account.json
  export USE_GKE_GCLOUD_AUTH_PLUGIN="True"

  gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
  gcloud container clusters get-credentials k8s-topgun --project cf-concourse-production --zone us-central1-a
}
