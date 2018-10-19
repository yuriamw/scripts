#! /bin/bash

TOOLCHAIN_PATH=/opt/toolchains/zstbgcc-8.2.0-arm-eglibc-2.18-new/bin
CROSS=arm-linux-

DIR=$1
if [ -z "$DIR" ]; then
  DIR=.
fi

for i in `find $DIR -type f`; do
  if [ `file $i | grep -c ELF` -gt 0 ]; then
    echo $i
    $TOOLCHAIN_PATH/${CROSS}readelf -W -s $i | grep ' UNIQUE ' | c++filt
  fi
done
