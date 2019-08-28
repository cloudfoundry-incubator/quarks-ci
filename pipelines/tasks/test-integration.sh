#!/usr/bin/env sh
set -eu

: "${ibmcloud_apikey:?}"
: "${ibmcloud_server:?}"
: "${ibmcloud_region:?}"
: "${ibmcloud_cluster:?}"
: "${ssh_server_ip:?}"
: "${ssh_server_user:?}"
: "${ssh_server_key:?}"
: "${OPERATOR_TEST_STORAGE_CLASS:?}"
: "${DOCKER_IMAGE_REPOSITORY:?}"

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on
export TEST_NAMESPACE="test$(date +%s)"

## File used for coverage reporting
version=
if [ -f s3.build-number/version ]; then
  version=$(cat s3.build-number/version)
fi
export GOVER_FILE=gover-${version}-integration.coverprofile

upload_debug_info() {
  if ls /tmp/env_dumps/* &> /dev/null; then
    TARBALL_NAME="env_dump-$(date +"%s").tar.gz"
    echo "Env dumps will be uploaded as ${TARBALL_NAME}"
    tar cfzv env_dumps/${TARBALL_NAME} -C /tmp/env_dumps/ .
  fi
}

## Make sure to cleanup the tunnel pod and service
cleanup () {
  upload_debug_info

  echo "Cleaning up"
  set +e
  kubectl get mutatingwebhookconfiguration -oname | \
    grep "$TEST_NAMESPACE" | \
    xargs -r -n 10 kubectl delete
  kubectl get validatingwebhookconfiguration -oname | \
    grep "$TEST_NAMESPACE" | \
    xargs -r -n 10 kubectl delete
  pidof ssh | xargs kill
}

trap cleanup EXIT

echo "Setting up bluemix access"
ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"
export BLUEMIX_CS_TIMEOUT=500
eval $(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)
echo "Running integration tests in the ${ibmcloud_cluster} cluster."

## Set up SSH tunnels to make our webhook server available to k8s
echo "Setting up SSH tunnel for webhook"
cat <<EOF > /tmp/cf-operator-tunnel-identity
$ssh_server_key
EOF
chmod 0600 /tmp/cf-operator-tunnel-identity

# Random base port to support parallelism with different webhook servers
export CF_OPERATOR_WEBHOOK_SERVICE_PORT=$(( ( RANDOM % 59000 )  + 4000 ))
export CF_OPERATOR_WEBHOOK_SERVICE_HOST="$ssh_server_ip"
export NODES=${NODES:-5}

echo "Setting up webhooks and namespaces on k8s"
for i in $(seq 1 "$NODES"); do
  port=$(( CF_OPERATOR_WEBHOOK_SERVICE_PORT + i ))
  namespace="${TEST_NAMESPACE}-${i}"
  tunnel_name="tunnel-$port"
  kubectl create namespace "$namespace"

  # GatewayPorts option needs to be enabled on ssh server
  ssh -fNT -i /tmp/cf-operator-tunnel-identity -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -R "$ssh_server_ip:$port:localhost:$port" "$ssh_server_user@$ssh_server_ip"

  cat <<EOF | kubectl create -f- --namespace="$namespace"
---
kind: Endpoints
apiVersion: v1
metadata:
  name: $tunnel_name
subsets:
  - addresses:
      - ip: $ssh_server_ip
    ports:
      - port: $port
EOF
done

echo "--------------------------------------------------------------------------------"
echo "Running integration tests"
make -C src/code.cloudfoundry.org/cf-operator test-integration

echo "--------------------------------------------------------------------------------"
echo "Running integration storage tests"
make -C src/code.cloudfoundry.org/cf-operator test-integration-storage

find src/code.cloudfoundry.org/cf-operator/code-coverage -name "gover-*.coverprofile" -print0 | xargs -0 -r cp -t code-coverage/

echo "--------------------------------------------------------------------------------"
echo "Running e2e CLI tests"
# fix relative SSL path in KUBECONFIG
kube_path=$(dirname "$KUBECONFIG")
sed -i 's@certificate-authority: \(.*\)$@certificate-authority: '$kube_path'/\1@' "$KUBECONFIG"
make -C src/code.cloudfoundry.org/cf-operator test-cli-e2e
