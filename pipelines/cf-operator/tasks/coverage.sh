#!/usr/bin/env sh
set -ex

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD

version=

if [ -f s3.build-number/version ]; then
  version=$(cat s3.build-number/version)
fi

export BUILD_NUMBER=${version}


cp s3.code-coverage*/*.coverprofile src/code.cloudfoundry.org/cf-operator
sed -i 's/mode: atomic// ; 1s/^/mode: atomic/' src/code.cloudfoundry.org/cf-operator/*.coverprofile

make -C src/code.cloudfoundry.org/cf-operator coverage
