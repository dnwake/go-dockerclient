#!/bin/bash

container=$1
shift
logfile=$1
shift
other_args=$@
status="$(docker inspect --format={{.State.Status}} $container 2>/dev/null)"

rm -f $logfile

case "$status" in 
    running)
	echo "Container $container is already running"
	;;

    "")
	echo "Starting $container ..."
        docker run --name=$container $other_args 2>&1 > $logfile &
	sleep 1
	;;

    *)
        echo "Restarting $container"
	docker start $container 2>&1 > $logfile
	sleep 1
	;;
esac

if test "$(docker inspect --format={{.State.Running}} $container 2>/dev/null)" != true; then
  echo "Container $container failed to start: check $logfile for details"
  exit 1
fi
