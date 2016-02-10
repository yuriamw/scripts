#! /bin/bash

# For busybox MD5
echo ZoddyY
openssl passwd -1 ZoddyY
# For busybox MD5 with my salt
echo "ZoddyY with salt ABcdEF12"
openssl passwd -1 -salt ABcdEF12 ZoddyY

# For busybox MD5 from commandline
if [ -n "$1" ]; then
  echo "From command line arg[1]"
  openssl passwd -1 $1
fi
