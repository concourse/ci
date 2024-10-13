#!/usr/bin/env bash

set -euo pipefail

script_dir=${0%/*}
deployment_path="${script_dir}/deployment"
output="$(pwd)/kubeconfig"

cd $deployment_path

terraform init

terraform workspace select "$WORKSPACE" || \
  terraform workspace new "$WORKSPACE"

if [[ "${cleanup,,}" == "true" ]]; then
  terraform destroy \
    --auto-approve

  exit 0
fi

terraform apply \
  --auto-approve \
  --replace 'linode_lke_cluster.main'

terraform output -json \
  | jq -r '.kube_config.value' | base64 -D > "${output}/config"
