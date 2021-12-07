#!/bin/bash

set -e

ISO_ARCH="${ISO_ARCH:-$(uname -p)}"
OUTPUT_DIR="coreos"
IMAGE_DATA_FILE="coreos-stream.json"
SOURCES_FILE="/usr/share/coreos-sources"

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

    local iso_file="coreos-${arch}.iso"
    local iso_sha256
    iso_sha256="$(image_data "${arch}" sha256)"

    wget "${url}" -O "${iso_file}"
    local actual_sha256
    actual_sha256="$(sha256sum "${iso_file}" | cut -d' ' -f1)"
    if [ "${actual_sha256}" != "${iso_sha256}" ]; then
        echo "Invalid checksum  ${actual_sha256}" >&2
        echo "Expected checksum ${iso_sha256}" >&2
        exit 1
    fi
    printf "%s" "${iso_sha256}" >"${iso_file}.sha256"
}


get_sha512() {
    local iso_file="$1"

    awk "/^SHA512 / { if (\$2 == \"(${iso_file})\") print \$4 }" "${SOURCES_FILE}" | tail -n 1
}

download_lookaside_arch() {
    local arch="$1"

    local iso_file
    local iso_sha512
    iso_file="$(basename "$(image_data "${arch}" location)")"
    iso_sha512="$(get_sha512 "${iso_file}")"

    if [ -z "${iso_sha512}" ]; then
        echo "No SHA512 sum found for ${iso_file}" >&2
        exit 1
    fi

    local lookaside="http://pkgs.devel.redhat.com/repo"
    local url="${lookaside}/containers/ose-installer/${iso_file}/sha512/${iso_sha512}/${iso_file}"

    download_url "${arch}" "${url}"
}

download_direct_arch() {
    local arch="$1"

    local url
    url="$(image_data "${arch}" location)"

    download_url "${arch}" "${url}"
}

download_arch() {
    local arch="$1"

    if [[ "${DIRECT_DOWNLOAD:-false}" =~ [Tt]rue ]]; then
        download_direct_arch "${arch}"
    else
        download_lookaside_arch "${arch}"
    fi
}

download_arch "${ISO_ARCH}"
