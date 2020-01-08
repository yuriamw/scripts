#! /bin/bash

sym=
dirlist=
defaultdir=.
elfs=0
nm_search_flags=ABDTWV

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
  echo "        -e,--elfs"
  echo "            Search symbols in all ELF files instead of lib*.so* pattern."
}

SHORT_OPTS="hs:d:e"
LONG_OPTS="help,sym:,dir:,elfs"

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
    -e|--elfs)
      elfs=1
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

search_files() {
    if [ $elfs -eq 0 ]; then
        find $dirlist -name "lib*.so*"
    else
        for _elf in $(find $dirlist -type f); do if [ $(file $_elf | grep -c ELF) -ne 0 ]; then echo $_elf; fi; done
    fi
}

for i in $(search_files); do
    if [ $(nm -D $i 2>/dev/null | grep -c -w "[$nm_search_flags] $sym") -gt 0 ]; then
        echo $i
        nm -D $i | grep -w "[$nm_search_flags] $sym";
    fi
done
