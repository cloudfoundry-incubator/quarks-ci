#!/bin/bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <CONCOURSE_TARGET> <RELEASE_VERSION>"
  echo ""
  echo "Example: $0 cfo 0.4.0"
  exit 1
fi

target="$1"
version="$2"
export version
pipeline_name="cfo-release-$version"

fly -t "$target" login -k
fly --target "$target" set-pipeline \
  --pipeline="$pipeline_name" \
  --config=<(erb "pipeline.yml") \
  --load-vars-from="vars.yml" \
  --load-vars-from=<(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" --notes)
