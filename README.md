# Machine OS Images

This repo builds a container image that contains the latest CoreOS ISO and can
regurgitate it or the corresponding PXE files (kernel, initrd, rootfs).

## Building the image

By default, the ISO is downloaded from the lookaside cache available only in
OpenShift CI. To download directly (for local builds, or OKD), set the arg
`DIRECT_DOWNLOAD=true` (the `make build` target sets this for you).

## Retrieving the Machine OS

The scripts `/bin/copy-iso` and `/bin/copy-pxe` can be used to copy the ISO and
PXE files respectively to a volume that is bound into the container. Pass the
destination path as an argument. For example:

    podman run --rm -v .:/data:bind /bin/copy-iso /data

For the `copy-iso` script, if the `IP_OPTIONS` environment variable is
non-empty then the output ISO will be configured to add the provided option to
the kernel command line.

The script `/bin/copy-metal` calls `copy-iso` and `copy-pxe` to copy the
specific files needed for parts of the baremetal platform, depending on the
first argument: `--all` for all files; `--pxe` for just the PXE files; or
`--image-build` for just the ISO and initrd. In addition, symlinks are created
so that filenames match the ones used in previous versions of the metal
platform.

