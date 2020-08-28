#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

pushd src/code.cloudfoundry.org/quarks-operator
  bin/tools
  . bin/include/versioning
  echo "$ARTIFACT_VERSION" > docker/tag
  bin/build
popd

cp src/code.cloudfoundry.org/quarks-operator/binaries/cf-operator "binaries/cf-operator-$ARTIFACT_VERSION"
