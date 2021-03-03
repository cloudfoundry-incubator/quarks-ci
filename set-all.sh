#!/bin/bash

target=${1-cfo}
vars=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" --notes)

fly:pipeline() {
  pipeline_dir="$1"
  pipeline_name="$2"

  pushd pipelines/"$pipeline_dir"
  fly --target "$target" set-pipeline \
    --pipeline="$pipeline_name" \
    --config=<(erb "pipeline.yml") \
    --load-vars-from=<(echo "$vars") \
    --load-vars-from="vars.yml"
  popd
}

fly:pipeline release-images-cf-deployment release-images-cf-deployment
fly:pipeline quarks-gora quarks-gora
fly:pipeline images quarks-images

# unsused?
# fly:pipeline release-images
