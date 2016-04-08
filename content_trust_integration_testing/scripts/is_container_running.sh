#!/bin/bash

container=$1
echo "CALLED WITH CONTAINER $container" >> /tmp/asdf
docker inspect --format={{.State.Status}} $container 2>/dev/null
