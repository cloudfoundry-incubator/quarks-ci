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

docker pull ${STEMCELL}

VERSION=$(cat release/version)
STEMCELL_VERSION=${STEMCELL#*fissile-stemcell-}
STEMCELL_VERSION=${STEMCELL_VERSION/:/-}
FINAL_NAME=${REGISTRY_NAMESPACE}/${RELEASE_NAME}-release:${STEMCELL_VERSION}-${VERSION}

s3.fissile-linux/fissile build release-images --stemcell=${STEMCELL} --name=${RELEASE_NAME} --version=${VERSION} --sha1=$(cat release/sha1) --url=$(cat release/url)

BUILT_IMAGE_ID=$(docker images | egrep ^fissile | awk '{print $3}')
docker tag ${BUILT_IMAGE_ID} ${FINAL_NAME}
docker push ${FINAL_NAME}
