#!/usr/bin/env sh

set -euo

apk add --quiet --no-progress trivy

echo "unpacking vulnerability db"

TRIVY_TEMP_DIR=$(mktemp -d)
trivy --cache-dir $TRIVY_TEMP_DIR image --download-db-only
tar -cf ./trivy-db/db.tar.gz -C $TRIVY_TEMP_DIR/db metadata.json trivy.db
rm -rf $TRIVY_TEMP_DIR
