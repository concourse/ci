#!/usr/bin/env bash

set -euo pipefail

apk add --quiet --no-progress curl jq

valid_labels=("bug" "misc" "enhancement" "breaking")

labels=$(curl -sf \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${OWNER}/${REPO}/pulls/${PRNUMBER}" \
  | jq -r '.labels[].name')

for label in $labels; do
  for valid in "${valid_labels[@]}"; do
    if [[ "$label" == "$valid" ]]; then
      echo "Found valid label: $label"
      exit 0
    fi
  done
done

echo "PR does not contain a valid label. Must have one of: ${valid_labels[*]}"
exit 1
