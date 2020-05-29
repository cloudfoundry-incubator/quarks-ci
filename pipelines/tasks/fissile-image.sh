#!/bin/bash

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -eux

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

# Prepare stemcell
STEMCELL_NAME="${STEMCELL_REPOSITORY}:$(cat s3.stemcell-version/*-version)"
docker pull "${STEMCELL_NAME}"

sha1=$(sha1sum release/*.tgz | awk '{print $1}')
s3.fissile-linux/fissile build release-images --stemcell="${STEMCELL_NAME}" --name="${RELEASE_NAME}" --version="${VERSION}" --sha1="$sha1" --url="$(cat release/url)"

BUILT_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "$STEMCELL_REPOSITORY" | head -1)
docker tag "${BUILT_IMAGE}" "${REGISTRY_NAMESPACE}/${BUILT_IMAGE}"
docker push "${REGISTRY_NAMESPACE}/${BUILT_IMAGE}"
