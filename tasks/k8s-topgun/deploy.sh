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

mkdir -p "${HOME}/.kube"
cp "${output}/config" "${HOME}/.kube/config"

echo "changing default storage class"
# For some reason the default stoarge class that linode sets results in
# volumes being made but never attached to the nodes. Switching to the
# non-default storage class fixes this for whatever reason. This is fine
# anyways as we don't want volumes that we retain, we want them destroyed
# after we're done using them which is what the non-default storage class
# does
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
  sleep 20s
done
