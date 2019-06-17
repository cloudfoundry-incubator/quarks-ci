#!/bin/bash

sleep 5

mkdir -p /tmp/drain_logs/
echo "delaying-drain-job/drain.sh ran" > /tmp/drain_logs/delaying-drain-job.log

# Demand a 5 second wait time before terminating the job
echo "5"
