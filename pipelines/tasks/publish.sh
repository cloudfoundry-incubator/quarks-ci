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

echo "$password" | docker login --username "$username" --password-stdin

# Determine version
ARTIFACT_VERSION="$(cat docker/tag)"

echo "publishing $ARTIFACT_VERSION docker image"

CANDIDATE="$candidate_repository:$ARTIFACT_VERSION"
RELEASE="$repository:$ARTIFACT_VERSION"
docker pull "$CANDIDATE"
docker tag "$CANDIDATE" "$RELEASE"
docker push "$RELEASE"
