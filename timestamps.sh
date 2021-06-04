#! /bin/bash

export LANG=C
export LC_TIME=C

# config=charter-humaxwb20-powerup-tst
config=tmnl-humaxwb20-sfw-tst

# See http://www.graphviz.org/doc/info/output.html
#
# gvout=ps
# gvout=pdf
# gvout=svg
# gvout=svgz
# gvout=pcl
gvout=png

date="$(date '+%Y-%m-%d_%H-%M-%S')"
logdir="../bug/INT2122-540-incremental"
logfile="${logdir}/build-timestamp-${date}-${config}".log
gvfile="${logdir}/$(basename ${logfile} .log)".dot
outfile="${logdir}/$(basename ${gvfile} .dot)".${gvout}

mode="-d explain"
# Next is VERY time consuming (hours or even days)
# I've been waiting for 24 hours, but I didn’t get the result
# mode="-t graph"
# digraph ninja {
#     blah
#     blah
#     blah
# }

FILES=(
#     out.${config}/gen/components/vbs/libs/dvbs-server/*.stamp
#     out.${config}/obj/components/vbs/dvbs/src/platform/local/core.NetworkServiceImpl.o
    out.${config}/gen/components/common_utils/*.stamp
    out.${config}/obj/components/common_utils/src/logger/logger.TcpOutput.o
    out.${config}/artifacts/PCI_Spectrum110-H_chr_*_SLG.vmlinuz_initrd
)

./gnb configs/${config}.yaml -- ${mode} | tee -a ${logfile}

ls -l ${FILES[*]} | tee -a ${logfile}

if [ "${mode}" = "-t graph" ]; then
    echo "Plot a graph ..."
    sed -n -e '/digraph ninja {/,/}/p' ${logfile} > ${gvfile}
    dot -T${gvout} ${gvfile} -o ${outfile}
    echo "Done"
fi
