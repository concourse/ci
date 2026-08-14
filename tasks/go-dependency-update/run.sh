#!/bin/bash

set -euo pipefail

apk add --no-progress --no-cache git go

cd repo

go get -u -t ./...
go mod tidy

if git diff --quiet; then
    echo "No updates"
    exit 0
fi

# log changes
git diff

echo "verifying changes don't break anything..."
go build ./...
go vet ./...
echo "Everything looks good!"

git config --global user.email "concourseteam+concourse-github-bot@gmail.com"
git config --global user.name "Concourse Bot"

git add -A
git commit -m "bump go dependencies"
