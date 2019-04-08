#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

cp s3.code-coverage/*.coverprofile src/code.cloudfoundry.org/cf-operator
sed -i 's/mode: atomic// ; 1s/^/mode: atomic\n/' src/code.cloudfoundry.org/cf-operator/*.coverprofile

make -C src/code.cloudfoundry.org/cf-operator coverage