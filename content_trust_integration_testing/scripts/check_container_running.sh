#!/bin/bash

container=$1
logfile=$2

if test "$(docker inspect --format={{.State.Running}} $container 2>/dev/null)" != true; then
  echo "Container $container failed to start: check $logfile for details"
  exit 1;
fi

