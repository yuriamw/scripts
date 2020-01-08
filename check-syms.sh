#! /bin/bash

rootfs=
config=
outdir=
prefix=
script=
default_outdir=.
default_script=gn/check_missed_symbols.py

usage()
{
  echo "Usage: $(basename $0) [OPTIONS]"
  echo "    Search for DSO where the symbol is defined:"
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -r ROOTFS,--rootfs=ROOTFS"
  echo "            Check symbols in the directory tree ROOTFS. Mandatory."
  echo "        -c CONFIG,--config=CONFIG"
  echo "            Configuration file. Mandatory."
  echo "        -o OUTDIR,--outdir=OUTDIR"
  echo "            Put output files into OUTDIR. Default is ${default_outdir}."
  echo "        -p PREFIX,--prefix=PREFIX"
  echo "            Add PREFIX to output files. Optional. Default is empty."
  echo "        -s SCRIPT,--script=SCRIPT"
  echo "            Call SCRIPT instead. Optional. Default is '${default_script}'."
}

SHORT_OPTS="hr:c:o:p:s:"
LONG_OPTS="help,rootfs:,config:,outdir:,prefix:,script:"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -r|--rootfs)
      shift
      rootfs="$(realpath $1)"
    ;;
    -c|--config)
      shift
      config="$1"
    ;;
    -o|--outdir)
      shift
      outdir="$1"
    ;;
    -p|--prefix)
      shift
      prefix="$1"
    ;;
    -s|--script)
      shift
      script="$1"
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

if [ -z "${script}" ]; then
    script=${default_script}
fi
if [ -z "${outdir}" ]; then
    outdir=${default_outdir}
fi
if [ -z "${rootfs}" -o -z "${config}" -o -z "${outdir}" ]; then
    usage
    exit 1
fi

report_file=${outdir}/${prefix}check_symbols_result.txt
database_file=${outdir}/${prefix}dependency_tree.db
csv_file=${outdir}/${prefix}deps_table.csv

rm -f ${report_file} ${database_file} ${csv_file}
mkdir -p ${outdir}

python ${script} \
    --sysroot_stripped_path ${rootfs} \
    --config_path ${config} \
    --report_path ${report_file} \
    --database_path ${database_file} \
    --csv_path ${csv_file}
