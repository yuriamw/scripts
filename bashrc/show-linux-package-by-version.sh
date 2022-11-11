#! /bin/bash

function show-linux-package-by-version() {
    pkgver="$1"
    if [ -z "$pkgver" ]; then
        echo "Version is missing"
        return
    fi

    dpkg -l linux-* | sed -n -e /$pkgver/p | sed -e s/^..\ *// | sed -e s/\ .*//
}
