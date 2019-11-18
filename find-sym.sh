#! /bin/bash

sym=
dirlist=
defaultdir=.

usage()
{
  echo "Usage: $(basename $0) [OPTIONS]"
  echo "    Search for DSO where the symbol is defined:"
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -s SYMBOL,--sym=SYMBOL"
  echo "            Search for SYMBOL"
  echo "        -d DIR,--dir=DIR"
  echo "            Search in directory DIR. Repeat multilpe times to search in multiple directories."
  echo "            Default is current directory."
}

SHORT_OPTS="hs:d:"
LONG_OPTS="help,sym:,dir:"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -s|--sym)
      shift
      sym="$1"
    ;;
    -d|--dir)
      shift
      dirlist="${dirlist} $1"
    ;;
    --)
      break
    ;;
    *)
      usage
      exit 1
    ;;
  esac
  shift
done

if [ -z "${sym}" ]; then
    usage
    exit 1
fi
if [ -z "${dirlist}" ]; then
    dirlist=${defaultdir}
fi

for i in $(find $dirlist -name "lib*.so*"); do
    if [ $(nm -D $i 2>/dev/null | grep -c -w "[ABDTW] $sym") -gt 0 ]; then
        echo $i
        nm -D $i | grep -w "[ABDTW] $sym";
    fi
done
