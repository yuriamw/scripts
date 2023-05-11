#! /bin/bash

dir="$1"
upperdir="../../${dir}"
tmp="/tmp/konsole.tabs"
trap 'rm -f -- "${tmp}"' EXIT

cat << EOF > "${tmp}"
title: %d : %n;; workdir: ${upperdir};; profile: Profile 1
title: %d : %n;; workdir: ${dir};;      profile: Profile 1
title: %d : %n;; workdir: ${dir};;      profile: Profile 1
title: %d : %n;; workdir: ${dir};;      profile: Profile 1
EOF

exec konsole --tabs-from-file "${tmp}" 2>/dev/null &
