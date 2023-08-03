#! /bin/bash

searchterms=()
searchdirs=()

exec 3>&1

usage()
{
    echo "Usage: $(basename $0) [OPTIONS] [DIR1] [DIR2] [...]"
    echo "    Search for terms in git local copies recurcievely:"
    echo "    [DIR1] [DIR2] [...] is a list of directoryes with git local copies."
    echo "    If list of directories is omited then curren directory is used."
    echo "    Options:"
    echo "        -h,--help"
    echo "            Print help and exit"
    echo "        -s SERACHTERM,--search=SERACHTERM"
    echo "            Search for term SERACHTERM."
    echo "            Could be used multiple times."
    echo "        -f FILE,--file=FILE"
    echo "            Read search terms from FILE."
    echo "            File shall contains the one term per line."
    echo "            Could be used multiple times."
    echo "        -o OUTPUT,--output=OUTPUT"
    echo "            Put the output to file OUTPUT. Default is stdout."
}

SHORT_OPTS="hs:f:o:"
LONG_OPTS="help,search:,file:,output:"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
        ;;
        -s|--search)
            shift
            searchterms=( "${searchterms[@]}"  "$1")
        ;;
        -f|--file)
            shift
            old="${IFS}"
            IFS=""
            while IFS= read -r line; do
                searchterms=( "${searchterms[@]}"  "${line}")
            done < "$1"
            IFS="${old}"
        ;;
        -d|--dir)
            shift
            searchdirs=("${searchdirs[@]}" "$1" )
        ;;
        -o|--output)
            shift
            exec 3>"$1"
        ;;
        --)
        break
        ;;
        *)
            usage
            exit 1
        ;;
    esac
    shift
done

shift
while [ $# -gt 0 ]; do
    searchdirs=("${searchdirs[@]}" "$1" )
    shift
done
[ ${#searchdirs[@]} -eq 0 ] && searchdirs=("${searchdirs[@]}" "." )

collection=$(jq -n)

for r in ${searchdirs[@]}; do
    repo=$(jq -n --arg repository "$r" --argjson results '[]' '$ARGS.named')

    for t in ${searchterms[@]}; do
        pushd $r >/dev/null

        branches=( $(git branch -lr | sed -e '/.*HEAD.*/d') )

        br=$(jq -n '[]')
        for b in ${branches[@]}; do
            f=$(git grep -na "${t}" "$b"  | cut -f'-3' -d':')
            if [ -z "$f" ]; then
                continue
            fi

            a=()
            for e in $f; do

                a=( $(echo "$e" | sed -e 's/\:/ /g') )
                if [ ${#a[@]} -ne 3 ]; then
                    echo "ERROR: can not parse"
                    echo "'$f'"
                    exit 1
                fi

                elem=$(jq -n --arg branch ${a[0]}  --arg file ${a[1]}  --arg line ${a[2]} '$ARGS.named')
                br=$(echo ${br} | jq ". +=  [ ${elem} ]")
            done

        done

        count=$(echo ${br} | jq '. | length')
        if [ $count -gt 0 ]; then
            list=$(jq -n --arg "searchTerm" "$t" --argjson branches "[ ${br} ]" '$ARGS.named')
            repo=$( echo "${repo}" | jq ".results += [ ${list} ]" )
        fi

        popd >/dev/null
    done

    collection=$( echo "${collection}" | jq ". += [ ${repo} ]" )

done

echo "${collection}" >&3
