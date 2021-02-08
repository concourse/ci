Expand-Archive `
    -Path .\concourse-windows\concourse-*.tgz `
    -DestinationPath .\concourse
cd .\concourse

.\bin\concourse.exe --version

Expand-Archive `
    -LiteralPath .\fly-assets\fly-windows-amd64.zip `
    -DestinationPath .

.\fly.exe --version
