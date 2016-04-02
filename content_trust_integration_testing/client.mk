## This container is responsible for pulling and verifying images from the registry
export CLIENT_DIR=$(TMPDIR)/client_repo
export CLIENT_IMAGE_NAME=client_image
export CLIENT_IMAGE=$(IMAGEDIR)/$(CLIENT_IMAGE_NAME)
export CLIENT_CONTAINER_NAME=client_container
export CLIENT_CONTAINER=$(CONTAINERDIR)/$(CLIENT_CONTAINER_NAME)
export CLIENT_LOG=$(TMPDIR)/client_log
export GO_DOCKERCLIENT_DIR=$(THISDIR)/..
export DOCKER_VERSION=$(shell docker version --format '{{.Server.Version}}')

prepare_client: client
	echo "Getting all required Go dependencies.  This may take some time..."
	docker exec -t $(CLIENT_CONTAINER_NAME) bash -c ' \
	        export GOPATH=/root/go && \
                if ! test -f $$GOPATH/deps_loaded; then \
	            go_files="$$(find $$GOPATH -name *.go)" && \
	            go_src_dirs="$$(for file in $$go_files; do dirname $$file; done | sort | uniq)"; \
		    for dir in $$go_src_dirs; do cd $$dir && go get; done; \
                    touch $$GOPATH/deps_loaded; \
                fi \
	'

client: client_image notary registry
	$(DOCKER_RUN) \
		$(CLIENT_CONTAINER_NAME) \
		$(CLIENT_LOG) \
		-t \
		--privileged \
		--name=${CLIENT_CONTAINER_NAME} \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(GO_DOCKERCLIENT_DIR):/root/go/src/github.com/fsouza/go-dockerclient \
                -v $(THISDIR)/src:/root/go/src/main \
		--link $(NOTARY_CONTAINER_NAME_1):$(NOTARY_HOST) \
		--link $(REGISTRY_CONTAINER_NAME):$(REGISTRY_HOST) \
		$(CLIENT_IMAGE_NAME)

client_image: $(CLIENT_IMAGE)

$(CLIENT_IMAGE): $(NOTARY_REPO_DIR)/notary
	mkdir -p $(CLIENT_DIR)
	cp $(NOTARY_REPO_DIR)/notary/fixtures/root-ca.crt $(CLIENT_DIR)
	cp $(DOCKERFILE_DIR)/client_dockerfile $(CLIENT_DIR)/Dockerfile
	cd $(CLIENT_DIR) && docker build --build-arg docker_version=$(DOCKER_VERSION) -t $(CLIENT_IMAGE_NAME) .

clean_client_container:
	docker rm -f -v $(CLIENT_CONTAINER_NAME) 2>/dev/null; true

clean_client_image:
	docker rmi -f $(CLIENT_IMAGE_NAME) 2>/dev/null; true

clean_client_dir:
	rm -fr $(CLIENT_DIR)
