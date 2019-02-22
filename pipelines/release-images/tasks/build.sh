#!/bin/bash
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

# Prepare stemcell
STEMCELL_NAME=${STEMCELL_REPOSITORY}:$(cat s3.stemcell-version/*-version)
docker pull ${STEMCELL_NAME}

s3.fissile-linux/fissile build release-images --stemcell=${STEMCELL_NAME} --name=${RELEASE_NAME} --version=${VERSION} --sha1=$(cat release/sha1) --url=$(cat release/url)

BUILT_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | egrep ^fissile)
docker tag ${BUILT_IMAGE} ${REGISTRY_NAMESPACE}/${BUILT_IMAGE}
docker push ${REGISTRY_NAMESPACE}/${BUILT_IMAGE}
