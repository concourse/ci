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
  echo "removing any leftover topgun namespaces to ensure all volumes in Linode are deleted"

  # Adding '|| true' to ignore any errors, except for the final 'terraform destroy'
  terraform output -json \
    | jq -r '.kube_config.value' \
    | base64 -d > "${output}/config" \
    || true
  chmod go-r "${output}/config"

  kubectl get namespaces \
    --no-headers \
    --output custom-columns=':metadata.name' \
    | grep '^topgun' \
    | xargs -I % kubectl delete namespace % --wait=true \
    || true

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

mkdir -p "${HOME}/.kube"
cp "${output}/config" "${HOME}/.kube/config"

echo "changing default storage class to ephemeral class"
kubectl patch storageclass linode-block-storage-retain -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass linode-block-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass

echo "Waiting for all nodes in node pool to be ready"
while true; do
  pods="$(kubectl get nodes --no-headers | grep -v NotReady | wc -l)"
  # the ${// /} is to remove any spaces
  if [[ "${pods// /}" == "8" ]]; then
    echo "All pods connected to the control plane"
    exit 0
  fi
  sleep 20
done
