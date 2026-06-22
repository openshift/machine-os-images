#!/bin/bash

set -e

ISO_ARCH="${ISO_ARCH:-$(uname -p)}"
OUTPUT_DIR="coreos"
IMAGE_DATA_FILE="coreos-stream.json"
CACHI2_GENERIC_DIR="/cachi2/output/deps/generic"

if [ ! -d "${OUTPUT_DIR}" ]; then
    mkdir -p "${OUTPUT_DIR}"
fi
cd "${OUTPUT_DIR}"

openshift-install coreos print-stream-json >"${IMAGE_DATA_FILE}"

image_data() {
    local arch="$1"
    local field="$2"

    jq -r ".architectures.${arch}.artifacts.metal.formats.iso.disk.${field}" ${IMAGE_DATA_FILE}
}

download_url() {
    local arch="$1"
    local url="$2"
    shift 2

    local iso_file="coreos-${arch}.iso"
    local iso_sha256
    iso_sha256="$(image_data "${arch}" sha256)"

    wget --quiet "$@" "${url}" -O "${iso_file}"
    local actual_sha256
    actual_sha256="$(sha256sum "${iso_file}" | cut -d' ' -f1)"
    if [ "${actual_sha256}" != "${iso_sha256}" ]; then
        echo "Invalid checksum  ${actual_sha256}" >&2
        echo "Expected checksum ${iso_sha256}" >&2
        exit 1
    fi
    printf "%s" "${iso_sha256}" >"${iso_file}.sha256"
}

download_art_arch() {
    local arch="$1"

    local origurl
    origurl="$(image_data "${arch}" location)"
    local url="$ISO_HOST/${origurl#*.com/art/}"

    download_url "${arch}" "${url}" --no-check-certificate  # skipping certificate check is ok because we will check its sha256 in any case.
}

download_direct_arch() {
    local arch="$1"

    local url
    url="$(image_data "${arch}" location)"

    download_url "${arch}" "${url}"
}

copy_from_cachi2() {
    local arch="$1"

    local iso_file="coreos-${arch}.iso"
    local cachi2_iso="${CACHI2_GENERIC_DIR}/${iso_file}"

    if [ ! -f "${cachi2_iso}" ]; then
        echo "ISO not found in Cachi2 directory: ${cachi2_iso}" >&2
        exit 1
    fi

    cp "${cachi2_iso}" "${iso_file}"

    local iso_sha256
    iso_sha256="$(image_data "${arch}" sha256)"
    local actual_sha256
    actual_sha256="$(sha256sum "${iso_file}" | cut -d' ' -f1)"
    if [ "${actual_sha256}" != "${iso_sha256}" ]; then
        echo "Invalid checksum  ${actual_sha256}" >&2
        echo "Expected checksum ${iso_sha256}" >&2
        exit 1
    fi
    printf "%s" "${iso_sha256}" >"${iso_file}.sha256"
}

download_arch() {
    local arch="$1"

    if [ -d "${CACHI2_GENERIC_DIR}" ]; then
        copy_from_cachi2 "${arch}"
    elif [[ "${DIRECT_DOWNLOAD:-false}" =~ [Tt]rue ]]; then
        download_direct_arch "${arch}"
    else
        download_art_arch "${arch}"
    fi
}

download_arch "${ISO_ARCH}"

