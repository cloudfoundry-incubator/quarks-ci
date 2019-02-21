#!/usr/bin/env sh
set -ev

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

cd src/code.cloudfoundry.org/cf-operator
go version
# warm up cache
go mod download -json
