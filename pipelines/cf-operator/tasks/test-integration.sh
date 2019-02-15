#!/usr/bin/env sh
set -eux

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on

ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"
eval $(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)

make -C src/code.cloudfoundry.org/cf-operator test-integration
