#!/usr/bin/env bash
set -eu
cd ${0%/*}
cd ..

VERBOSE=${VERBOSE:-1}

function startswith() {
    declare -l file="${1}"
    declare -l prelude="${2}"
    declare -l line=$(head -n1 "$file")
    if [ "$line" != "$prelude" ]; then
        echo "$prelude" | cat - "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
}

function check() {
    declare -l base="${1}"
    find "$base" -type f -name '*.qc' -print0 | sort -z | while read -r -d '' file; do
        [ "$VERBOSE" != "0" ] && echo "$file"
        declare -l file_h="${file%.qc}.qh"
        if [[ ! -f "$file_h" ]]; then echo "#pragma once" > "$file_h"; fi

        include=$(basename "$file")
        include="${include%.qc}.qh"
        include="#include \"${include}\""
        startswith "$file" "$include"
    done
    find "$base" -type f -name '*.qh' -a \! -name '_mod.qh' -print0 | sort -z | while read -r -d '' file; do
        [ "$VERBOSE" != "0" ] && echo "$file"
        startswith "$file" "#pragma once"
    done
}

check client
check server
check menu
check common
