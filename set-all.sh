#!/bin/bash

target=${1-suse}
vars=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" --notes)

fly:pipeline() {
  pipeline_dir="$1"
  pipeline_name="$2"

  echo "flying '$2' - press any key"
  echo

  pushd pipelines/"$pipeline_dir"
  fly --target "$target" set-pipeline \
    --pipeline="$pipeline_name" \
    --config=<(erb "pipeline.yml") \
    --load-vars-from=<(echo "$vars") \
    --load-vars-from="vars.yml"
  popd
}

fly:pipeline quarks-gora quarks-gora
fly:pipeline images quarks-images
#fly:pipeline release-images release-images

#for v in v12.36.0 v13.9.0 v13.17.0 v15.1.0 v16.3.0; do
#for v in v15.1.0 v16.3.0; do
for v in  v16.15.0; do
  export CF_VERSION="$v"
  fly:pipeline release-images-cf-deployment release-images-"$v"
done
