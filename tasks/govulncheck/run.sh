#!/usr/bin/env bash

set -euo pipefail

export GOPATH=$PWD/gopath
export PATH=$GOPATH/bin:$PATH

cd concourse

# WARNING: Always run govulncheck with the exact Go version declared in go.mod.
# Running with a newer Go binary evaluates stdlib against that newer release
# and hides Go standard library CVEs affecting the version in go.mod.
# Consequently, when a stdlib vulnerability is reported, resolve it by bumping
# the Go patch version in go.mod.
export GOTOOLCHAIN="go$(go list -m -f '{{.GoVersion}}')"

go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck -version

failed=0

echo "=== govulncheck (GOOS=linux) ==="
GOOS=linux govulncheck ./... || failed=1

# only these packages are built and tested for the other platforms
for goos in windows darwin; do
  echo "=== govulncheck (GOOS=${goos}) ==="
  GOOS="$goos" govulncheck ./cmd/concourse ./fly/... ./worker/baggageclaim/... ./go-archive/... || failed=1
done

exit "$failed"
