#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

pushd src/code.cloudfoundry.org/cf-operator
git describe --tags --long || git tag v0.0.0 # Make sure there's always a tag that can be used for building the version
. bin/include/versioning
popd

# for backwards-compatibility
ARTIFACT_VERSION=${ARTIFACT_VERSION:-$VERSION_TAG}

make -C src/code.cloudfoundry.org/cf-operator build
cp src/code.cloudfoundry.org/cf-operator/binaries/cf-operator binaries/cf-operator-$ARTIFACT_VERSION
echo $ARTIFACT_VERSION > docker/tag
