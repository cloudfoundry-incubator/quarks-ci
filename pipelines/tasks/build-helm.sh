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
cp src/code.cloudfoundry.org/quarks-operator/helm/cf-operator*.tgz helm-charts/
