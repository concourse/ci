set GOPATH=%CD%\gopath
set PATH=%CD%\gopath\bin;%PATH%

cd .\concourse\worker\baggageclaim

go mod download

go install -mod=mod github.com/onsi/ginkgo/ginkgo

ginkgo -r -p
