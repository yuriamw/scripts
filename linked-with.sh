#! /bin/bash

LIBNAME=$1
SEARCHDIR=.

if [ -z "$LIBNAME" ]; then
  echo "ERROR: Usage: $(basename $0) <libname.so>"
  exit 1
fi

for f in $(find $SEARCHDIR -type f); do
  if [ -n "$(file $f | grep ELF)" ]; then
    if [ -n "$(readelf -d $f | sed -n -e '/.*NEEDED.*'$LIBNAME'/p')" ]; then
      echo $f
    fi
  fi
done
