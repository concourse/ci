#!/usr/bin/env bash

set -euo pipefail

deployment_path=ci/deployments/smoke

cd $deployment_path

echo "$GCP_KEY" > keys/gcp.json

echo "$SSH_KEY" > keys/id_rsa
chmod 0600 keys/id_rsa
ssh-keygen -y -f keys/id_rsa > keys/id_rsa.pub

terraform init

terraform workspace select "$WORKSPACE"

terraform destroy \
  --var project=$GCP_PROJECT \
  --auto-approve
