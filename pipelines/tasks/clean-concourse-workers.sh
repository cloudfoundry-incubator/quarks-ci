#!/bin/bash

set -eu

cd director/environments/softlayer/director
source .envrc

day_number=$(date +%u)
day_number=$((day_number - 1))

quarks_worker_number=(($day_number % 2))
worker_number=(($day_number % 5))

bosh -n -d concourse recreate worker-quarks/$quarks_worker_number
bosh -n -d concourse recreate worker/$worker_number
