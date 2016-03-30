#!/bin/bash
THIS_DIR="$(cd "$(dirname "$0")"; pwd)"
OUTPUT_FILE=${TMPDIR}/test_output

### old command that just uses the docker cmdline
get_commands_to_pull_and_run_docker_image_old() {
    echo " \
        docker pull ${REGISTRY_URL}/${image_name}:latest && \
        docker run --rm ${REGISTRY_URL}/${image_name}:latest \
    "
}

get_commands_to_pull_and_run_docker_image() {
    echo " \
        export GOPATH=/root/go && \
        go run /root/go/src/main/invoke_pull.go registry-server:5000/${image_name}:latest && \
        docker run --rm ${REGISTRY_URL}/${image_name}:latest \
    "
}


### Attempts to pull the specified image from the registry
### Then runs it and compares the results to what is expected
run_test() {
    if test "${CORRUPT_IMAGE}" == true; then
        export image_name=${CORRUPT_GOOD_IMAGE_NAME};
    else
	export image_name=${GOOD_IMAGE_NAME};
    fi;

    (
        ### Return a test failure even though we are piping to tee
        set -o pipefail
        docker exec ${CLIENT_CONTAINER_NAME} bash -c " \
            if test ${TRUST} == true; then \
                export DOCKER_CONTENT_TRUST=1; \
                export DOCKER_CONTENT_TRUST_SERVER=${NOTARY_URL}; \
            else \
                unset DOCKER_CONTENT_TRUST; \
    	    unset DOCKER_CONTENT_TRUST_SERVER; \
    	fi; \
            docker rmi -f ${REGISTRY_URL}/${image_name}:latest >/dev/null 2>&1; \
            $(get_commands_to_pull_and_run_docker_image) \
        " 2>&1 | tee $OUTPUT_FILE
    )
        
    exit_value=$?

    actual="$(tail -n 1 $OUTPUT_FILE)"

    if test "$EXPECTED_RESULT" == "fail"; then
        if test "$exit_value" != 0; then
            echo 'Test succeeded'
	    echo
        else
            echo 'Test failed: expected failure but succeeded'
	    echo
            exit 1
        fi
    fi

    if test -n "$EXPECTED_OUTPUT"; then
        if test "${EXPECTED_OUTPUT}" == "${actual}"; then
            echo 'Test succeeded'
            echo
        else
            echo -n "Test failed: expected '$(echo ${EXPECTED})' but found '${actual}'"
            echo 
            exit 1
        fi
    fi

    exit 0
}

run_test
