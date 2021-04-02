#! /bin/bash

while true ; do
    echo ""
    echo ""
    echo "### PS ###"
    ps -axh -o 'pid,vsz,rss,comm,args' | sort -g -r -k3,3 | head -n 3
    echo ""
    echo ""
    sleep 1
done
