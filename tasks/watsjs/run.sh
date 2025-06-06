#!/usr/bin/env bash

set -euo pipefail

cd concourse

# check if smoke tests already downloaded fly
if ! [ -e /usr/local/bin/fly ]; then
  go install ./fly
fi

cd web/wats

stty columns 80 # for better yarn output
corepack enable
yarn install

yarn test -v --color "$@"
