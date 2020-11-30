#!/bin/bash

set -eu

concourse/bin/concourse worker \
    --work-dir ./work \
    --tsa-host ci.concourse-ci.org:2222 \
    --tsa-public-key ./keys/tsa-host-key.pub \
    --tsa-worker-private-key ./keys/worker-key \
    --team main
