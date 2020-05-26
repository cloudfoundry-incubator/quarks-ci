#!/bin/bash

set -e -u -x

usage() {
  echo "Usage: $0 task.sh git-dir"
}

succeed_early() {
  exit 0
}


dir="${1-}"
if [ -z ${dir+x} ] || [ ! -d "$dir" ]; then
  echo "missing git dir to check for changes"
  usage
  exit 1
fi

task="${2-}"
if [ -z ${task+x} ]; then
  echo "missing task script which is conditionally executed"
  usage
  exit 1
fi

shift 2

pushd "$dir"

# after excluding all lines matching the regex, exit if no lines are left
if [ ${SUCCEED_UNLESS_CHANGES_BEYOND+x} ]; then
  lines=$( git diff --name-only HEAD~1 | \
    grep -E -v "$SUCCEED_UNLESS_CHANGES_BEYOND" )
  if [ -z "$lines" ]; then
    succeed_early
  fi
fi

# if changes do not include any lines matching the regex, exit early
if [ ${SUCCEED_UNLESS_CHANGES_CONTAIN+x} ]; then
  git diff --name-only HEAD~1 | \
    grep -q -E "$SUCCEED_UNLESS_CHANGES_CONTAIN" || succeed_early
fi

popd

exec "$task" "$@"
