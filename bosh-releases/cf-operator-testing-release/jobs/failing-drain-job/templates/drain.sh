#!/bin/bash

mkdir -p /tmp/drain_logs/
echo "failing-drain-job/drain.sh ran" > /tmp/drain_logs/failing-drain-job.log

exit 1
