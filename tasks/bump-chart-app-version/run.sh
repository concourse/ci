#!/usr/bin/env bash

set -euo pipefail -x

apk add --no-progress --no-cache git cmd:sed

concourse_version=$(cat concourse-release/version)

pushd concourse-chart
  sed -i "s/appVersion: .*/appVersion: ${concourse_version}/g" Chart.yaml
  sed -i "1,/imageTag/s/imageTag: .*/imageTag: \"${concourse_version}\"/g" values.yaml
  sed -i "s/Concourse image version | .* |/Concourse image version | \`${concourse_version}\` |/g" README.md

  git --no-pager diff

  git config --global user.email "concourseteam+concourse-github-bot@gmail.com"
  git config --global user.name "Concourse Bot"

  git add -A
  git commit -m "bump app version and image tag" --signoff
popd
