#!/bin/bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <CONCOURSE_TARGET> <PIPELINE_AND_BRANCH_NAME> <TAG_FILTER>"
  echo ""
  echo "Example: $0 cfo v0.4.x v0.4"
  exit 1
fi

target="$1"
branch="$2"
tag_filter="$3"
export branch tag_filter

pipeline_name="cfo-release-$branch"
fly --target "$target" set-pipeline \
  --pipeline="$pipeline_name" \
  --config=<(erb "pipeline.yml") \
  --load-vars-from="vars.yml" \
  --load-vars-from=<(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" --notes)
