$ErrorActionPreference = "Stop"
trap { $host.SetShouldExit(1) }

# This is where go puts intermediate build artifacts, esp during testing
$env:TMP = "$pwd\tmp"

$env:Path += ";C:\Go\bin;C:\Program Files\Git\cmd;C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin"

$env:GOPATH = "$pwd\gopath"
$env:Path += ";$pwd\gopath\bin"
