#! /bin/bash -e

export LC_ALL=C

defoutform=image
basedir=.
platform=
cpu=arm
buildtype=dev
server=ctec
user=$USER
path=/home/$USER
port=22
skip=0
withdirs=0
skipnfs=0
mso=charter

supported_outforms="image powerup valhalla"

DO_POWERUP=0
DO_IMAGE=0
DO_VALHALLA=0

usage()
{
  echo "Usage: $(basename $0) [OPTIONS]"
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -f OUTFORM,--out-form=OUTFORM"
  echo "            Create archive for output form OUTFORM. Default is '$defoutform'"
  echo "            This option can be repeated to generate multiple output forms."
  echo "            Currently supported output forms: $supported_outforms."
  echo "        -b DIR,--base-dir=DIR"
  echo "            Use DIR as a base directory to find build output products. Default is '$basedir'"
  echo "        -p PLATFORM,--platform=PLATFORM"
  echo "            Search for build products for PLATFORM"
  echo "        -c CPU,--cpu=CPU"
  echo "            Search for build products for CPU. Default is '$cpu'"
  echo "        -t BUILDTYPE,--build-type=BUILDTYPE"
  echo "            Search for BUILDTYPE build products. Default is '$buildtype'"
  echo "        -s SERVER,--server=SERVER"
  echo "            Upload build products to SERVER. Default is '$server'"
  echo "        -a PATH,--path=PATH"
  echo "            Upload build products to PATH directory on server. Default is '$path'"
  echo "        -r PORT,--port=PORT"
  echo "            Upload build products to SERVER. Default is '$port'"
  echo "        -u USER,--user=USER"
  echo "            Use USER name for for scp auth. Default is '$user'"
  echo "        -U USER,--user-with-dirs=USER"
  echo "            Use USER name for for scp auth. Default is '$user'"
  echo "            Store files at /home/USER/PLATFORM subdirectory on the server"
  echo "            This is the same as -u USER -a /home/USER/PLATFORM"
  echo "        --skip"
  echo "            Do not upload files to the server."
  echo "        -n,--skip-nfs"
  echo "            Use USER name for for scp auth. Default is '$user'"
}

check_outform()
{
  local outf
  for outf in $supported_outforms; do
    if [ $outf == $1 ]; then
      echo $1
      return
    fi
  done
}

SHORT_OPTS="hb:p:c:t:s:a:r:u:f:U:n"
LONG_OPTS="help,base-dir:,platform:,cpu:,build-type:,server:,path:,port,user:out-form:,user-with-dirs:,skip-nfs,skip"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -f|--out-form)
      shift
      outform="$outform $1"
    ;;
    -b|--base-dir)
      shift
      basedir="$1"
    ;;
    -p|--platform)
      shift
      platform="$1"
    ;;
    -c|--cpu)
      shift
      cpu="$1"
    ;;
    -t|--build-type)
      shift
      buildtype="$1"
    ;;
    -s|--server)
      shift
      server="$1"
    ;;
    -a|--path)
      shift
      path="$1"
    ;;
    -r|--port)
      shift
      port="$1"
    ;;
    -u|--user)
      shift
      user="$1"
    ;;
    -U|--user-with-dirs)
      shift
      user="$1"
      withdirs=1
    ;;
    -n|--skip-nfs)
      shift
      skipnfs=1
    ;;
    --skip)
      shift
      skip=1
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

if [ -z "$platform" ]; then
  echo "ERROR: platform is not speified"
  exit 1
fi

TARGET="$platform-$cpu-$mso"
BUILD_TYPE=$buildtype

WORKDIR=$(mktemp -d)
TAR_BASE=$platform-$buildtype
PROJ_BASE=${basedir}

SRV=${user}@${server}
SRVPORT="-P $port"

if [ ${withdirs} -eq 1 ]; then
  path=/home/${user}/${platform}
fi
SRVDIR=$path

[ -z "$outform" ] && outform=$defoutform

current_outforms=
outform=$(echo "$outform" | tr ' ' '\n'| sort | uniq | tr '\n' ' ')
for i in $outform; do
  if [ -n "$(check_outform $i)" ]; then
    current_outforms="$current_outforms $i"
    eval DO_$(echo $i | tr '[:lower:]' '[:upper:]')=1
  else
    echo "ERROR: Unknown output form: '$i'"
    exit 1
  fi
done

echo "Output form: $current_outforms"
echo "Directory:   $PROJ_BASE"
echo "Build type:  $BUILD_TYPE"

if [ $DO_POWERUP -eq 1 ]; then
  echo "Target:      $TARGET"
  PRJDIR=${PROJ_BASE}/native/output/${TARGET}/${BUILD_TYPE}
  if [ -d ${PRJDIR} ]; then
    TAR=${TAR_BASE}.tar.bz2
    rm -rf ${WORKDIR}/usr
    rm -rf ${WORKDIR}/symbols
    rm -rf ${WORKDIR}/${TAR}
    mkdir -p ${WORKDIR}/usr/{bin,lib}
    mkdir -p ${WORKDIR}/symbols
    echo -n "Searching for binary files for ${TARGET} ... "
    cp -a `find ${PRJDIR} -type f -a -executable -a ! -name *.so* -a ! -name *.dbg` ${WORKDIR}/usr/bin/
    cp -a `find ${PRJDIR} \( -name *.so -o -name *.so.[0-9]* \) -a ! -name *.dbg -a ! -name *.sym` ${WORKDIR}/usr/lib/
    echo "Done"
    echo -n "Searching for symbol files for ${TARGET} ... "
    for sym in ${PRJDIR}/*.sym; do
      hash=$(head -n 1 $sym | cut -f4 -d' ')
      fname=$(basename $sym .sym)
      mkdir -p ${WORKDIR}/symbols/${fname}/${hash}
      cp -a $sym ${WORKDIR}/symbols/${fname}/${hash}/
    done
    echo "Done"
    echo -n "Creating tarball ... "
    pushd ${WORKDIR} > /dev/null
      tar -jc usr symbols -f ${TAR}
    popd  > /dev/null
    echo "Done"
    if [ $skip -ne 1 ]; then
      echo "scp to ${SRV}:${SRVDIR} ... "
      scp ${SRVPORT} ${WORKDIR}/${TAR} ${SRV}:${SRVDIR}
    else
      echo "cp to current dir: $(pwd) ... "
      cp ${WORKDIR}/${TAR} ./
    fi
  else
    echo "Nothing to do for '$TARGET'"
  fi
fi

if [ $DO_IMAGE -eq 1 ]; then
  echo "Target:      $TARGET"
  PRJDIR=${PROJ_BASE}/native/output-images/${TARGET}
  rm -rf ${WORKDIR}
  mkdir -p ${WORKDIR}
  # Technicolor SAO
  sao_name=squashfs.sao
  sao="$(ls $PRJDIR/${BUILD_TYPE}/*.sao | grep -v [0-9].sao | tail -n 1)"
  if [ -f "$sao" ]; then echo "Copy $sao"; cp -f $sao $WORKDIR/$sao_name; fi
  # Humax vmlinuz-initrd
  vmli_name=vmlinuz-initrd
  vmli="$(ls $PRJDIR/${BUILD_TYPE}/*.${vmli_name} | grep -v [0-9].${vmli_name} | tail -n 1)"
  if [ -f "$vmli" ]; then echo "Copy $vmli"; cp -f $vmli $WORKDIR/$vmli_name; fi
  # Arris PKG
  pkg_name=vmlinuz-initrd.pkg.charter
  pkg="$(ls $PRJDIR/${BUILD_TYPE}/*.charter | grep -v [0-9].charter | tail -n 1)"
  if [ -f "$pkg" ]; then echo "Copy $pkg"; cp -f $pkg $WORKDIR/$pkg_name; fi
  # NFS
  if [ $skipnfs -ne 1 ]; then
    nfm_name=nfs_image-${BUILD_TYPE}.zip
    nfm=$PRJDIR/$nfm_name
    [ -f "$nfm" ] && cp -f $nfm $WORKDIR/$nfm_name
  fi
  if [ $skip -ne 1 ]; then
    echo "scp to ${SRV}:${SRVDIR} ... "
    scp ${SRVPORT} ${WORKDIR}/* ${SRV}:${SRVDIR}
  else
    echo "cp to current dir: $(pwd) ... "
    cp ${WORKDIR}/* ./
  fi
fi

if [ $DO_VALHALLA -eq 1 ]; then
  echo "Target:      ${mso}-${platform}"
  PRJDIR=${PROJ_BASE}/out.${mso}-${platform}/artifacts
  transfer_files=""
  rm -rf ${WORKDIR}
  mkdir -p ${WORKDIR}
  # Humax vmlinuz_initrd
  vmli_name=vmlinuz_initrd
  vmli_name_out=valhalla.vml-IO
  vmli="$(ls -t $PRJDIR/*.${vmli_name} | head -n 1)"
  if [ -f "$vmli" ]; then echo "Copy $vmli"; cp -f $vmli $WORKDIR/$vmli_name_out; transfer_files="$transfer_files $WORKDIR/$vmli_name_out"; fi
  # NFS
  if [ $skipnfs -ne 1 ]; then
    nfm_name="nfs_image-${BUILD_TYPE}*.zip"
    nfm_name_out="nfs_image-${BUILD_TYPE}.zip"
    nfm="$(ls -t $PRJDIR/$nfm_name | head -n 1)"
    if [ -f "$nfm" ]; then echo "Copy $nfm"; cp -f $nfm $WORKDIR/$nfm_name_out; transfer_files="$transfer_files $WORKDIR/$nfm_name_out"; fi
  fi
  # Transfer
  if [ $skip -ne 1 ]; then
    echo "scp to ${SRV}:${SRVDIR} ... "
    scp ${SRVPORT} ${transfer_files} ${SRV}:${SRVDIR}
  else
    echo "cp to current dir: $(pwd) ... "
    cp ${transfer_files} ./
  fi
fi

rm -rf ${WORKDIR}
date
exit 0

# DO_DVBS=0
# DO_SAO=0
#
# SRVTFTPDIR=/tftpboot/arriswb
#
# DVBS_DIR=${basedir}/native/apps/DVBS
# DVBS_NAME=DVBS-charter-arris-worldbox-multi-dbg
# DVBS_TAR=${DVBS_NAME}.tar.bz2
# DVBS_ADLIBS="libdisk_storage.so libudev.so"
#
# if [ $DO_DVBS -eq 1 ]; then
#   if [ -d ${DVBS_DIR}/${DVBS_NAME} ]; then
#     rm -rf ${DVBS_NAME}
#     echo -n "Copying files from ${DVBS_DIR}/${DVBS_NAME} ..."
#     cp -a ${DVBS_DIR}/${DVBS_NAME} ./
#     echo "Done"
#     echo -n "Removing configs..."
#     rm -fv ${DVBS_NAME}/*.yaml
#     rm -fv ${DVBS_NAME}/*.cfg
#     rm -fv ${DVBS_NAME}/*.conf
#     echo "Done"
#     echo -n "Copying extra libs ${DVBS_ADLIBS} ..."
#     for l in ${DVBS_ADLIBS}; do
#       cp ${PROJ_BASE}/native/output/${TARGET}/${BUILD_TYPE}/${l} ${DVBS_NAME}/
#     done
#     echo "Done"
#     echo -n "Creating tarball..."
#     tar -cjf ${DVBS_TAR} ${DVBS_NAME}
#     echo "Done"
#     scp ${SRVPORT} ${WORKDIR}/${DVBS_TAR} ${SRV}:${SRVDIR}
#   fi
# fi
#
# if [ $DO_SAO -eq 1 ]; then
#   IMAGE_TYPE="sao sao-nfs"
#   IMAGEDIR=${basedir}/build/export
#   if [ -d ${IMAGEDIR} ]; then
#     for img in ${IMAGE_TYPE}; do
#       IMAGE="arris-*.$img"
#       for i in ${IMAGEDIR}/${IMAGE}; do
#         t="`echo $i | sed -e 's/.*\.sao/sao/'`"
#         scp ${SRVPORT} ${i} ${SRV}:${SRVTFTPDIR}/`basename $t`
#       done
#     done
#     ROOTFS="`ls -1 ${IMAGEDIR}/arris-*-rootfs.tar.bz2`"
#     scp ${SRVPORT} ${ROOTFS} ${SRV}:${SRVDIR}/rootfs.tar.bz2
#   else
#     echo "Nothing to do for '$i'"
#   fi
# fi
