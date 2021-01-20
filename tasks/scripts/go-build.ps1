Set-PSDebug -Trace 1

$ErrorActionPreference = "Stop"
trap { $host.SetShouldExit(1) }

# This is where go puts intermediate build artifacts, esp during testing
$silence = mkdir "$pwd\tmp" # assign just to silence output
$env:TMP = "$pwd\tmp"

$env:GOPATH = "$pwd\gopath"
$env:Path += ";$pwd\gopath\bin"
