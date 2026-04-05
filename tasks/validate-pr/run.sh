#!/usr/bin/env bash

set -euo pipefail

chmod +x validator/releaseme

validator/releaseme validate \
    --github-token=$GITHUB_TOKEN \
    --github-owner=concourse \
    --github-repo=concourse \
    --pr-number=$PRNUMBER
