### Build and run a Notary server, consisting of three Docker containers
### Adapted from https://docs.docker.com/engine/security/trust/trust_sandbox/
NOTARY_REPO_DIR=$(TMPDIR)/notary_repo
NOTARY_STARTUP_LOG=$(TMPDIR)/notary_startup_log

## These values are hardcoded in docker compose files and cannot be changed easily
export NOTARY_IMAGE_1=notary_notaryserver
export NOTARY_IMAGE_2=notary_notarysigner
export NOTARY_IMAGE_3=notary_notarymysql
export NOTARY_CONTAINER_NAME_1=notary_notaryserver_1
export NOTARY_CONTAINER_NAME_2=notary_notarysigner_1
export NOTARY_CONTAINER_NAME_3=notary_notarymysql_1
export NOTARY_PORT=4443
export NOTARY_VOLUME_NAME=notary_data

## This value is hardcoded in the server's X509 cert
export NOTARY_HOST=notary-server

export NOTARY_URL=https://$(NOTARY_HOST):$(NOTARY_PORT)
export NOTARY_IMAGE=$(IMAGEDIR)/$(NOTARY_IMAGE_1)
export NOTARY_CONTAINER=$(CONTAINERDIR)/$(NOTARY_CONTAINER_NAME_1)

CHECK_CONTAINER_RUNNING := $(SCRIPTDIR)/check_container_running.sh
GET_CONTAINER_STATUS    := $(SCRIPTDIR)/get_container_status.sh

notary: $(NOTARY_IMAGE) $(NOTARY_REPO_DIR)/notary etc_hosts
ifeq ($(shell $(GET_CONTAINER_STATUS) $(NOTARY_CONTAINER_NAME_1)),running)
	echo "Notary already running..."
else
	echo "Starting notary..."
	cd $(NOTARY_REPO_DIR)/notary && docker-compose up -d > $(NOTARY_STARTUP_LOG) 2>&1
	sleep 1
	$(CHECK_CONTAINER_RUNNING) $(NOTARY_CONTAINER_NAME_1) $(NOTARY_STARTUP_LOG)
endif

notary_image: $(NOTARY_IMAGE)

$(NOTARY_IMAGE): $(NOTARY_REPO_DIR)/notary
	cd $(NOTARY_REPO_DIR)/notary && docker-compose build

$(NOTARY_REPO_DIR)/notary:
	mkdir -p $(NOTARY_REPO_DIR)
	cd $(NOTARY_REPO_DIR) && git clone https://github.com/docker/notary.git
	cd $(NOTARY_REPO_DIR)/notary && git checkout trust-sandbox

clean_notary_containers:
	docker rm -f -v $(NOTARY_CONTAINER_NAME_1) $(NOTARY_CONTAINER_NAME_2) $(NOTARY_CONTAINER_NAME_3) >/dev/null 2>&1; true
	docker volume rm $(NOTARY_VOLUME_NAME) >/dev/null 2>&1; true

clean_notary_images:
	docker rmi -f $(NOTARY_IMAGE_1) $(NOTARY_IMAGE_2) $(NOTARY_IMAGE_3) 2>/dev/null; true

clean_notary_dir:
	rm -fr $(NOTARY_REPO_DIR)
