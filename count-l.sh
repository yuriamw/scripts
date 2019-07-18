#! /bin/bash

if [ -z "$1" ]; then
  echo "Usage: $(basename "$0") <input-file>"
  echo "    Check input rsp file (GN) <input-file> for duplica -lname options"
  exit 1
fi

INFILE="$1"

cat "$INFILE" | tr ' ' '\n' | sed -n -e '/^\-l/p' | sort | uniq -c
