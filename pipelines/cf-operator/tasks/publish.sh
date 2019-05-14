#!/bin/bash
set -ex

# Start Docker Daemon (and set a trap to stop it once this script is done)
echo 'DOCKER_OPTS="--data-root /scratch/docker --max-concurrent-downloads 10"' >/etc/default/docker
service docker start
service docker status
trap 'service docker stop' EXIT
sleep 10

echo "$password" | docker login --username "$username" --password-stdin

# Determine version
VERSION_TAG=$(cat docker/tag)

echo "building for $VERSION_TAG"

CANDIDATE="$candidate_repository:$VERSION_TAG"
RELEASE="$repository:$VERSION_TAG"
docker pull "$CANDIDATE"
docker tag "$CANDIDATE" "$RELEASE"
docker push "$RELEASE"
