#! /bin/bash

INFILE="${1}"
OUTFILE="${INFILE%.*}.mpd"

avconv -i "${INFILE}" -acodec copy -vcodec copy \
    -f dash \
    -min_seg_duration 2000 \
    -use_template 0 -use_timeline 1 \
    -init_seg_name Head-\$RepresentationID\$.m4s \
    -media_seg_name \$RepresentationID\$-\$Number%05d\$.m4s \
    "${OUTFILE}"
