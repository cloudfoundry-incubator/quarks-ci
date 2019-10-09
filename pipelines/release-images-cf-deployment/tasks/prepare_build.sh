#!/usr/bin/env bash

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -eux

manifest_releases=$(yq -r ".manifest_version as \$cf_version | .releases[] | .name" "${CF_DEPLOYMENT_YAML}" | sort)
failed=false

# Find releases which are not covered by the pipeline yet
new_releases=$(comm -23 <(echo $manifest_releases | tr " " "\n") <(echo $RELEASES | tr " " "\n") | tr -d '[:space:]')
if [ -z "$new_releases" ]; then
  echo "There are new release which are not covered by the pipeline yet: $new_releases"
  failed=true
fi

# Find releases which are no longer part of cf-deployment
obsolete_releases=$(comm -13 <(echo $manifest_releases | tr " " "\n") <(echo $RELEASES | tr " " "\n") | tr -d '[:space:]')

if [ -z "$obsolete_releases" ]; then
  echo "There are releases which are no longer part of cf-deployment: $obsolete_releases"
  failed=true
fi

if [ "$failed" = true ]; then
  exit 1
fi
