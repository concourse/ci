#!/usr/bin/env bash

set -euo pipefail -x

postgres_version=$(cat postgres-chart-release/version)

pushd concourse-chart
  # pattern match for the postgresql dependency lines
  sed -i "/- name: postgresql/,/version/ s/version: .*/version: ${postgres_version}/" Chart.yaml

  helm dependency update

  git config --global user.email "concourseteam+concourse-github-bot@gmail.com"
  git config --global user.name "Concourse Bot"

  git add -A
  git commit -m "bump postgres version" --signoff
popd
