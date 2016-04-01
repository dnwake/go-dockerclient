## We need to set up /etc/hosts so that containers can talk to each other
TMPFILE=$(TMPDIR)/docker_etc_hosts
DOCKER_SOCK := $(shell ls /var/run/docker.sock 2>/dev/null)

etc_hosts: 
ifeq ($(DOCKER_SOCK),/var/run/docker.sock)
	echo "Setting up /etc/hosts on Linux"
	cat /etc/hosts > $(TMPFILE)
	grep -q "127.0.0.1 $(NOTARY_HOST)" $(TMPFILE)   || echo "127.0.0.1 $(NOTARY_HOST)"   >> $(TMPFILE)
	grep -q "127.0.0.1 $(REGISTRY_HOST)" $(TMPFILE) || echo "127.0.0.1 $(REGISTRY_HOST)" >> $(TMPFILE)
	echo " ... I need sudo permission to edit /etc/hosts -- if I don't have it, this will possibly hang"
	sudo mv $(TMPFILE) /etc/hosts
else ifeq ($(DOCKER_HOST),"")
	echo "Neither /var/run/docker.sock nor \$DOCKER_HOST available: is Docker running?"
	exit 1
else ifeq ($(DOCKER_MACHINE_NAME),"")
	echo "Assuming docker-machine, but \$DOCKER_MACHINE_NAME not set: is Docker running?"
	exit 1
else
	echo "Setting up /etc/hosts on docker-machine VM"
	docker-machine ssh $(DOCKER_MACHINE_NAME) cat /etc/hosts > $(TMPFILE)
	grep -q "127.0.0.1 $(NOTARY_HOST)" $(TMPFILE)   || echo "127.0.0.1 $(NOTARY_HOST)"   >> $(TMPFILE)
	grep -q "127.0.0.1 $(REGISTRY_HOST)" $(TMPFILE) || echo "127.0.0.1 $(REGISTRY_HOST)" >> $(TMPFILE)
	docker-machine ssh $(DOCKER_MACHINE_NAME) mkdir -p /tmp
	docker-machine scp $(TMPFILE) $(DOCKER_MACHINE_NAME):/tmp/etc_hosts
	docker-machine ssh $(DOCKER_MACHINE_NAME) sudo mv /tmp/etc_hosts /etc/hosts
endif
