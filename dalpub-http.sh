#! /bin/bash -e

usage()
{
  echo "Usage: $(basename $0) <GROUP_DIR> <DAL_PACKAGE>"
  echo "    Prepare the group tree for HTTP boot"
  echo "    Example:"
  echo "    $(basename $0) ArrisWB/0 PCI_spectrum100A_chr_104_1102021E_0421_SLG.dal_package.zip"
}

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

CWD=$(pwd)
DALGROUP=$1
DALPACK=$2
DALREMOVE="DALManager DALManager.unsigned Package.unsigned"
DALINCLUDE="Package section.txt version.txt"
DALSUBDIR=Package
DALGROUPCFG=$DALSUBDIR/group.cfg

SRVHOST=172.30.140.246
SRVBASE=WB_DCD
SRVURL=http://$SRVHOST/$SRVBASE/$DALGROUP/Package

if [ ! -f $DALPACK ]; then
  echo "ERROR: Package '$DALPACK' does not exist"
  exit 1
fi

DALPACK=$(readlink -f $DALPACK)
TMP=$(mktemp -d)

pushd $TMP
  unzip $DALPACK
  rm -rf $DALREMOVE
  sed -e "s#etv://.f=<FREQUENCY>.<PID>.m=QAM256#$SRVURL#" -i $DALGROUPCFG
  cp -a $DALINCLUDE $CWD/
popd

rm -rf $TMP
