#!/usr/bin/env sh
set -eu

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on
export OPERATOR_WEBHOOK_PORT=443
export TEST_NAMESPACE="test$(date +%s)"
export TUNNEL_NAME="tunnel-${OPERATOR_WEBHOOK_PORT}"

# Start ngrok tunnel
ngrok authtoken ${ngrok_token}
ngrok tcp ${OPERATOR_WEBHOOK_PORT} > /dev/null &

## Make sure to cleanup the tunnel pod and service
cleanup () {
  kill $(pgrep ngrok)
  kubectl delete mutatingwebhookconfiguration cf-operator-mutating-hook-${TEST_NAMESPACE}
  kubectl delete ns ${TEST_NAMESPACE}
}
trap cleanup EXIT

# Setup bluemix access
ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"
eval $(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)

# Create temporary namespace
kubectl create namespace "$TEST_NAMESPACE"

NGROK_HOST=""
while [ -z ${NGROK_HOST} ]; do
  NGROK_HOST=$(curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*):.*/\1/p')
  NGROK_PORT=$(curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..[^"]*:([^"]*).*/\1/p')
  [ -z "${NGROK_HOST}" ] && (echo "Waiting for end point..."; sleep 5)
done
export NGROK_IP=$(host ${NGROK_HOST} | awk '/has address/ { print $4 }')
echo "End point: ${NGROK_HOST}:${NGROK_PORT}"

cat <<EOF | kubectl create -f - --namespace=${TEST_NAMESPACE}
apiVersion: v1
kind: Service
metadata:
  name: ${TUNNEL_NAME}
  labels:
    run: ${TUNNEL_NAME}
spec:
  ports:
  - port: ${OPERATOR_WEBHOOK_PORT}
    targetPort: ${NGROK_PORT}
    protocol: TCP
---
kind: Endpoints
apiVersion: v1
metadata:
  name: ${TUNNEL_NAME}
subsets:
  - addresses:
      - ip: ${NGROK_IP}
    ports:
      - port: ${NGROK_PORT}
EOF

export OPERATOR_WEBHOOK_HOST=$(kubectl get service -n "$TEST_NAMESPACE" webhook -o json | jq -r .spec.clusterIP)
make -C src/code.cloudfoundry.org/cf-operator test-integration
