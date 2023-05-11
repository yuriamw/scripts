#! /bin/bash

dir="$1"
[ -z "${dir}" ] && dir="."

for i in $(find ${dir} -type f -name "*.go"); do
    pkg=$(basename $(dirname $i) )
    sed -i -e "1 s/package.*/package ${pkg}/" $i
    case $i in
        *_test.go)
            continue
        ;;
    esac
    sed -i -z "s/\n)[^\n]*\n/\0\nconst (\n\tpkgName=\"${pkg}\"\n)\n/1" $i
done
