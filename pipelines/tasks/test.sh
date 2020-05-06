#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

make -C src/code.cloudfoundry.org/quarks-operator test-unit

if [ -n "$COVERAGE" ] && [ -f s3.build-number/version ]; then
  version=$(cat s3.build-number/version)
  gover_file=gover-${version}-unit.coverprofile
  # add missing newlines to work around gover bug: https://github.com/sozorogami/gover/issues/9
  find src/code.cloudfoundry.org/quarks-operator/code-coverage -type f | while read -r f; do echo >> "$f"; done
  gover src/code.cloudfoundry.org/quarks-operator/code-coverage code-coverage/"$gover_file"
fi
