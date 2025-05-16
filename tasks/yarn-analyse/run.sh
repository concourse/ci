#!/usr/bin/env bash

set -euo pipefail

# for better yarn output
stty columns 80

cd concourse
corepack enable
yarn install
yarn analyse
