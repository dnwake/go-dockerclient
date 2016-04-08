export BAD_IMAGE_DIR=$(TMPDIR)/bad_image
export BAD_IMAGE_NAME=bad_image
export BAD_IMAGE=$(IMAGEDIR)/$(BAD_IMAGE_NAME)

bad_image: $(BAD_IMAGE)

$(BAD_IMAGE): 
	mkdir -p $(BAD_IMAGE_DIR)
	cp $(DOCKERFILE_DIR)/bad_dockerfile $(BAD_IMAGE_DIR)/Dockerfile
	cd $(BAD_IMAGE_DIR) && docker build -t $(BAD_IMAGE_NAME) .

clean_bad_image:
	docker rmi -f $(BAD_IMAGE_NAME) 2>/dev/null; true
