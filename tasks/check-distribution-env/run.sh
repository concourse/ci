#!/usr/bin/env bash

# diff - verifies if there are any concourse parameters that are missing from
# the distribution's configurable parameters
#
# Environment variables:
#   DISTRIBUTION    Distribution, i.e. 'helm' or 'bosh'

set -euo pipefail

distro_dir=$PWD/distribution
linux_rc=$PWD/linux-rc

if [ -z "$DISTRIBUTION" ]; then
  echo "missing required env $DISTRIBUTION" >&2
  exit 1
fi

distro_scripts=$(dirname "$0")/$DISTRIBUTION

main() {
  local variables_in_packaging=$(get_distribution_variables | sort -u)
  local variables_supported_by_binary=$(get_concourse_variables | sort -u)

  local unsupported_by_binary=$(comm -23 <(echo "$variables_in_packaging") <(echo "$variables_supported_by_binary"))
  local missing_from_packaging=$(comm -13 <(echo "$variables_in_packaging") <(echo "$variables_supported_by_binary"))

  if [[ ! -z $unsupported_by_binary ]]; then
    echo "Error: found some variables in the ${DISTRIBUTION} packaging that might not be supported by the Concourse binary:"
    echo "$unsupported_by_binary"
  fi

  if [[ ! -z $missing_from_packaging ]]; then
    echo "Error: found some variables supported by the Concourse binary that are missing from the ${DISTRIBUTION} packaging:"
    echo "$missing_from_packaging"
  fi

  if [[ -z $unsupported_by_binary ]] && [[ -z $missing_from_packaging ]]; then
    echo "All good!"
    exit 0
  fi

  exit 1
}

get_distribution_variables() {
  "${distro_scripts}/list-actual" "$distro_dir" | filter_list ignored-in-distribution
}

get_concourse_variables() {
    tar -zxf "${linux_rc}"/concourse-*.tgz -C "$linux_rc"

  for subcommand in web worker; do
    "${linux_rc}/concourse/bin/concourse" $subcommand --help 2>&1 |
      grep -o '\[\$.*\]' |
      tr -d \[\]\$
  done | filter_list ignored-in-concourse
}

filter_list() {
  local filter="$(cat "$distro_dir/packaging-state/$1" | xargs | tr ' ' '|')"

  if [ -z "$filter" ]; then
    tee
  else
    grep -E -v "$filter"
  fi
}

main "$@"
