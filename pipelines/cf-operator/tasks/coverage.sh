#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD

version=

if [ -f s3.build-number/version ]; then
  version=$(cat s3.build-number/version)
fi

export BUILD_NUMBER=${version}

pushd src/code.cloudfoundry.org/quarks-operator
mkdir code-coverage
popd
cp s3.code-coverage*/*.coverprofile src/code.cloudfoundry.org/quarks-operator/code-coverage/
make -C src/code.cloudfoundry.org/quarks-operator coverage
