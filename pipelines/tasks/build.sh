#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export BASE="$PWD"

pushd src/code.cloudfoundry.org/quarks-operator
  bin/tools
  bin/build
  . bin/include/versioning
  echo "$ARTIFACT_VERSION" > "$BASE"/docker/tag
popd

cp src/code.cloudfoundry.org/quarks-operator/binaries/cf-operator "binaries/cf-operator-$ARTIFACT_VERSION"
