#!/bin/bash

set -euo pipefail

cd repo

go get -u -t ./...
go mod tidy

if git --no-pager diff --quiet; then
    echo "No updates"
    exit 0
fi

# log changes
git --no-pager diff --color=always

echo "verifying changes don't break anything..."
go build ./...
go vet ./...
echo "Everything looks good!"

git config --global user.email "concourseteam+concourse-github-bot@gmail.com"
git config --global user.name "Concourse Bot"

git add -A
git commit -m "bump go dependencies"
