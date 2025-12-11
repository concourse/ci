#!/usr/bin/env bash

set -euo pipefail

# Removes all releases whose:
# - name starts with "concourse"
# - version contains "dev"
# - is not one of the four latest versions uploaded
# - is not currently being used, denoted by the version containing an asterisk
releases=$(bosh releases --json | jq '
  .Tables[0].Rows
  | [.[] | select(.name | startswith("concourse")) | select(.version | contains("dev")) | select(.version | contains("*") | not)]
  | group_by(.name)
  | map(.[4:])
  | flatten
  | .[]
  | "\(.name)/\(.version)"')


while IFS= read -r release; do
  if [[ -n "$release" ]]; then
    echo "Deleting release: $release"
    bosh --non-interactive delete-release "$release"
  fi
done <<< "$releases"
