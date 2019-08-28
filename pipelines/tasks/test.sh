#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

version=

if [ -f s3.build-number/version ]; then
  version=$(cat s3.build-number/version)
fi
export GOVER_FILE=gover-${version}-unit.coverprofile

make -C src/code.cloudfoundry.org/cf-operator test-unit

find src/code.cloudfoundry.org/cf-operator/code-coverage -name gover-*.coverprofile | xargs -r cp -t code-coverage/
