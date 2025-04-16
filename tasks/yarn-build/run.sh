#!/usr/bin/env bash

set -euo pipefail

# for better yarn output
stty columns 80

pushd concourse
  corepack enable
  yarn install
  yarn build
popd

cp -a ./concourse/. ./built-concourse
