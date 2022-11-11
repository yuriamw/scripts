#! /bin/bash

function go-mod-tidy-recursive {
    dir="$1"
    [ -z "${dir}" ] && dir="."

    for i in $(find "${dir}" -name go.mod -type f)
    do
        d="$(dirname $i)"
        echo $d
        (cd $d && go mod tidy)
    done

}
