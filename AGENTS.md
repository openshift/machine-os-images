# Machine OS Images - AI Agent Instructions

Instructions for AI coding agents. This repository builds container images containing CoreOS ISOs and provides scripts to extract ISOs or PXE boot files for OpenShift baremetal platform infrastructure.

## Repository Structure

| File/Directory | Purpose |
|----------------|---------|
| `Dockerfile` | Multi-stage build for CoreOS ISO container |
| `Makefile` | Build and lint targets |
| `fetch_image.sh` | Downloads CoreOS ISOs during build |
| `.ci-operator.yaml` | OpenShift CI configuration |
| `scripts/copy-iso` | Copy ISO to mounted volume with optional kernel arg injection |
| `scripts/copy-pxe` | Extract PXE boot files (kernel, initrd, rootfs) from ISO |
| `scripts/copy-metal` | Orchestrate copy-iso/copy-pxe for baremetal deployments |

## Testing Standards

CI uses OpenShift CI (`.ci-operator.yaml`). Run these locally before submitting PRs:

| Command | Purpose |
|---------|---------|
| `make shellcheck` | Shell script linting via shellcheck |
| `make build` | Build container image (uses `DIRECT_DOWNLOAD=true`) |

**Note**: This repository has no unit tests; validation is via shellcheck only.

## Code Conventions

- **Shell**: Use `set -o errexit -o nounset -o pipefail`
- **Dockerfile**: Multi-stage builds with SHA256 validation for downloads
- **Scripts**: Idempotent operations (check SHA256 before copying/extracting)

## Key Components

### Build Process

Two-stage Dockerfile: builder downloads CoreOS ISO via `fetch_image.sh` (uses `openshift-install coreos print-stream-json`, validates SHA256); final stage bundles tools (`coreos-installer`, `jq`, `oc`) and scripts.

**Key environment variables:**
- `DIRECT_DOWNLOAD`: Download source (`true`=public, `false`=lookaside cache)
- `ISO_ARCH`: Architecture to download (default: `uname -p`)
- `MACHINE_OS_IMAGES_IMAGE`: Cross-arch extraction (requires pull secret at `/run/secrets/pull-secret`)

### Runtime Scripts

- `/bin/copy-iso`: Copy ISO with kernel arg injection (`IP_OPTIONS`), FIPS auto-detection
- `/bin/copy-pxe`: Extract PXE files (kernel, initrd, rootfs), `--initrd-only` flag support
- `/bin/copy-metal`: Orchestrate extraction, three modes (`--all`, `--pxe`, `--image-build`)

## Code Review Guidelines

When reviewing pull requests:

1. **Security** - No hardcoded credentials, validate SHA256 checksums, careful with `--insecure` flags
1. **Shellcheck compliance** - All scripts must pass shellcheck
1. **Idempotency** - Scripts should check SHA256 before redundant operations
1. **Error handling** - Use `set -o errexit -o nounset -o pipefail`

Focus on: `Dockerfile`, `fetch_image.sh`, `scripts/`

## AI Agent Guidelines

### Before Changes

1. Run `make shellcheck` to verify baseline
1. Check patterns in existing shell scripts

### When Making Changes

1. Make minimal, surgical edits
1. Run `make shellcheck` before committing
1. Test build process for Dockerfile changes: `make build`
1. Verify SHA256 validation remains intact for security

### Security Requirements

- Validate SHA256 checksums for all downloads
- Use `--insecure` only when SHA256 is verified (lookaside cache mode)
- Pin external dependencies by SHA where possible
- No hardcoded credentials or secrets
