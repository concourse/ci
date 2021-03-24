. .\ci\tasks\scripts\go-build.ps1

$currentRef = & git -C concourse rev-parse --short HEAD

$version = "$(Get-Content "version\version")+$currentRef"

$archive = "concourse-${version}.windows.amd64.zip"

# can't figure out how to pass an empty string arg in PowerShell, so just
# configure a noop for the fallback
$ldflags = "-X noop.Noop=noop"
if (Test-Path "final-version\version") {
  $finalVersion = (Get-Content "final-version\version")
  $ldflags = "-X github.com/concourse/concourse.Version=$finalVersion"
}

Push-Location concourse
  go build -o concourse.exe -ldflags "$ldflags" -buildmode=exe ./cmd/concourse
  mv concourse.exe ..\concourse-windows
Pop-Location

Push-Location concourse-windows
  mkdir bin
  mv concourse.exe bin

  mkdir fly-assets
  if (Test-Path "..\fly-linux") {
    cp ..\fly-linux\fly-*.tgz fly-assets
  }

  if (Test-Path "..\fly-windows") {
    cp ..\fly-windows\fly-*.zip fly-assets
  }

  if (Test-Path "..\fly-darwin") {
    cp ..\fly-darwin\fly-*.tgz fly-assets
  }

  mkdir concourse
  mv bin concourse
  mv fly-assets concourse

  Compress-Archive `
    -LiteralPath .\concourse `
    -DestinationPath ".\${archive}"

  Get-FileHash -Algorithm SHA1 ".\${archive}" | `
    Out-File -Encoding utf8 ".\${archive}.sha1"

  Remove-Item .\concourse -Recurse
Pop-Location
