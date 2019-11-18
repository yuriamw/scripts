#! /bin/bash

SYSROOT=$(pwd)/out.charter-arrishydra-powerup-prd/linux/sysroot_stripped
CONFIG=platforms/arrishydra/check_symbols.yaml
OUTDIR=$(pwd)/

rm -rf ${OUTDIR}/{check_symbols_result.txt,dependency_tree.db,deps_table.csv}
python ./gn/check_missed_symbols.py \
    --sysroot_stripped_path ${SYSROOT} \
    --config_path ${CONFIG} \
    --report_path ${OUTDIR}/check_symbols_result.txt \
    --database_path ${OUTDIR}/dependency_tree.db \
    --csv_path ${OUTDIR}/deps_table.csv
