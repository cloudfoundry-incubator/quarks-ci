#!/bin/bash

set -e

mkdir /bosh-cache

ROOT_DIR=$PWD

pushd ci/bosh-releases/$RELEASE_NAME

VERSION=$(cat VERSION)
echo "Will now generate version ${VERSION}"

RELEASE_TARBALL_BASE_NAME=${RELEASE_NAME}-release-${VERSION}.tgz
RELEASE_TARBALL=$ROOT_DIR/release_tarball_dir/${RELEASE_TARBALL_BASE_NAME}

/usr/local/bin/bosh.sh \
    "$(id -u)" "$(id -g)" /bosh-cache create-release \
    --final \
    --version=${VERSION} \
    --tarball=${RELEASE_TARBALL}
