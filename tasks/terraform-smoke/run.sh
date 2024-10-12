#!/usr/bin/env bash

set -euo pipefail

outputs=$PWD/outputs

script_dir=${0%/*}

deployment_path="${script_dir}/deployment"

if [ -d linux-rc ]; then
  cp linux-rc/concourse-*.tgz "${deployment_path}/concourse.tgz"
fi

cd $deployment_path

echo "${SSH_KEY}" > "keys/private_key"
chmod 0600 "keys/private_key"

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
  --replace 'hcloud_server.main'

terraform output -json \
  | jq 'with_entries(.value |= .value)' > "${outputs}/outputs.json"
