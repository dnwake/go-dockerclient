### Build and run a Docker V2 registry server in a Docker container
### Adapted from https://docs.docker.com/engine/security/trust/trust_sandbox/
export REGISTRY_REPO_DIR=$(TMPDIR)/registry_repo
export REGISTRY_IMAGE_NAME=registry_image
export REGISTRY_IMAGE=$(IMAGEDIR)/$(REGISTRY_IMAGE_NAME)
export REGISTRY_CONTAINER_NAME=registry_container
export REGISTRY_CONTAINER=$(CONTAINERDIR)/$(REGISTRY_CONTAINER_NAME)
export REGISTRY_GIT_URL=https://github.com/docker/distribution.git
export REGISTRY_GIT_COMMIT=e430d77342
export REGISTRY_HOST=registry-server
export REGISTRY_PORT=5000
export REGISTRY_URL=$(REGISTRY_HOST):$(REGISTRY_PORT)
export REGISTRYLOG=$(TMPDIR)/registrylog

STATUS=$(shell $(GET_CONTAINER_STATUS) $(REGISTRY_CONTAINER_NAME))


registry: $(REGISTRY_IMAGE)
	$(DOCKER_RUN) \
		$(REGISTRY_CONTAINER_NAME) \
		$(REGISTRYLOG) \
		-p $(REGISTRY_PORT):$(REGISTRY_PORT) \
		$(REGISTRY_IMAGE_NAME)

registry_image: $(REGISTRY_IMAGE)

$(REGISTRY_IMAGE): $(REGISTRY_REPO_DIR)/distribution
	cd $(REGISTRY_REPO_DIR)/distribution && docker build -t $(REGISTRY_IMAGE_NAME) .

$(REGISTRY_REPO_DIR)/distribution:
	mkdir -p $(REGISTRY_REPO_DIR)
	cd $(REGISTRY_REPO_DIR) && git clone $(REGISTRY_GIT_URL)
	cd $(REGISTRY_REPO_DIR)/distribution && git checkout $(REGISTRY_GIT_COMMIT)

clean_registry_container:
	docker rm -f -v $(REGISTRY_CONTAINER_NAME) >/dev/null 2>&1; true

clean_registry_image:
	docker rmi -f $(REGISTRY_IMAGE_NAME) 2>/dev/null; true

clean_registry_dir:
	rm -fr $(REGISTRY_REPO_DIR)
