$ErrorActionPreference = "Stop"
trap { $host.SetShouldExit(1) }

# This is where go puts intermediate build artifacts, esp during testing
mkdir "$pwd\tmp"
$env:TMP = "$pwd\tmp"

$env:GOPATH = "$pwd\gopath"
$env:Path += ";$pwd\gopath\bin"
