#!/usr/bin/env sh

set -euo pipefail

echo "Setting up bluemix access"
ibmcloud logout
ibmcloud login -a "$ibmcloud_server" --apikey "$ibmcloud_apikey"
ibmcloud cs  region-set "$ibmcloud_region"

echo "Running in cluster: $ibmcloud_cluster"

export BLUEMIX_CS_TIMEOUT=500

eval "$(ibmcloud cs cluster-config "$ibmcloud_cluster" --export)"

OLD_DATE=$(date -d '4 hour ago' "+%s")
export OLD_DATE

delete_old() {
  res="$1"

  list=$(kubectl get "$res" --no-headers -o json | jq -r '
    .items[] |
    select(.metadata.creationTimestamp | fromdateiso8601 < ( env.OLD_DATE | tonumber ) ) |
    select(.metadata.name | contains("test")) | .metadata.name
  ')

  if [ -z "$list" ]; then
    echo "Currently no $res, older than 4 hours. Nothing to delete"
  else
    echo $list | xargs -r -n 50 kubectl delete --wait=false --timeout=60s $res
  fi
}

set +eo pipefail
delete_old namespace
delete_old validatingwebhookconfigurations
delete_old mutatingwebhookconfigurations

export LC_TIME=C
export LC_DATE=C
CURRENT_DATE="$(date '+%a %b %d')"
helm list | grep cf-operator | grep -v "$CURRENT_DATE" | tail -n +2 | awk '{print $1}' | xargs -r -n 1 helm delete --purge

if ! hash havener 2>/dev/null; then
  echo "[Error] havener binary is not installed."
  exit 1
fi

NODES_TO_NUKE=$(kubectl get nodes | grep -v NAME | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')

echo "Cleaning images in the following nodes: ${NODES_TO_NUKE}"

havener node-exec --no-tty "$NODES_TO_NUKE" -- \
  sh -c "crictl images | grep cf-operator | awk '{print \$3}' | xargs -r -n 1 crictl rmi 2> /dev/null"

exit 0
