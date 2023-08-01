#! /bin/bash

secrets=()

if [ -f "$1" ]; then
    secrets=( $(cat "$1") )
else
    secrets=("$1")
fi

collection=$(jq -n)

for r in CS23-*; do

    repo=$(jq -n --arg repository "$r" --argjson secrets '[]' '$ARGS.named')

    for t in ${secrets[@]}; do
        pushd $r >/dev/null

        branches=( $(git branch -la | sed -n -e 's/remotes\///p' | sed -e 's/.*HEAD.*//') )

        br=$(jq -n '[]')
        for b in ${branches[@]}; do
            f=$(git grep -n "${t}" "$b" | sed -e 's/\:\s.*//')
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
            list=$(jq -n --arg "secret" "$t" --argjson branches "[ ${br} ]" '$ARGS.named')
            repo=$( echo "${repo}" | jq ".secrets += [ ${list} ]" )
        fi

        popd >/dev/null
    done

    collection=$( echo "${collection}" | jq ". += [ ${repo} ]" )

done

echo "${collection}"
