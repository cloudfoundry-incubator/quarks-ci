#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

pushd src/code.cloudfoundry.org/cf-operator
git describe --tags --long || git tag v0.0.0 # Make sure there's always a tag that can be used for building the version
. bin/include/versioning
popd

set -ex
make -C src/code.cloudfoundry.org/cf-operator build
echo $VERSION_TAG > docker/tag
