set GOPATH=%CD%\gopath
set PATH=%CD%\gopath\bin;%PATH%

cd .\concourse\worker\baggageclaim

go mod download

go install github.com/onsi/ginkgo/v2/ginkgo

ginkgo -r -p
