#! /bin/bash

function go-generate-recursive {
    dir="$1"
    [ -z "${dir}" ] && dir="."

    for i in $(find "${dir}" -name go.mod -type f)
    do
        d="$(dirname $i)"
        echo "=== run go generate in: $d"
        (cd $d && go generate -x)
    done
}
