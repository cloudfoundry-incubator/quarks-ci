#!/usr/bin/env sh

set -euo pipefail

echo "Seting up bluemix access"
ibmcloud logout
ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"

echo "Running in cluster: ${ibmcloud_cluster}"

export BLUEMIX_CS_TIMEOUT=500

eval $(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)

CURRENT_DATE=$(date '+%Y-%m-%d')
export CURRENT_DATE
NS_LIST=$(kubectl get ns --no-headers -o json | jq -r '.items[] | select(.metadata.creationTimestamp | tostring | contains(env.CURRENT_DATE) | not) | select(.metadata.name | contains("test")) | .metadata.name')
export NS_LIST

if [ -z "${NS_LIST}" ]; then
  echo "Currently no namespaces, older than 1 day. Nothing to delete"
else
  for DELETE_NS in ${NS_LIST}; do 
      echo "Going to patch ests, bdpl and ejob resources in the namespace: ${DELETE_NS}"
      eval "$(kubectl -n "${DELETE_NS}" get ests --no-headers | awk '{print "kubectl patch ests -n ${DELETE_NS} " $1 " --patch '\''{\"metadata\": { \"finalizers\": null }}'\'' --type merge"}')"
      eval "$(kubectl -n "${DELETE_NS}" get bdpl --no-headers | awk '{print "kubectl patch bdpl -n ${DELETE_NS} " $1 " --patch '\''{\"metadata\": { \"finalizers\": null }}'\'' --type merge"}')"
      eval "$(kubectl -n "${DELETE_NS}" get ejob --no-headers | awk '{print "kubectl patch ejob -n ${DELETE_NS} " $1 " --patch '\''{\"metadata\": { \"finalizers\": null }}'\'' --type merge"}')"

      echo "Going to delete namespace: ${DELETE_NS}"
      kubectl delete ns "${DELETE_NS}" --timeout=60s --force --grace-period=0
      echo ""
  done
fi

