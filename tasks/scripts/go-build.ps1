$ErrorActionPreference = "Stop"
trap { $host.SetShouldExit(1) }

# This is where go puts intermediate build artifacts, esp during testing
$env:TMP = "$pwd\tmp"

$env:GOPATH = "$pwd\gopath"
$env:Path += ";$pwd\gopath\bin"
