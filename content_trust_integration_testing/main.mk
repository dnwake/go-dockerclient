export THISDIR         :=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export TMPDIR          := $(THISDIR)/tmp
export SCRIPTDIR       := $(THISDIR)/scripts
export IMAGEDIR        := $(TMPDIR)/images
export DOCKERFILE_DIR  := $(THISDIR)/dockerfiles

all: tests

clean: clean_containers

clean_all: clean_containers clean_images clean_dirs

clean_containers: clean_notary_containers clean_registry_container clean_client_container clean_image_pusher_container

clean_images: clean_notary_images clean_registry_image clean_client_image clean_good_image clean_bad_image list_images

clean_dirs: clean_notary_dir clean_registry_dir clean_client_dir

include notary.mk registry.mk client.mk good_image.mk bad_image.mk image_pusher.mk hosts.mk tests.mk

Makefile: refresh_images

refresh_images:
	$(CLEAN_IMAGES)
	$(UPDATE_IMAGES)

.PHONY: all \
	bad_image \
	build_client \
	clean \
	clean_all \
	clean_bad_image \
	clean_containers \
	clean_dirs \
	clean_good_image \
	clean_image_pusher_container \
	clean_images \
	clean_client_container \
	clean_client_dir \
	clean_client_image \
	clean_notary_containers \
	clean_notary_dir \
	clean_notary_images \
	clean_registry_container \
	clean_registry_dir \
	clean_registry_image \
	etc_hosts \
	etc_hosts_linux \
	etc_hosts_osx \
	good_image \
	image_pusher \
	client \
	client_container \
	client_image \
	client_server \
	list_containers \
	list_images \
	notary \
	notary_image \
	pause_image \
	push_images \
	registry \
	registry_image \
	restart_notary \
	restart_registry \
	run-test \
	test_bad \
	test_error 


CLEAN_IMAGES = bash -c ' \
rm -fr $(IMAGEDIR) >/dev/null \
'

UPDATE_IMAGES = bash -c ' \
mkdir -p $(IMAGEDIR) && \
cd $(IMAGEDIR) && \
for image in $$(docker images | awk "{print \$$1}" | grep -v none | grep -v /); do \
  test -f image || { mkdir -p $$(dirname $$image) && touch $$image; } \
done \
'

DOCKER_RUN              := $(SCRIPTDIR)/docker_run.sh
