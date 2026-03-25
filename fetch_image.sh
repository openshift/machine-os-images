#!/bin/bash

set -ex

ISO_ARCH="${ISO_ARCH:-$(uname -m)}"
OUTPUT_DIR="coreos"
COREOS_VERSIONS="${COREOS_VERSIONS:-9}"

stream_name_for_version() {
    local version="$1"
    case "${version}" in
        9) echo "rhel-9" ;;
        10) echo "rhel-10" ;;
        *)
            echo "Unknown CoreOS version: ${version}" >&2
            exit 1
            ;;
    esac
}

file_prefix_for_version() {
    local version="$1"
    case "${version}" in
        9) echo "coreos" ;;
        10) echo "coreos10" ;;
        *)
            echo "Unknown CoreOS version: ${version}" >&2
            exit 1
            ;;
    esac
}

if [ ! -d "${OUTPUT_DIR}" ]; then
    mkdir -p "${OUTPUT_DIR}"
fi
cd "${OUTPUT_DIR}"

image_data() {
    local data_file="$1"
    local arch="$2"
    local field="$3"

    jq -r ".architectures.${arch}.artifacts.metal.formats.iso.disk.${field}" "${data_file}"
}

download_url() {
    local file_prefix="$1"
    local data_file="$2"
    local arch="$3"
    local url="$4"
    shift 4

    local iso_file="${file_prefix}-${arch}.iso"
    local iso_sha256
    iso_sha256="$(image_data "${data_file}" "${arch}" sha256)"

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
    local file_prefix="$1"
    local data_file="$2"
    local arch="$3"

    local origurl
    origurl="$(image_data "${data_file}" "${arch}" location)"
    local url="$ISO_HOST/${origurl#*.com/art/}"

    download_url "${file_prefix}" "${data_file}" "${arch}" "${url}" --no-check-certificate  # skipping certificate check is ok because we will check its sha256 in any case.
}

download_direct_arch() {
    local file_prefix="$1"
    local data_file="$2"
    local arch="$3"

    local url
    url="$(image_data "${data_file}" "${arch}" location)"

    download_url "${file_prefix}" "${data_file}" "${arch}" "${url}"
}

download_arch() {
    local file_prefix="$1"
    local data_file="$2"
    local arch="$3"

    if [[ "${DIRECT_DOWNLOAD:-false}" =~ [Tt]rue ]]; then
        download_direct_arch "${file_prefix}" "${data_file}" "${arch}"
    else
        download_art_arch "${file_prefix}" "${data_file}" "${arch}"
    fi
}

# Normalize COREOS_VERSIONS: support both comma and space separated
COREOS_VERSIONS="${COREOS_VERSIONS//,/ }"

for version in ${COREOS_VERSIONS}; do
    stream_name="$(stream_name_for_version "${version}")"
    file_prefix="$(file_prefix_for_version "${version}")"
    stream_data_file="${file_prefix}-stream.json"

    openshift-install coreos print-stream-json --stream "${stream_name}" >"${stream_data_file}"

    echo "Downloading CoreOS ${version} (stream: ${stream_name}) for ${ISO_ARCH}"
    download_arch "${file_prefix}" "${stream_data_file}" "${ISO_ARCH}"
done
