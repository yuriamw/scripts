#! /bin/bash

# -v /my/own/datadir:/data/db -d mongo
HOST_DATADIR="/home/hdd/mongo/data"
VOLUME_MOUNT="-v ${HOST_DATADIR}:/data/db"

docker run -ti --rm \
    -p 27017:27017 \
    ${VOLUME_MOUNT} \
    mongo
