#!/usr/bin/env sh
set -eu

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on
export TEST_NAMESPACE="test$(date +%s)"

version=

if [ -f s3.build-number/version ]; then
  version=$(cat s3.build-number/version)
fi

export GOVER_FILE=gover-${version}-integration.coverprofile

# Random port to support parallelism with different webhook servers
export CF_OPERATOR_WEBHOOK_SERVICE_PORT=$(( ( RANDOM % 62000 )  + 2000 ))
export TUNNEL_NAME="tunnelpod-${CF_OPERATOR_WEBHOOK_SERVICE_PORT}"

## Make sure to cleanup the tunnel pod and service
cleanup () {
  echo "Cleaning up"
  set +e
  kubectl delete mutatingwebhookconfiguration "cf-operator-mutating-hook-${TEST_NAMESPACE}"
  kubectl delete ns --wait=false --grace-period=60 "${TEST_NAMESPACE}"
  pidof ssh | xargs kill
}
trap cleanup EXIT

echo "Seting up bluemix access"
ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"
eval $(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)

echo "Creating namespace"
kubectl create namespace "$TEST_NAMESPACE"

echo "Seting up SSH tunnel for webhook"
cat <<EOF > identity
$ssh_server_key
EOF
chmod 0600 identity

# GatewayPorts option needs to be enabled on ssh server
ssh -fNT -i identity -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -R "${ssh_server_ip}:${CF_OPERATOR_WEBHOOK_SERVICE_PORT}:localhost:${CF_OPERATOR_WEBHOOK_SERVICE_PORT}" "${ssh_server_user}@${ssh_server_ip}"

echo "Seting up webhook on k8s"
cat <<EOF | kubectl create -f - --namespace=${TEST_NAMESPACE}
---
kind: Endpoints
apiVersion: v1
metadata:
  name: ${TUNNEL_NAME}
subsets:
  - addresses:
      - ip: ${ssh_server_ip}
    ports:
      - port: ${CF_OPERATOR_WEBHOOK_SERVICE_PORT}
EOF
export CF_OPERATOR_WEBHOOK_SERVICE_HOST="$ssh_server_ip"


echo "Running integration tests"
make -C src/code.cloudfoundry.org/cf-operator test-integration

echo "Running e2e tests"
# fix SSL path
kube_path=$(dirname "$KUBECONFIG")
sed -i 's@certificate-authority: \(.*\)$@certificate-authority: '$kube_path'/\1@' $KUBECONFIG
make -C src/code.cloudfoundry.org/cf-operator test-e2e

find src/code.cloudfoundry.org/cf-operator/code-coverage -name gover-*.coverprofile | xargs -r cp -t code-coverage/
