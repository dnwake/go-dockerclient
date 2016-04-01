export GOOD_IMAGE_DIR=$(TMPDIR)/good_image
export GOOD_IMAGE_NAME=good_image
export GOOD_IMAGE=$(IMAGEDIR)/$(GOOD_IMAGE_NAME)
export CORRUPT_GOOD_IMAGE_NAME=corrupt_good_image

good_image: $(GOOD_IMAGE)

$(GOOD_IMAGE):
	mkdir -p $(GOOD_IMAGE_DIR)
	cp $(DOCKERFILE_DIR)/good_dockerfile $(GOOD_IMAGE_DIR)/Dockerfile
	cd $(GOOD_IMAGE_DIR) && docker build -t $(GOOD_IMAGE_NAME) .
	$(UPDATE_IMAGES)

clean_good_image:
	docker rmi -f $(GOOD_IMAGE_NAME) 2>/dev/null; true
