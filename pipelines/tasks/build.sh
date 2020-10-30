#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

export BASE="$PWD"

cd src/code.cloudfoundry.org/quarks-operator

bin/tools
. bin/include/versioning

ARTIFACT_VERSION=$( echo "$ARTIFACT_VERSION" | sed 's/-dirty//' )

bin/build

echo "$ARTIFACT_VERSION" > "$BASE"/docker/tag

echo "Built quarks-operator binary for $ARTIFACT_VERSION and set docker tag."
