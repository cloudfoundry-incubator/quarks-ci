#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

pushd src/code.cloudfoundry.org/quarks-operator
. bin/include/versioning
popd

make -C src/code.cloudfoundry.org/quarks-operator build-helm
cp -p src/code.cloudfoundry.org/quarks-operator/helm/quarks*.tgz helm-charts/

SHA256=$(sha256sum src/code.cloudfoundry.org/quarks-operator/helm/quarks*.tgz | cut -f1 -d ' ' )
version=$(echo "$ARTIFACT_VERSION" | sed 's/^v//; s/-/+/')
echo $SHA256 > shas/$version
