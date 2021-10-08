#!/bin/bash

cd concourse

result=$(goimports -l ./**/*.go)
number_of_changed_files=$(echo ${result} | wc -l)

if [[ ${number_of_changed_files} -ne 0 ]]; then
  echo ${result}
  exit 1
fi

echo "formatting looks good!"
