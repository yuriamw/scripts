#! /bin/bash

WALLET="R9P2yrMPxQXNhk7U6EqqcPeWbQrvLRWX5A"
USER="${WALLET}.x96-1"
PROTOCOL="stratum+tcp"
HOST="pool.verus.io"
PORT="9998"
POOL="${PROTOCOL}://${HOST}:${PORT}"

PARAMS=(
    --no-color
    --syslog
    --syslog-prefix=ccminer
    -p=x
    -t=4
    --cpu-priority=5
)

/home/x96/verus/ccminer -a verus -o "${POOL}" -u "${USER}" "${PARAMS[@]}"
