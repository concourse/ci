#!/usr/bin/env bash

set -euo pipefail

PRNUMBER=$(cat concourse-pr/.git/resource/pr)

chmod +x validator/releaseme

validator/releaseme validate \
    --github-token=$GITHUB_TOKEN \
    --github-owner=concourse \
    --github-repo=concourse \
    --pr-number=$PRNUMBER
