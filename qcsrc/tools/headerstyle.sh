#!/usr/bin/env bash
set -eu
cd ${0%/*}
cd ..

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
        echo "$file"
        declare -l file_h="${file%.qc}.qh"
        if [ ! -f "$file_h" ]; then echo "#pragma once" > "$file_h"; fi

        include=$(basename "$file")
        include="${include%.qc}.qh"
        include="#include \"${include}\""
        startswith "$file" "$include"
    done
    find "$base" -type f -name '*.qh' -a \! -name '_mod.qh' -print0 | sort -z | while read -r -d '' file; do
        echo "$file"
        startswith "$file" "#pragma once"
    done
    find "$base" -type f -name '_mod.inc' -print0 | sort -z | while read -r -d '' file; do
        echo "$file"
        declare -l file_inc="${file%_mod.inc}_all.inc"
        if [ ! -f "$file_inc" ]; then
            echo '#include "_all.qh"' > "$file_inc"
            echo '#include "_mod.inc"' >> "$file_inc"
        fi
        declare -l file_qh="${file%_mod.inc}_all.qh"
        if [ ! -f "$file_qh" ]; then
            echo '#pragma once' > "$file_qh"
            echo '#include "_mod.qh"' >> "$file_qh"
        fi
    done
}

check client
check server
check menu

# TODO: check that "_mod.(qc|inc)" is not included except by "_all.(qc|inc)"
