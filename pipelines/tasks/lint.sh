#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD

make -C src/code.cloudfoundry.org/cf-operator lint
