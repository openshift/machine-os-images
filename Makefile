DIRECT_DOWNLOAD ?= true

.PHONY: build
build:
	DIRECT_DOWNLOAD=$(DIRECT_DOWNLOAD) podman build -f Dockerfile .
