#!/usr/bin/env bash

set -euo pipefail

apk add --quiet --no-progress py3-pip git
pip install oyaml
python ci/tasks/pin-resource-type-versions/run.py

cd ci

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

git add -A
git commit --allow-empty -m "pin resource type versions for release $RELEASE_MINOR"
