#!/bin/bash

cd concourse

result=$(goimports -l ./**/*.go)
number_of_changed_files=$(echo -n ${result} | wc -l)

if [[ ${number_of_changed_files} -ne 0 ]]; then
  echo "!!! Please format the following files using golang.org/x/tools/cmd/goimports !!!"
  echo "Install goimports with: go install golang.org/x/tools/cmd/goimports@latest"
  echo ${result}
  exit 1
fi

echo "Formatting looks good!"
