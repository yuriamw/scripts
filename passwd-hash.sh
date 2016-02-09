#! /bin/bash

# For busybox MD5
openssl passwd -1 ZoddyY
# For busybox MD5 with my salt
openssl passwd -1 -salt ABcdEF12 ZoddyY
