#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD

pushd src/code.cloudfoundry.org/cf-operator
. bin/include/versioning
popd

set -ex
make -C src/code.cloudfoundry.org/cf-operator build
cp -r src/code.cloudfoundry.org/cf-operator/build docker/
echo $VERSION_TAG > docker/tag
