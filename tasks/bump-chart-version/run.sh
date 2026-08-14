#!/usr/bin/env bash

set -euo pipefail -x

apk add --no-progress --no-cache git cmd:sed

chart_version=$(cat version/version)

pushd concourse-chart
  # pattern line matching to find the correct lines
  sed -i "/type: application/,/version/ s/version: .*/version: ${chart_version}/" Chart.yaml

  git diff

  git config --global user.email "concourseteam+concourse-github-bot@gmail.com"
  git config --global user.name "Concourse Bot"

  git add -A
  git diff-index --quiet HEAD || git commit -m 'bump chart version' --signoff
popd
