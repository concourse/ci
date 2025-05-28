#!/bin/sh

set -euo

BINARY_VERSION=$(/usr/local/concourse/bin/concourse --version)
echo "expecting: $EXPECTED_VERSION"
echo "got: $BINARY_VERSION"

if [ "$BINARY_VERSION" != "${EXPECTED_VERSION}" ]; then
  exit 1
fi
