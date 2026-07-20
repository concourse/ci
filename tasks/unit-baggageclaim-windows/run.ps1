
. .\ci\tasks\scripts\go-build.ps1

cd .\concourse

go mod download

$GinkgoVersion = go list -f '{{.Version}}' -m github.com/onsi/ginkgo/v2
if ($LASTEXITCODE) { Throw "failed to determine Ginkgo version (exit code $LASTEXITCODE)" }

go install "github.com/onsi/ginkgo/v2/ginkgo@$GinkgoVersion"
if ($LASTEXITCODE) { Throw "Ginkgo installation failed (exit code $LASTEXITCODE)" }

$env:CGO_ENABLED = 1
ginkgo -r -p -flake-attempts=3 -race .\worker\baggageclaim

Exit $LastExitCode
