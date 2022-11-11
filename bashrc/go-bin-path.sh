#! /bin/bash

if [ -z "${GOBIN}" ]; then
    go_prog="$(which go)"
    if [ -n "${go_prog}" ]; then
        go_bin=$(${go_prog} env GOBIN)
        if [ -z "${go_bin}" ]; then
            if [ -d ~/go/bin ]; then
                go_bin=~/go/bin
            fi
        fi
        if [ -n "${go_bin}" ]; then
            if [ $(echo "${PATH}" | grep -c "${go_bin}") -eq 0 ]; then
                export PATH=${go_bin}:${PATH}
            fi
        fi
    fi
fi
