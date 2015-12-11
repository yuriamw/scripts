#! /bin/bash -e

filename="$1"
outdir="$(pwd)"

if [ ! -f "${filename}" ]; then
  echo "Usage: $(basename $0) FILE.mib"
  exit 1
fi
dirname="$(basename ${filename})-split"

OID=
OWNER=

rm -rf

mkdir -p "${outdir}/${dirname}"
tmp=$(mktemp -d -p "${outdir}")

cat "${filename}" | sed -n -e 's/OBJECT-TYPE$/TYPE/p' -e 's/Owner://p' | sed -e 's/"//' | sed -e 's/ */ /' | sed -e ':a;N;$!ba;s/TYPE\n/ /g' | \
while read OID OWNER; do
  of=$(echo ${OWNER} | tr [:upper:] [:lower:])
  echo $OID >> "${tmp}/mib-${of}.txt"
done

cp -f "${tmp}"/mib-*.txt "${outdir}/${dirname}/"
rm -rf "${tmp}"
