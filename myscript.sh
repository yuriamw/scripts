#! /bin/bash

echo "###   TWEAK"
TWEAK=
# TWEAK="$TWEAK zstbgcc-8.3.0-arm-eglibc-2.18.tbz2"
# TWEAK="$TWEAK zstbgcc-8.3.0-mipsel-uclibc-0.9.29.tbz2"
TWEAK="$TWEAK zstbgcc-8.3.0-mipsel-uclibc-0.9.32.tbz2"
rm -rf /opt/toolchains/zstbgcc-8.*
for i in $TWEAK; do
  echo "###   $i"
  tar -jxf tools/builder/$i -C /
done
ls -ld /opt/toolchains/*
echo "###   TWEAKED"
