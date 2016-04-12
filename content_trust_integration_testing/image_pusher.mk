## This container is responsible for pushing images to the registry
export IMAGE_PUSHER_CONTAINER_NAME=image_pusher
export IMAGE_PUSHER_2_CONTAINER_NAME=image_pusher_2
export IMAGE_PUSHER_LOG=$(TMPDIR)/image_pusher_log
export IMAGE_PUSHER_2_LOG=$(TMPDIR)/image_pusher_2_log

push_images: image_pusher good_image bad_image registry notary
	echo "If necessary, pushing good, bad and corrupted images to the registry.  May take some time..."
	docker exec $(IMAGE_PUSHER_CONTAINER_NAME) bash -c ' \
		if ! docker pull $(REGISTRY_URL)/$(GOOD_IMAGE_NAME):latest >/dev/null 2>/dev/null; then \
			export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=root; \
			export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=repository; \
			export DOCKER_CONTENT_TRUST=1; \
			export DOCKER_CONTENT_TRUST_SERVER=$(NOTARY_URL); \
			docker tag -f $(GOOD_IMAGE_NAME) $(REGISTRY_URL)/$(GOOD_IMAGE_NAME):latest && \
			docker tag -f $(GOOD_IMAGE_NAME) $(REGISTRY_URL)/$(CORRUPT_GOOD_IMAGE_NAME):latest && \
			docker tag -f $(BAD_IMAGE_NAME) $(REGISTRY_URL)/$(BAD_IMAGE_NAME):latest && \
			docker push $(REGISTRY_URL)/$(GOOD_IMAGE_NAME):latest >/dev/null && \
			docker push $(REGISTRY_URL)/$(BAD_IMAGE_NAME):latest >/dev/null && \
			docker push $(REGISTRY_URL)/$(CORRUPT_GOOD_IMAGE_NAME):latest >/dev/null; \
		fi; \
'

	echo "Delegating push authority to the shared key for $(BAD_IMAGE_NAME)"

	docker exec $(IMAGE_PUSHER_CONTAINER_NAME) bash -c ' \
		/root/notary/notary -v -D -s $(NOTARY_URL) -d /root/.docker/trust \
			key rotate $(REGISTRY_URL)/$(BAD_IMAGE_NAME) snapshot -r; \
		/root/notary/notary -v -D -s $(NOTARY_URL) -d /root/.docker/trust \
			delegation add $(REGISTRY_URL)/$(BAD_IMAGE_NAME) targets/release /root/delegation.crt all-paths; \
		/root/notary/notary -v -D -s $(NOTARY_URL) -d /root/.docker/trust \
			publish $(REGISTRY_URL)/$(BAD_IMAGE_NAME) \
'

	echo "Corrupting $(CORRUPT_GOOD_IMAGE_NAME) so it actually points to $(BAD_IMAGE_NAME) in the registry"

	docker exec $(REGISTRY_CONTAINER_NAME) bash -c ' \
		rm -fr /var/lib/registry/docker/registry/v2/repositories/$(CORRUPT_GOOD_IMAGE_NAME) && \
		ln -sf /var/lib/registry/docker/registry/v2/repositories/$(BAD_IMAGE_NAME) \
		 /var/lib/registry/docker/registry/v2/repositories/$(CORRUPT_GOOD_IMAGE_NAME) \
	'

push_images_2: image_pusher_2 good_image bad_image registry notary
	echo "If necessary, pushing good, bad and corrupted images to the registry.  May take some time..."
	docker exec $(IMAGE_PUSHER_2_CONTAINER_NAME) bash -c ' \
			export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE=root; \
			export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE=repository; \
			export DOCKER_CONTENT_TRUST=1; \
			export DOCKER_CONTENT_TRUST_SERVER=$(NOTARY_URL); \
			docker tag -f $(GOOD_IMAGE_NAME) $(REGISTRY_URL)/$(GOOD_IMAGE_NAME):latest && \
			docker tag -f $(GOOD_IMAGE_NAME) $(REGISTRY_URL)/$(CORRUPT_GOOD_IMAGE_NAME):latest && \
			docker tag -f $(BAD_IMAGE_NAME) $(REGISTRY_URL)/$(BAD_IMAGE_NAME):latest && \
			docker push $(REGISTRY_URL)/$(GOOD_IMAGE_NAME):latest >/dev/null && \
			docker push $(REGISTRY_URL)/$(BAD_IMAGE_NAME):latest >/dev/null && \
			docker push $(REGISTRY_URL)/$(CORRUPT_GOOD_IMAGE_NAME):latest >/dev/null; \
	'
image_pusher: notary registry client_image etc_hosts
	$(DOCKER_RUN) \
		$(IMAGE_PUSHER_CONTAINER_NAME) \
		$(IMAGE_PUSHER_LOG) \
		-t \
		--privileged \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--link $(NOTARY_CONTAINER_NAME_1):$(NOTARY_HOST) \
		--link $(REGISTRY_CONTAINER_NAME):$(REGISTRY_HOST) \
		$(CLIENT_IMAGE_NAME)

image_pusher_2: notary registry client_image etc_hosts push_images
	$(DOCKER_RUN) \
		$(IMAGE_PUSHER_2_CONTAINER_NAME) \
		$(IMAGE_PUSHER_LOG) \
		-t \
		--privileged \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--link $(NOTARY_CONTAINER_NAME_1):$(NOTARY_HOST) \
		--link $(REGISTRY_CONTAINER_NAME):$(REGISTRY_HOST) \
		$(CLIENT_IMAGE_NAME)

clean_image_pusher_containers:
	docker rm -f -v $(IMAGE_PUSHER_CONTAINER_NAME) 2>/dev/null; true
	docker rm -f -v $(IMAGE_PUSHER_2_CONTAINER_NAME) 2>/dev/null; true
