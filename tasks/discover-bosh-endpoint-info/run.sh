#!/usr/bin/env bash

set -euo pipefail

# print once just to see useful output in CI
bosh instances

HOSTNAME=$(bosh instances | grep "${BOSH_INSTANCE_GROUP}/" | awk '{print $4}' | head -n1)

echo "http://${HOSTNAME}:8080" > endpoint-info/instance_url
