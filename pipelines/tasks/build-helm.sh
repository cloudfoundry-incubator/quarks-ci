#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

pushd src/code.cloudfoundry.org/quarks-operator
  bin/tools
  bin/build-helm
popd

cp src/code.cloudfoundry.org/quarks-operator/helm/quarks*.tgz helm-charts/
