#!/usr/bin/env bash
set -eu
cd ${0%/*}
cd ..

function hash() {
    git hash-object $1
}

function check() {
    declare -l base="${1}"
    # strip trailing spaces
    STRIP_TRAILING_WS='s/[[:space:]]\+$//'
    # line feed at EOF for #include to work properly
    ENSURE_EOFLF='$a\'
    find "$base" -type f -print0 | sort -z | while read -r -d '' file; do
        oldHash=$(hash ${file})
        oldTime=$(stat -c "%Y" ${file})
        sed -i -e ${STRIP_TRAILING_WS} -e ${ENSURE_EOFLF} ${file}
        newHash=$(hash ${file})
        if [[ $newHash == $oldHash ]]; then touch -d @$oldTime ${file}; fi
    done
}

check lib
check common
check ecs
check client
check server
check menu
