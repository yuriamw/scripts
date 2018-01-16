#! /bin/bash

status="EX1"
CRC="356B4B5C"
echo -n "Input your exchange e-mail address: "
read email
echo -n "Input license expired date (YYYY-MM-DD): "
read exdate
mdhash=$(echo -n $status,$email,$exdate,$CRC | md5sum | awk '{print $1}')
echo " ------------------"
echo "| You license key: |"
echo " ------------------"
echo $status,$email,$exdate,$mdhash
echo
read -sn1 -p "Press any key to exit..."; echo
