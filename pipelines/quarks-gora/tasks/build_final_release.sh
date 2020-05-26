#!/bin/bash

exec 3> `basename "$0"`.trace

BASH_XTRACEFD=3

set -eux

mkdir /bosh-cache

ROOT_DIR=$PWD

WORKDIR=git_output
# Prepare the git repository for the "put" task
git clone --recurse-submodules "gora" git_output

pushd git_output

OLD_VERSION=$(git describe --tags --abbrev=0)
VERSION="$(echo $OLD_VERSION | sed -e 's/\(.*\)\.[0-9]\+/\1/').$(($(echo $OLD_VERSION | rev | cut -d. -f1 | rev)+1))"

echo "Old version is ${OLD_VERSION}"
echo "Will now generate version ${VERSION}"

echo $VERSION > $ROOT_DIR/release_tarball_dir/VERSION

cat << EOF > config/private.yml
---
blobstore:
  options:
    access_key_id: "${ACCESS_KEY_ID}"
    secret_access_key: "${SECRET_ACCESS_KEY}"

EOF

RELEASE_TARBALL_BASE_NAME=${RELEASE_NAME}-release-${VERSION}.tgz
RELEASE_TARBALL=$ROOT_DIR/release_tarball_dir/${RELEASE_TARBALL_BASE_NAME}

/usr/local/bin/bosh.sh \
    "$(id -u)" "$(id -g)" /bosh-cache create-release \
    --final \
    --version="${VERSION}" \
    --tarball="${RELEASE_TARBALL}"

SHA256SUM=$(sha256sum ${RELEASE_TARBALL} | cut -d' ' -f1)

# GitHub release body text (will be used from the pipeline to push the GitHub release)
# NOTE: Don't change the text unless you also change the crate-pr.sh task because this is parsed to extract the url and sha.
cat << EOF > $ROOT_DIR/release_tarball_dir/release_body
Release Tarball: https://s3.amazonaws.com/cf-operators/${RELEASE_TARBALL_BASE_NAME}
\`sha256:${SHA256SUM}\`
EOF

git add .
git config --global user.name "CFContainerizationBot"
git config --global user.email "cf-containerization@cloudfoundry.org"

git commit -m "Add version $VERSION"
echo "master" > $ROOT_DIR/release_tarball_dir/target_commit