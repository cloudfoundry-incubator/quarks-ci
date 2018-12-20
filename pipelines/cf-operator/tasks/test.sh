#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

cd src/code.cloudfoundry.org/cf-operator
make test-unit
