#!/usr/bin/env bash

trap 'ls -l /tmp/drain_logs; exit 0' TERM
while true; do sleep 5; done
