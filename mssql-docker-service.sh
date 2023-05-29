#! /bin/bash

HOST_DATADIR="/home/hdd/mssql/data"
VOLUME_MOUNT="-v ${HOST_DATADIR}:/var/opt/mssql"

PASSWD='ThisIs!Password'

IMAGE_NAME="mcr.microsoft.com/mssql/server:latest"

docker stop ${IMAGE_NAME}
docker rm ${IMAGE_NAME}

docker run --rm -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=${PASSWD}" \
    -p 1433:1433 \
    --name mssql \
    ${VOLUME_MOUNT} \
    ${IMAGE_NAME}
