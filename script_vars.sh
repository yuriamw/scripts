#! /bin/bash

alias script=". bcm/refsw/BSEAV/tools/build/plat 97405 C0"

VARS="`set -o posix ; set`"

DEBUG=y
# set -x
. bcm/refsw/BSEAV/tools/build/plat 97405 C0
# set +x

SCRIPT_VARS="`grep -vFe "$VARS" <<< "$(set -o posix ; set)" | grep -v ^VARS=`"
unset VARS
echo $SCRIPT_VARS
