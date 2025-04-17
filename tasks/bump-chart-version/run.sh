#!/usr/bin/env bash

set -euo -x pipefail

chart_version=$(cat version/version)

pushd concourse-chart
  # pattern line matching to find the correct lines
  sed -i "/type: application/,/version/ s/version: .*/version: ${chart_version}/" Chart.yaml

  git diff

  git config --global user.email "ci@localhost.com"
  git config --global user.name "CI Bot"

  git add -A
  git diff-index --quiet HEAD || git commit -m 'bump chart version' --signoff
popd
