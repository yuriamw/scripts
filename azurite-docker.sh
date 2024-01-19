#! /bin/bash

HOST_DATADIR="/var/opt/azurite"
VOLUME_MOUNT="-v ${HOST_DATADIR}:/data"

# https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?tabs=docker-hub#well-known-storage-account-and-key
# Well-known storage account and key
# Azurite accepts the same well-known account and key used by the legacy Azure Storage Emulator.
#
# Account name: devstoreaccount1
# Account key: Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==
AZURITE_ACCOUNTS="devstoreaccount1:Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="

IMAGE_NAME="mcr.microsoft.com/azure-storage/azurite:latest"

docker run -ti --rm -e "AZURITE_ACCOUNTS=${AZURITE_ACCOUNTS}" \
    -p 10000:10000 -p 10001:10001 -p 10002:10002 \
    --name azurite \
    ${VOLUME_MOUNT} \
    ${IMAGE_NAME}
