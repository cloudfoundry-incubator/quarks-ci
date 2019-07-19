#!/usr/bin/env bash

set -o errexit -o nounset

GREEN='\033[0;32m'
NC='\033[0m'

function build_release() {
  cf_version="${1}"
  docker_registry="${2}"
  docker_organization="${3}"
  docker_username="${4}"
  docker_password="${5}"
  stemcell_os="${6}"
  stemcell_version="${7}"
  stemcell_image="${8}"
  release_name="${9}"
  release_url="${10}"
  release_version="${11}"
  release_sha1="${12}"

  stemcell_name="${stemcell_os}-${stemcell_version}"

  echo -e "Building image:"
  echo -e "  - Release name:    ${GREEN}${release_name}${NC}"
  echo -e "  - Release version: ${GREEN}${release_version}${NC}"
  echo -e "  - Release URL:     ${GREEN}${release_url}${NC}"
  echo -e "  - Release SHA1:    ${GREEN}${release_sha1}${NC}"
  echo -e "  - CF version:      ${GREEN}${cf_version}${NC}"
  echo -e "  - Stemcell:        ${GREEN}${stemcell_name}${NC}"

  # Build the release image.
  fissile build release-images \
    --stemcell="${stemcell_image}" \
    --name="${release_name}" \
    --version="${release_version}" \
    --sha1="${release_sha1}" \
    --url="${release_url}" \
    --docker-registry="${docker_registry}" \
    --docker-organization="${docker_organization}"

  # Check if there is an image already pushed for the release being built, otherwise push.
  built_image_filter=$(docker images --format "{{.Repository}} {{.Tag}}" | grep "${release_name}.*${stemcell_name}.*${release_version}" | head -1)
  built_image_repository=$(echo "${built_image_filter}" | awk '{ printf $1 }')
  built_image_tag=$(echo "${built_image_filter}" | awk '{ printf $2 }')
  built_image="${built_image_repository}:${built_image_tag}"
  echo -e "Built image: ${GREEN}${built_image}${NC}"
  docker_creds_string=""${docker_username}":"${docker_password}""
  if curl --silent -u "${docker_creds_string}" "https://"${docker_registry}"/v2/"${docker_organization}"/"${release_name}"/manifests/"${built_image_tag}"" | jq '.errors[0].code' | grep -q null; then
    echo -e "Skipping push for ${GREEN}${built_image}${NC} as it is already present in the registry..."
  else
    docker push "${built_image}"
  fi
  docker rmi "${built_image}"

  echo '----------------------------------------------------------------------------------------------------'
}
