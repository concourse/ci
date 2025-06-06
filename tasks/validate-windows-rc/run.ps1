$ErrorActionPreference = "Stop"
trap { $host.SetShouldExit(1) }

Expand-Archive `
    -Path .\concourse-tarballs\concourse-*.zip `
    -DestinationPath .
cd .\concourse

.\bin\concourse.exe --version

Expand-Archive `
    -LiteralPath .\fly-assets\fly-windows-amd64.zip `
    -DestinationPath .

.\fly.exe --version
