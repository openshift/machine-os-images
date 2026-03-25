DIRECT_DOWNLOAD ?= true
COREOS_VERSIONS ?= 9

.PHONY: build
build:
	podman build -f Dockerfile . --build-arg "DIRECT_DOWNLOAD=$(DIRECT_DOWNLOAD)" --build-arg "COREOS_VERSIONS=$(COREOS_VERSIONS)"

.PHONY: shellcheck
shellcheck:
	find . -type f -path './scripts/*' -o -name '*.sh' -exec shellcheck -s bash {} \+
