. .\ci\tasks\scripts\go-build.ps1

cd .\concourse\fly

go mod download

go install github.com/onsi/ginkgo/ginkgo

ginkgo -r -p

Exit $LastExitCode
