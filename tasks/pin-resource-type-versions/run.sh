#!/usr/bin/env bash

set -euo pipefail

apk add --quiet --no-progress python3 py3-pip git
pip install oyaml
python ci/tasks/pin-resource-type-versions/run.py

cd ci

git config --global user.email "concourseteam+concourse-github-bot@gmail.com"
git config --global user.name "Concourse Bot"

git add -A
git commit --allow-empty -m "pin resource type versions for release $RELEASE_MINOR"
