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
  | jq -r '.kube_config.value' | base64 -d > "${output}/config"
chmod go-r "${output}/config"

echo "Waiting for all nodes in node pool to be ready"
mkdir -p "${HOME}/.kube"
cp "${output}/config" "${HOME}/.kube/config"

while true; do
  pods="$(kubectl get nodes --no-headers | wc -l)"
  # the ${// /} is to remove any spaces
  if [[ "${pods// /}" == "8" ]]; then
    echo "All pods connected to the control plane"
    exit 0
  fi
  sleep 20s
done
