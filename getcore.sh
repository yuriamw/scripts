#! /bin/bash

DO_DOWNLOAD=0
DO_RUN=0
DO_ALL=1

default_nfs_server=ctec
default_nfs_root=/home/nfs_builds/iovcharenko
default_nfs_core_name=core
default_gn_tree=${HOME}/work/soft/charter/IPStack/valhalla
default_buildtype=dev
default_mso=charter
default_cpu=mipsel
default_platform=humaxwb11
default_user="$USER"
default_toolchain=zstbgcc-8.2.0-mipsel-uclibc-0.9.32
default_toolchain_local_prefix=/home/iurii.ovcharenko/work/soft/charter/IPStack/toolchain/valhalla
default_core_dir=core

nfs_server=""
nfs_root=""
nfs_core_name=""
gn_tree=""
buildtype=""
mso=""
cpu=""
platform=""
app=""
user=""
toolchain=""
toolchain_prefix=""
core_dir=""

local_toolchain=0

usage()
{
  echo "Usage: $(basename $0) [OPTIONS]"
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -d,--download"
  echo "            Only download core file and get libs from build."
  echo "        -r,--run"
  echo "            Only run GDB only."
  echo "        -n [PATH_TO_CORE],--nfs-core=[PATH_TO_CORE]"
  echo "            Download core file specified by PATH_TO_CORE from ${default_nfs_root}/PATH_TO_CORE"
  echo "        -a NAME,--app NAME"
  echo "            Core is for application name APP."
  echo "        -o [DIR],--core=[DIR]"
  echo "            Download core file into directory DIR. Default is ${default_core_dir}"
  echo "        -A NAME,--app-with-dir NAME"
  echo "            The same as -a NAME -o NAME."
  echo "        -g [PATH_TO_GN_BUILD],--gn=[PATH_TO_GN_BUILD]"
  echo "            Get libs and binaries from the out directory of GN build tree specified by PATH_TO_GN_BUILD"
  echo "            Default is ${default_gn_tree}"
  echo "        -p PLATFORM,--platform=PLATFORM"
  echo "            Search for build products for PLATFORM. Default is $default_platform"
  echo "        -c CPU,--cpu=CPU"
  echo "            Search for build products for CPU. Default is '$default_cpu'"
  echo "        -b BUILDTYPE,--build-type=BUILDTYPE"
  echo "            Search for BUILDTYPE build products. Default is '$default_buildtype'"
  echo "        -m MSO,--mso=MSO"
  echo "            Search under mso MSO for build products. Default is '$default_mso'"
  echo "        -t TOOLCHAIN,--toolchain=TOOLCHAIN"
  echo "            Use toolchain TOOLCHAIN. Default is '$default_toolchain'"
  echo "        -l,--local-toolchain"
  echo "            Use locally built toolchain from GN build."
  echo "        -u USER,--user=USER"
  echo "            Login to NFS server as user USER. Default is '$default_user'"
}

SHORT_OPTS="hdrn:o:g:c:p:b:a:A:t:l"
LONG_OPTS="help,download,run,nfs-core:core:gn:cpu:platform:build-type:app:app-with-dir:toolchain:local-toolchain"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -d|--download)
      DO_ALL=0
      DO_DOWNLOAD=1
    ;;
    -r|--run)
      DO_ALL=0
      DO_RUN=1
    ;;
    -n|--nfs-core)
      shift
      nfs_core_name="$1"
    ;;
    -a|--app)
      shift
      app="$1"
    ;;
    -o|--core)
      shift
      core_dir="$1"
    ;;
    -A|--app-with-dir)
      shift
      app="$1"
      core_dir="$1"
    ;;
    -g|--gn)
      shift
      gn_tree="$1"
    ;;
    -p|--platform)
      shift
      platform="$1"
    ;;
    -c|--cpu)
      shift
      cpu="$1"
    ;;
    -b|--build-type)
      shift
      buildtype="$1"
    ;;
    -t|--toolchain)
      shift
      toolchain="$1"
    ;;
    -l|--local-toolchain)
      local_toolchain=1
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

set_default_if_empty() {
  local x="`eval echo \\$$1`"
  local y="default_${1}"
  if [ -z "$x" ]; then
    eval $1="`eval echo \\$$y`"
  fi
}

set_default_if_empty nfs_server
set_default_if_empty nfs_root
set_default_if_empty nfs_core_name
set_default_if_empty gn_tree
set_default_if_empty buildtype
set_default_if_empty mso
set_default_if_empty cpu
set_default_if_empty platform
set_default_if_empty user
set_default_if_empty toolchain
set_default_if_empty core_dir

if [ $local_toolchain -eq 1 ]; then
  toolchain_prefix=${default_toolchain_local_prefix}/tools/toolchain-build/.install/${toolchain}
fi

if [ $DO_ALL -eq 1 ]; then
  DO_DOWNLOAD=1
  DO_RUN=1
fi

if [ $DO_DOWNLOAD -eq 1 ]; then
  rm -rf ${core_dir}
  mkdir -p ${core_dir}
  set +e
  for f in lib usr/lib usr/bin; do
#     cp -fv ${gn_tree}/out.${mso}-${platform}/linux/${cpu}/${buildtype}/sysroot/$f/* ${core_dir}/
    cp -fv ${gn_tree}/out.${mso}-${platform}-${buildtype}/linux/sysroot/$f/* ${core_dir}/
    echo $?
  done
  set -e
#   cp -a /opt/toolchains/zstbgcc-8.1.0-mipsel-uclibc-0.9.32/mipsel-linux-uclibc/lib/{libstdc++.so,libstdc++.so.6,libstdc++.so.6.0.25} ${core_dir}/

  scp ${user}@${nfs_server}:${nfs_root}/${nfs_core_name} ${core_dir}/
fi

if [ $DO_RUN -eq 1 ]; then
  ${toolchain_prefix}/opt/toolchains/${toolchain}/bin/${cpu}-linux-gdb -e ${core_dir}/${app} -s ${core_dir}/${app} -c ${core_dir}/`basename ${nfs_core_name}` --eval-command="set solib-search-path ${core_dir}"
fi
