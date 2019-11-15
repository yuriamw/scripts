#! /bin/bash

SYSROOT=out.charter-arrishydra-powerup-tst/linux/sysroot_stripped
CONFIG=platforms/arrishydra/check_symbols.yaml
OUTDIR=./

python ./gn/check_missed_symbols.py \
    --sysroot_stripped_path ${SYSROOT} \
    --config_path ${CONFIG} \
    --report_path ${OUTDIR}/check_symbols_result.txt \
    --database_path ${OUTDIR}/dependency_tree.db \
    --csv_path ${OUTDIR}/deps_table.csv \
