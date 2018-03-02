#! /bin/bash

FTP_SERVER=ftp://ftp.developonbox.ru
FTP_BASEDIR=common/SCM/builds/charter/worldbox

USER=build
PASSWD=f1LSpx8aYR

SUPPORTED_PLATFORMS="arriswb20 humaxwb11 humaxwb20 tchwb11 tchwb20"
SUPPORTED_BUILD_TYPES="dev prd"

FTP_PLATFORM_BASE=CHARTER_WB
PLATFORM=
FTP_BRANCH=
BUILD_ID=
BUILD_TYPE=

function usage() {
  echo "Usage: $(basename $0) [OPTIONS]"
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -b,--build"
  echo "            Build number"
  echo "        -t,--type"
  echo "            Build type."
  echo "            Supported build types: ${SUPPORTED_BUILD_TYPES}"
  echo "        -p,--platform"
  echo "            Platform name."
  echo "            Supported platforms: all ${SUPPORTED_PLATFORMS}"
  echo "            Multiple platfroms can be set by repeating this option"
  echo "        -r,--branch"
  echo "            Branch name. Example: TRUNK"
}

SHORT_OPTS="hb:t:p:r:"
LONG_OPTS="help,build:,type:,platform:,branch:"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

PLATFORM_CMDLINE=
while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -b|--build)
      shift
      BUILD_ID=${1}
    ;;
    -t|--type)
      shift
      BUILD_TYPE=${1}
    ;;
    -p|--platform)
      shift
      PLATFORM_CMDLINE="${PLATFORM_CMDLINE} ${1}"
    ;;
    -r|--branch)
      shift
      FTP_BRANCH=${1}
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

if [ -z "${PLATFORM_CMDLINE}" ]; then
  echo "ERR: Platform is not specified"
  exit 1
fi
if [ -z "${FTP_BRANCH}" ]; then
  echo "ERR: Branch is not specified"
  exit 1
fi
if [ -z "${BUILD_ID}" ]; then
  echo "ERR: Build is not specified"
  exit 1
fi
if [ -z "${BUILD_TYPE}" ]; then
  echo "ERR: Build type is not specified"
  exit 1
fi

PLATFORM_TO_FETCH=
for pl in ${PLATFORM_CMDLINE}; do
  if [ $(echo "all ${SUPPORTED_PLATFORMS}" | grep -c ${pl}) -ne 1 ]; then
    echo "ERR: Platform ${pl} is not supported"
    exit 1
  fi
done
if [ $(echo ${PLATFORM_CMDLINE} | grep -c all) -gt 0 ]; then
  PLATFORM_TO_FETCH="${SUPPORTED_PLATFORMS}"
else
  for pl in ${PLATFORM_CMDLINE}; do
    if [ $(echo "${PLATFORM_TO_FETCH}" | grep -c "${pl}") -eq 0 ]; then
      PLATFORM_TO_FETCH="${PLATFORM_TO_FETCH} ${pl}"
    fi
  done
fi

BUILD_PATTERN=
case ${BUILD_TYPE} in
  dev)
    BUILD_PATTERN=SLG
  ;;
  prd)
    BUILD_PATTERN=SRU
  ;;
  *)
    echo "ERR: Invalid BUILD_TYPE: ${BUILD_TYPE}"
    exit 1
  ;;
esac

###############################################################################

function convert_platform_to_ftp_dir() {
  local platform=$(echo ${1} | tr '[:lower:]' '[:upper:]')
  local len=$((${#platform}-1))
  local platform_dir=${platform::$len}.${platform:$len:1}
  echo ${platform_dir}
}

function find_rootfs_file() {
  local declare ftp_file_list
  local pattern=${1}
  rootfs_count=0
  ftp_file_list=($(curl -u ${USER}:${PASSWD} --list-only ${FTP_URL}/${BUILD_TYPE}/))
  for ((i=0;i<${#ftp_file_list[@]};i++)); do
    if [ $(echo "${ftp_file_list[$i]}" | grep -c ${pattern}.rootfs.zip) -ne 0 ]; then
      ROOTFS_FILE="${ftp_file_list[$i]}"
      echo "INF: Found rootfs file: ${ROOTFS_FILE}"
      rootfs_count=$((rootfs_count+1))
  #     break
    fi
  done
}

function download_file() {
  local url=${1}
  local outfile=${2}
  echo "INF: Downloading ${url} into ${outfile}"
  rm -f ${outfile}
  curl -u ${USER}:${PASSWD} -o ${outfile} ${url}
}

###############################################################################

echo "Platforms: ${PLATFORM_TO_FETCH}"
echo "Build: ${BUILD_ID} Type: ${BUILD_TYPE} Pattern: ${BUILD_PATTERN}"

for PLATFORM in ${PLATFORM_TO_FETCH}; do
  echo "======================================================================="
  echo "===   PLATFORM: ${PLATFORM}"

  IMAGE_INSTALL_FILE=image_install-${BUILD_TYPE}.zip
  ROOTFS_FILE=
  rootfs_count=0

  mkdir -p ${PLATFORM}

  FTP_PLATFORM="$(convert_platform_to_ftp_dir ${PLATFORM})"
  FTP_PLATFORM_DIR=${FTP_PLATFORM_BASE}_${FTP_PLATFORM}_${FTP_BRANCH}
  FTP_URL=${FTP_SERVER}/${FTP_BASEDIR}/${FTP_PLATFORM_DIR}/${BUILD_ID}

  find_rootfs_file ${BUILD_PATTERN}

  if [ -n "${IMAGE_INSTALL_FILE}" ]; then
    download_file ${FTP_URL}/${IMAGE_INSTALL_FILE} ${PLATFORM}/${IMAGE_INSTALL_FILE}
  fi
  rm -rf ${PLATFORM}/${BUILD_TYPE}
  mkdir -p ${PLATFORM}/${BUILD_TYPE}
  unzip ${PLATFORM}/${IMAGE_INSTALL_FILE} -d ${PLATFORM}/${BUILD_TYPE}

  if [ $rootfs_count -gt 1 ]; then
    echo "WRN: rootfs_count=${rootfs_count}"
  fi
  if [ -n "${ROOTFS_FILE}" ]; then
    VERSION=$(basename ${ROOTFS_FILE} .rootfs.zip)
    VERSION_FILE=${PLATFORM}/${BUILD_TYPE}/home/zodiac/version.txt
    echo "INF: version.txt: ${VERSION}"
    echo ${VERSION} > ${VERSION_FILE}
  fi

  echo "======================================================================="
done
