#! /bin/bash -e

export LC_ALL=C

TARGET=

DO_POWERUP=1
DO_DVBS=2
DO_IMAGE=3
ACTION=0

usage()
{
  echo "Usage: $(basename $0) [OPTIONS] TARGET [TARGET2] [TARGET3]"
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -p,--powerup"
  echo "            Build whole PowerUp"
  echo "        -d,--dvbs"
  echo "            Build DVBS"
  echo "        -i,--image"
  echo "            Build image"
  echo "        Only one action is permitted"
  echo "    TARGET:"
  echo "        Target build by platform name. Examples are:"
  echo "            humaxwb20     - build charter-humaxwb20-dev"
  echo "            humaxwb20-prd - build charter-humaxwb20-prd"
}

set_action()
{
  [ ${ACTION} -ne 0 ] && (echo "Only one action is permitted"; exit 1)
  ACTION=$1
}

echo_action()
{
  case ${ACTION} in
    ${DO_POWERUP})
      echo -n "PowerUp"
    ;;
    ${DO_DVBS})
      echo -n "DVBS"
    ;;
    ${DO_IMAGE})
      echo -n "image"
    ;;
    *)
      echo -n "@?#?#?@"
    ;;
  esac
}

SHORT_OPTS="hpdi"
LONG_OPTS="help,powerup,dvbs,image"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -p|--powerup)
      set_action ${DO_POWERUP}
    ;;
    -d|--dvbs)
      set_action ${DO_DVBS}
    ;;
    -i|--image)
      set_action ${DO_IMAGE}
    ;;
    --)
      shift
      break
    ;;
    *)
      usage
      exit 1
    ;;
  esac
  shift
done

if [ ${ACTION} -eq 0 ]; then
  usage
  exit 1
fi

while [ -n "$1" ]; do

  TARGET=$1; shift

  if [ -z "${TARGET}" ]; then
    usage
    exit 1
  fi

  target=$(echo ${TARGET} | sed -e 's/\-.*//')
  type=$(echo ${TARGET} | sed -n -e 's/.*\-//p')
  [ -z "${type}" ] && type=dev

  echo "######################################################################"
  echo "###   START: Build $(echo_action) for target ${charter-${target}-${type}}"

  DIR=
  case ${ACTION} in
    ${DO_POWERUP})
      ./01_build_native.sh charter-${target}-${type}
    ;;
    ${DO_DVBS})
      [ -d build/make-wrapper ] && DIR=build/make-wrapper
      [ -d native/apps/DVBS/build/make-wrapper ] && DIR=native/apps/DVBS/build/make-wrapper
      if [ -z "${DIR}" ]; then
        echo "ERROR: Could not find DVBS build/make-wrapper directory"
        exit 1
      fi
      (cd $DIR && ./make.sh charter-${target}-${type})
    ;;
    ${DO_IMAGE})
      [ -d charter-worldbox-images ] && DIR=charter-worldbox-images
      [ -d native/apps/charter-worldbox-images ] && DIR=native/apps/charter-worldbox-images
      if [ -z "${DIR}" ]; then
        echo "ERROR: Could not find DVBS build/make-wrapper directory"
        exit 1
      fi
      (cd ${DIR} && ./make.sh charter-${target}-${type})
    ;;
    *)
      usage
      exit 1
    ;;
  esac
  echo "###   FINISH: Build $(echo_action) for target ${charter-${target}-${type}}"
  echo "######################################################################"
done
