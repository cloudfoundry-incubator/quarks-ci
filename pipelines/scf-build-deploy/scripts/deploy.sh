#!/bin/bash

set -euo pipefail

bx login -a "${BX_API}" --apikey "${BX_API_KEY}"
eval "$(bx cs cluster-config "${CLUSTER_NAME}" --export)"

mkdir -p charts && tar -xzf scf-helm-charts/scf-*-helm.tar.gz -C charts
cat <<'EOF' >armada-deploy.yml
---
name: armada
releases:
- chart_name: uaa
  chart_namespace: uaa
  chart_version: 0
  chart_location: charts/helm/uaa
  overrides:
    secrets:
      UAA_ADMIN_CLIENT_SECRET: MyUaaAdminClientSecret
    env:
      DOMAIN: (( shell bx cs cluster-get --cluster ${CLUSTER_NAME} --json | jq --raw-output .ingressHostname ))
    kube:
     external_ips:
     - (( shell dig +short $(bx cs cluster-get --cluster ${CLUSTER_NAME} --json | jq --raw-output .ingressHostname) ))
     storage_class:
       persistent: "ibmc-file-gold"

- chart_name: cf
  chart_namespace: cf
  chart_version: 0
  chart_location: charts/helm/cf
  overrides:
    secrets:
      CLUSTER_ADMIN_PASSWORD: changeme
      UAA_ADMIN_CLIENT_SECRET: MyUaaAdminClientSecret
      UAA_CA_CERT: (( shell kubectl --namespace uaa get pods --output json | jq --raw-output ".items[].spec.containers[] | select(.name == \"uaa\") | .env[] | select(.name == \"INTERNAL_CA_CERT\") | [ .valueFrom.secretKeyRef.name, .valueFrom.secretKeyRef.key ] | @tsv" | while read -r SECRET_NAME SECRET_KEY; do kubectl --namespace uaa get secret "${SECRET_NAME}" --output json | jq --raw-output ".data[\"${SECRET_KEY}\"]" | base64 -d; done ))
    env:
      DOMAIN: (( shell bx cs cluster-get --cluster ${CLUSTER_NAME} --json | jq --raw-output .ingressHostname ))
      TCP_DOMAIN: tcp.(( shell bx cs cluster-get --cluster ${CLUSTER_NAME} --json | jq --raw-output .ingressHostname ))
      UAA_HOST: uaa.(( shell bx cs cluster-get --cluster ${CLUSTER_NAME} --json | jq --raw-output .ingressHostname ))
      UAA_PORT: 2793
      INSECURE_DOCKER_REGISTRIES: "\"insecure-registry.(( shell bx cs cluster-get --cluster ${CLUSTER_NAME} --json | jq --raw-output .ingressHostname )):20005\""
    kube:
      external_ips:
      - 192.0.2.42
      - (( shell dig +short $(bx cs cluster-get --cluster ${CLUSTER_NAME} --json | jq --raw-output .ingressHostname) ))
      storage_class:
        persistent: "ibmc-file-gold"

EOF

havener purge --non-interactive uaa cf
havener deploy --config armada-deploy.yml

CF_NAMESPACE=cf
BASE_SECRET="$(kubectl --namespace "${CF_NAMESPACE}" get cm secrets-config --output json | jq --raw-output '.data["current-secrets-name"]')"
DOMAIN="$(bx cs cluster-get --cluster "${CLUSTER_NAME}" --json | jq --raw-output .ingressHostname)"
kubectl create secret generic --namespace "${CF_NAMESPACE}" router-secret \
  --from-file=tls.crt=<(kubectl --namespace "${CF_NAMESPACE}" get secret "${BASE_SECRET}" --output json | jq --raw-output '.data["router-ssl-cert"]' | base64 -d) \
  --from-file=tls.key=<(kubectl --namespace "${CF_NAMESPACE}" get secret "${BASE_SECRET}" --output json | jq --raw-output '.data["router-ssl-cert-key"]' | base64 -d)
kubectl --namespace "${CF_NAMESPACE}" apply --wait --filename - <<EOF
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    ingress.bluemix.net/client-max-body-size: 1536m
  name: router
  namespace: cf
spec:
  rules:
  - host: '*.${DOMAIN}'
    http:
      paths:
      - backend:
          serviceName: router-gorouter-public
          servicePort: 80
        path: /
  tls:
  - hosts:
    - '*.${DOMAIN}'
    secretName: router-secret
EOF
