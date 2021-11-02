DIRECT_DOWNLOAD ?= true

.PHONY: build
build:
	podman build -f Dockerfile . --build-arg DIRECT_DOWNLOAD=$(DIRECT_DOWNLOAD)

.PHONY: shellcheck
shellcheck:
	find . -type f -path './scripts/*' -o -name '*.sh' -exec shellcheck -s bash {} \+
