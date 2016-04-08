#!/bin/bash

container=$1
docker inspect --format={{.State.Status}} $container 2>/dev/null
