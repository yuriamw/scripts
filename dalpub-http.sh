#! /bin/bash -e

usage()
{
  echo "Usage: $(basename $0) <GROUP_ID> <DAL_PACKAGE>"
  echo "    Prepare the group tree for HTTP boot"
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
SRVBASE=WB_DCD/CiscoWB
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
