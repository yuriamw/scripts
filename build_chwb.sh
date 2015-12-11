#!/bin/bash

#------------------------------------------------------------------------------
#   $Id$
#   Version control interface for Zodiac solutions.
#   Created by Mikhail Yurovskiy 12-Feb-2013
#   Copyright (C) 2013 Zodiac Interactive, LLC
#------------------------------------------------------------------------------

# Type ./vcs.sh without parameters to get help.

#CURRENT_DIR="`dirname \"$0\"`"
#TOOLS_DIR=$CURRENT_DIR/native/SDK/Devkit/tools

#if [ "$1" == "" ] ; then
#    perl $TOOLS_DIR/vcs.pl
#elif [ "$1" == "selfupdated" ] ; then
#    echo Self-update is finished.
#    rm -f __tmp__.sh
#    perl $TOOLS_DIR/vcs.pl $2
#else
#    echo Performing self-update...
#    echo "#!/bin/bash" >__tmp__.sh
#    echo "svn update" >>__tmp__.sh
#    echo "chmod +x $0" >>__tmp__.sh
#    echo "exec bash $0 selfupdated $1" >>__tmp__.sh
#    exec bash __tmp__.sh $1
#fi

cur_dir=`pwd`
work_root_dir="/home/work/CHARTER_WORLDBOX/CHARTER_WORLDBOX"
work_build_dir=$work_root_dir/native/apps
work_result_dir=$work_root_dir/native

clean_build() {
cd $work_result_dir
rm -rf ./build
rm -rf ./libs
rm -rf ./output
rm -rf ./output-launcher
cd $work_build_dir/DVBS
git clean -fxd
cd $work_build_dir/DiskStorage
git clean -fxd
cd $work_build_dir/Udev
git clean -fxd
cd $cur_dir
}

update_repo() {
cd $work_root_dir
./vcs.sh update
cd $cur_dir
}

build_repo() {
cd $work_build_dir
./make.sh charter-humaxwb
#./make.sh charter-humaxwb-dev
#./make.sh charter-waiverbox2
#./make.sh charter-waiverbox
cd $work_result_dir
if [ -d ./output/humaxwb-mips-charter/dev ] ; then
echo "create dev archive"
cp -R ./output/humaxwb-mips-charter/dev $cur_dir
cd $cur_dir/dev
rm *.map
rm *.dbg
rm *.sym
#rm *.a
#cd ../
#tar -cvjf $cur_dir/dev.tar.bz2 ./dev
mkdir -p ./usr/bin
mkdir -p ./usr/lib
mv *.so* ./usr/lib/
#mv DALManager dpi_host_app ncas_host_app ntpclient powerup-launcher sdvd supervisor ata_id udevd ./usr/bin/
mv DALManager dpi_host_app ncas_host_app powerup-launcher sdvd supervisor ata_id udevd ./usr/bin/
tar -cvjf $cur_dir/dev.tar.bz2 .
cd $cur_dir
rm -rf ./dev
else
cd $cur_dir
fi

cd $work_result_dir
if [ -d ./output/humaxwb-mips-charter/prd ] ; then
echo "create prd archive"
cp -R ./output/humaxwb-mips-charter/prd $cur_dir
cd $cur_dir/prd
rm *.map
rm *.dbg
rm *.sym
#rm *.a
mkdir -p ./usr/bin
mkdir -p ./usr/lib
mv *.so* ./usr/lib/
mv DALManager dpi_host_app ncas_host_app powerup-launcher sdvd supervisor ata_id udevd ./usr/bin/
tar -cvjf $cur_dir/prd.tar.bz2 .
cd $cur_dir
rm -rf ./prd
else
cd $cur_dir
fi

}

#echo  num $#

if [ "$1" == "clean" ] ; then
  clean_build
fi

if [ "$2" == "clean" ] ; then
  clean_build
fi

if [ "$1" == "up" ] ; then
  update_repo
fi

if [ "$2" == "up" ] ; then
  update_repo
fi

if [ "$2" == "nobuild" ] ; then
  echo "skip build"
else
  if [ "$3" == "nobuild" ] ; then
    echo "skip build"
  else
    build_repo
  fi
fi
