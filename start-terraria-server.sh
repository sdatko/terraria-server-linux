#!/usr/bin/env bash
#
# Run the Terraria server in a Linux container
#
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

BASE_DIR="$(dirname "$(readlink -f "$0")")"

CONTAINER_IMAGE='ubuntu:focal'

LOCAL_SERVER_FILES_DIR="${BASE_DIR}/1432/Linux/"
MOUNT_SERVER_FILES_DIR='/Terraria/'
LOCAL_WORLD_FILES_DIR="${HOME}/.local/share/Terraria/"
MOUNT_WORLD_FILES_DIR='/root/.local/share/Terraria/'

SERVER_ARCHIVE_URL='https://terraria.org/api/download/'
SERVER_ARCHIVE_URL+='pc-dedicated-server/terraria-server-1432.zip'
SERVER_ARCHIVE_FILE=$(basename "${SERVER_ARCHIVE_URL}")

SERVER_EXECUTABLE='TerrariaServer.bin.x86_64'
SERVER_PORT='7777'


#
# Make sure the directory for world data exists
#
mkdir -p "${LOCAL_WORLD_FILES_DIR}"


#
# Download and extract the server files
#
if [ ! -d "${LOCAL_SERVER_FILES_DIR}" ]; then
    pushd "${BASE_DIR}"

    if [ ! -f "${SERVER_ARCHIVE_FILE}" ]; then
        curl --location \
            --remote-name \
            --remote-header-name \
            "${SERVER_ARCHIVE_URL}"
    fi

    unzip "${SERVER_ARCHIVE_FILE}"
    chmod +x "${LOCAL_SERVER_FILES_DIR}/${SERVER_EXECUTABLE}"

    popd
fi


#
# Launch the server
#
# NOTE(sdatko): Exporting TERM solves the following problem for me:
#               System.Exception: Magic number is wrong: 542
#
podman run \
    --interactive \
    --tty \
    --rm \
    --env 'TERM=xterm' \
    --volume "${LOCAL_SERVER_FILES_DIR}:${MOUNT_SERVER_FILES_DIR}" \
    --volume "${LOCAL_WORLD_FILES_DIR}:${MOUNT_WORLD_FILES_DIR}" \
    --publish "${SERVER_PORT}:${SERVER_PORT}" \
    "${CONTAINER_IMAGE}" \
    "${MOUNT_SERVER_FILES_DIR}/${SERVER_EXECUTABLE}"
