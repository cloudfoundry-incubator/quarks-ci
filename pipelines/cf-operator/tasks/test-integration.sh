#!/usr/bin/env sh
set -eu

export PATH=$PATH:$PWD/bin
export GOPATH=$PWD
export GO111MODULE=on
export OPERATOR_WEBHOOK_PORT=$(( ( RANDOM % 62000 )  + 2000 ))
export TUNNEL_NAME="tunnelpod-${OPERATOR_WEBHOOK_PORT}"

TEST_NAMESPACE="test$(date +%s)"
export TEST_NAMESPACE


# Make sure to cleanup the tunnel pod and service
cleanup () {
  kubectl delete deployment ${TUNNEL_NAME} --namespace=${TEST_NAMESPACE}
  kubectl delete service ${TUNNEL_NAME} --namespace=${TEST_NAMESPACE}
}
trap cleanup EXIT

ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"
eval $(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)

# Create temporary namespace
kubectl create namespace "$TEST_NAMESPACE"

# Deploy reverse tunnel pod
cat <<EOF | kubectl create -f - --namespace=${TEST_NAMESPACE}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: ${TUNNEL_NAME}
spec:
  selector:
    matchLabels:
      run: ${TUNNEL_NAME}
  template:
    metadata:
      labels:
        run: ${TUNNEL_NAME}
    spec:
      containers:
      - name: sshd
        image: cfcontainerization/ci-tunnel
        ports:
        - containerPort: 22
        - containerPort: ${OPERATOR_WEBHOOK_PORT}
---
apiVersion: v1
kind: Service
metadata:
  name: ${TUNNEL_NAME}
  labels:
    run: ${TUNNEL_NAME}
spec:
  type: LoadBalancer
  ports:
  - port: ${OPERATOR_WEBHOOK_PORT}
    protocol: TCP
    name: http
  - port: 22
    protocol: TCP
    name: ssh
  selector:
    run: ${TUNNEL_NAME}
EOF

cat <<EOF > identity
${sshtunnel_key}
EOF
chmod 0600 identity

# Wait for pod to be running
while ! (kubectl get pods --namespace ${TEST_NAMESPACE} | grep Running); do
  sleep 5
  echo "Waiting for pod.."
done

# Wait for service/load balancer to be ready
external_ip=""
while [ -z ${external_ip} ]; do
  external_ip=$(kubectl get svc ${TUNNEL_NAME} --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}" --namespace=${TEST_NAMESPACE})
  [ -z "${external_ip}" ] && (echo "Waiting for end point..."; sleep 5)
done
echo "End point: ${external_ip}"

# Set up SSH tunnel which makes the local webhook server available in the kubernetes cluster
ssh -fNT -i identity -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -R ${external_ip}:${OPERATOR_WEBHOOK_PORT}:localhost:${OPERATOR_WEBHOOK_PORT} $external_ip

make -C src/code.cloudfoundry.org/cf-operator test-integration
