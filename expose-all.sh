#!/bin/sh

target=${1-cfo}

fly -t "$target" expose-pipeline -p cf-operator-check
fly -t "$target" expose-pipeline -p cf-operator-nightly
fly -t "$target" expose-pipeline -p cf-operator
fly -t "$target" expose-pipeline -p release-images
