#!/usr/bin/env sh

exec 3> `basename "$0"`.trace
BASH_XTRACEFD=3

set -eux

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

echo "--------------------------------------------------------------------------------"
echo "Running integration tests"
make -C src/code.cloudfoundry.org/cf-operator test-integration

echo "--------------------------------------------------------------------------------"
echo "Running integration storage tests"
make -C src/code.cloudfoundry.org/cf-operator test-integration-storage

if [ "${COVERAGE+ok}" = ok ] && [ -f s3.build-number/version ]; then
  version=$(cat s3.build-number/version)
  gover_file=gover-${version}-integration.coverprofile
  # add missing newlines to work around gover bug: https://github.com/sozorogami/gover/issues/9
  find src/code.cloudfoundry.org/cf-operator/code-coverage -type f | while read -r f; do echo >> "$f"; done
  gover src/code.cloudfoundry.org/cf-operator/code-coverage code-coverage/"$gover_file"
fi

echo "--------------------------------------------------------------------------------"
echo "Running e2e CLI tests"
# fix relative SSL path in KUBECONFIG
kube_path=$(dirname "$KUBECONFIG")
sed -i 's@certificate-authority: \(.*\)$@certificate-authority: '$kube_path'/\1@' "$KUBECONFIG"
make -C src/code.cloudfoundry.org/cf-operator test-cli-e2e
