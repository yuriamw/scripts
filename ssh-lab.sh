#! /bin/bash

port=22
defuser=iurii.ovcharenko
host=ctec

user=

usage()
{
  echo "Usage: $(basename $0) [OPTIONS] HOST"
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -s SERVER,--server=HOST"
  echo "            Server host address to connect to. Default is '$host'"
  echo "        -p PORT,--port=PORT"
  echo "            Port to connect to on the remote host. Default is '$port'"
  echo "        -u USER,--user=USER"
  echo "            User login. Default is '$defuser'"
}

SHORT_OPTS="hs:p:u:"
LONG_OPTS="help,server:,port:,user:"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -s|--server)
      shift
      host="$1"
    ;;
    -p|--port)
      shift
      port="$1"
    ;;
    -u|--user)
      shift
      user="$1"
    ;;
    --)
      shift
      [ -n "$1" ] && host=$1
      break
    ;;
    *)
      usage
      exit 1
    ;;
  esac
  shift
done

if [ -z "$user" ]; then
  case $host in
    ctec)
      user=$defuser
    ;;
    stlouis)
      user=zodiac
    ;;
    *)
      echo "ERROR: Can not guess user name for server: '$host'"
      exit 1
    ;;
  esac
fi

ssh -p ${port} ${user}@${host}
# sudo su -l zodiac
