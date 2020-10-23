#!/bin/bash

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -ex

# Start Docker Daemon (and set a trap to stop it once this script is done)
echo 'DOCKER_OPTS="--data-root /scratch/docker --max-concurrent-downloads 10"' >/etc/default/docker
service docker start
service docker status
trap 'service docker stop' EXIT
sleep 10

echo "${DOCKER_TEAM_PASSWORD_RW}" | docker login --username "${DOCKER_TEAM_USERNAME}" --password-stdin

pushd s3.fissile-linux
tar xfv fissile-*.tgz
popd

VERSION=$(cat release/version)
URL=$(cat release/url)

# Prepare stemcell
STEMCELL_NAME="${STEMCELL_REPOSITORY}:$(cat s3.stemcell-version/*-version)"
docker pull "${STEMCELL_NAME}"

if [ ! -e release/sha1 ]; then
  # Calculate sha1sum if the resource is a file from s3. bosh.io resources provide the checksum automatically
  SHA1=$(sha1sum release/*gz | cut -f1 -d ' ' )
else
  SHA1=$(cat release/sha1)
fi

# Download source tarball so that it can be stored later on
curl -L -o "s3.kubecf-sources/${RELEASE_NAME}-${VERSION}.tgz" "${URL}"

s3.fissile-linux/fissile build release-images --stemcell="${STEMCELL_NAME}" --name="${RELEASE_NAME}" --version="${VERSION}" --sha1="$SHA1" --url="${URL}"

echo "Push to docker.io"
BUILT_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "$STEMCELL_REPOSITORY" | head -1)
echo docker tag "${BUILT_IMAGE}" "${REGISTRY_NAMESPACE}/${BUILT_IMAGE}"
docker tag "${BUILT_IMAGE}" "${REGISTRY_NAMESPACE}/${BUILT_IMAGE}"
docker push "${REGISTRY_NAMESPACE}/${BUILT_IMAGE}"

echo "Push to ghcr.io"
echo "$GHCR_PASSWORD" | docker login ghcr.io --username "$GHCR_USERNAME" --password-stdin
echo docker tag "$BUILT_IMAGE" "$GHCR_ORGANIZATION/$BUILT_IMAGE"
docker tag "$BUILT_IMAGE" "$GHCR_ORGANIZATION/$BUILT_IMAGE"
docker push "$GHCR_ORGANIZATION/$BUILT_IMAGE"
