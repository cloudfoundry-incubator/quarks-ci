#!/bin/bash

set -euo pipefail

bx login -a "${BX_API}" --apikey "${BX_API_KEY}"
eval "$(bx cs cluster-config "${CLUSTER_NAME}" --export)"

tar -xzf scf-helm-charts/scf-*-helm.tar.gz

DOMAIN="$(bx cs cluster-get --cluster "${CLUSTER_NAME}" --json | jq --raw-output .ingressHostname)"
perl -pi -e "s/cf-dev.io/${DOMAIN}/" kube/cf/bosh-task/acceptance-tests.yaml

# TODO Verify how much we can scale the tests
perl -pi -e 's/value: "4"/value: "2"/' kube/cf/bosh-task/acceptance-tests.yaml

if kubectl --namespace=cf get pod acceptance-tests >/dev/null 2>&1; then
  kubectl delete \
    --namespace=cf \
    --wait \
    pod/acceptance-tests
fi

kubectl create \
  --namespace=cf \
  --filename="kube/cf/bosh-task/acceptance-tests.yaml"

sleep 10

kubectl logs \
  --namespace=cf \
  --follow \
  acceptance-tests

EXIT_CODE=0

if [[ "$(kubectl --namespace=cf get pod acceptance-tests --output json | jq --raw-output '.status.phase')" == "Failed" ]]; then
  echo "CATs failed"
  EXIT_CODE=1
fi

if kubectl --namespace=cf get pod acceptance-tests >/dev/null 2>&1; then
  kubectl delete \
    --namespace=cf \
    --wait \
    pod/acceptance-tests
fi

exit ${EXIT_CODE}
