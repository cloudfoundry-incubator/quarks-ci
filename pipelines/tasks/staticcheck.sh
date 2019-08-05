#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD

staticcheck code.cloudfoundry.org/cf-operator/...
