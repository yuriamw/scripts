#! /bin/bash

HOST_DATADIR="/var/opt/mssql"
VOLUME_MOUNT="-v ${HOST_DATADIR}:/var/opt/mssql"
# ENTRYPOINT=/opt/mssql/bin/permissions_check.sh
ENTRYPOINT=/opt/mssql/bin/sqlservr

PASSWD='ThisIs!Password'

IMAGE_NAME="cs23devacr.azurecr.io/eplan/infrastructure/mssqltestserver:v6"

docker run -ti --rm -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=${PASSWD}" \
    -p 1433:1433 \
    --name mssql \
    --entrypoint ${ENTRYPOINT} \
    ${VOLUME_MOUNT} \
    ${IMAGE_NAME}
