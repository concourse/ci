. .\ci\tasks\scripts\go-build.ps1

cd .\concourse\fly

go mod download

go install -mod=mod github.com/onsi/ginkgo/v2/ginkgo

ginkgo -r -p

Exit $LastExitCode
