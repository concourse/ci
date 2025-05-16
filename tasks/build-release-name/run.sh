#!/usr/bin/env bash

set -euo pipefail

if [ -d version ]; then
  version=v$(cat version/version)
elif [ "$#" -eq 1 ]; then
  version=$1
else
  echo "version must be specified, either as an argument or an input" >&2
  exit 1
fi

echo "$version" > ./release-name/release-name
