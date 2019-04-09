#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

version=$(cat s3.build-number/version)
export GOVER_FILE=gover-${version}-unit.coverprofile

make -C src/code.cloudfoundry.org/cf-operator test-unit

cp src/code.cloudfoundry.org/cf-operator/code-coverage/gover-*.coverprofile code-coverage/