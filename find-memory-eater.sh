#! /bin/bash

# does not work as the sort field till the end of line
exit 1

while true ; do
    echo "### PS ###"
    ps auxh | sort -g -r -k5 | head -n 10
    sleep 1
done
