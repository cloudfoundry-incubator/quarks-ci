#!/bin/sh

target=${1-cfo}

fly -t "$target" expose-pipeline -p release-images-cf-deployment
# fly -t "$target" expose-pipeline -p release-images
