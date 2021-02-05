$ErrorActionPreference = "Stop"
trap { $host.SetShouldExit(1) }

# This is where go puts intermediate build artifacts, esp during testing
$silence = mkdir "$pwd\tmp" # assign just to silence output
$env:TMP = "$pwd\tmp"

$env:GOPATH = "$pwd\gopath"
$env:Path += ";$pwd\gopath\bin"

# disable cgo - this makes the Windows build consistent with Linux by not
# building code with the 'cgo' buildflag (e.g. sqlite3 in dex).
$env:CGO_ENABLED = "0"
