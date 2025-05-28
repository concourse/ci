#!/usr/bin/env bash

set -euo pipefail

outputs=$PWD/outputs

deployment_path=ci/deployments/smoke

if [ -d linux-rc ]; then
  cp linux-rc/concourse-*.tgz $deployment_path/concourse.tgz
fi

cd $deployment_path

echo "$GCP_KEY" > keys/gcp.json

echo "$SSH_KEY" > keys/id_rsa
chmod 0600 keys/id_rsa
ssh-keygen -y -f keys/id_rsa > keys/id_rsa.pub

terraform init

terraform workspace select "$WORKSPACE" || \
  terraform workspace new "$WORKSPACE"

terraform apply \
  --auto-approve \
  --var project=$GCP_PROJECT \
  --replace="google_compute_instance.smoke" \

{
  terraform output -json | \
    jq -r 'keys[] as $k | "\($k) \(.[$k].value)"'
} | while read name value; do
  echo "$value" > $outputs/$name
done
