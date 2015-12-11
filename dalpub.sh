#! /bin/bash

DALPKG=$1

if [ ! -f "$1" ]; then
  echo "Usage: `basename $0` <dal.package.zip>"
  exit 1
fi

UUID=${UUID:-ciscowb}

set -x
curl -v -X POST --form uid=$UUID --form submit=Upload --form file=@$DALPKG http://172.24.133.145:8080/ams/dalPackagePublisher
