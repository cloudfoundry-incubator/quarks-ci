#!/bin/bash

target=${1-cfo}
vars=$(lpass show "Shared-CF-Containerization/ContainerizedCF-CI-Secrets" --notes)

fly:pipeline() {
  pipeline_name="$1"

  pushd pipelines/"$pipeline_name"
  fly --target "$target" set-pipeline \
    --pipeline="$pipeline_name" \
    --config=<(erb "pipeline.yml") \
    --load-vars-from=<(echo "$vars") \
    --load-vars-from="vars.yml"
  popd
}

fly:pipeline cf-operator
fly:pipeline cf-operator-check
fly:pipeline cf-operator-nightly
fly:pipeline cf-operator-testing-image
fly:pipeline release-images
fly:pipeline release-images-cf-deployment
fly:pipeline quarks-gora
fly:pipeline images

pushd pipelines/cf-operator-release
  ./configure.sh "$target" v4.0.x v4.
  ./configure.sh "$target" v5.0.x v5.
  ./configure.sh "$target" v6.x v6.
popd
