#!/usr/bin/env sh
set -eu

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on
export TEST_NAMESPACE="test$(date +%s)"

## Make sure to cleanup the tunnel pod and service
cleanup () {
  echo "Cleaning up"
  kubectl delete mutatingwebhookconfiguration cf-operator-mutating-hook-${TEST_NAMESPACE}
  kubectl delete ns ${TEST_NAMESPACE}
}
trap cleanup EXIT

echo "Seting up bluemix access"
ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"
eval $(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)

echo "Seting up bluemix access"
kubectl create namespace "$TEST_NAMESPACE"

echo "Running integration tests"
make -C src/code.cloudfoundry.org/cf-operator test-integration
