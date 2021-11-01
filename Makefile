DIRECT_DOWNLOAD ?= true

.PHONY: build
build:
	DIRECT_DOWNLOAD=$(DIRECT_DOWNLOAD) podman build -f Dockerfile .

.PHONY: shellcheck
shellcheck:
	find . -type f -path './scripts/*' -o -name '*.sh' -exec shellcheck -s bash {} \+
