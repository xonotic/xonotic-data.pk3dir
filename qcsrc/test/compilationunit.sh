#!/bin/bash
set -eu
cd "$(dirname "$0")"
cd ..

export QCC=../../../gmqcc/gmqcc

function check() {
  declare -l base="$1"
  declare -la predefs=("${!2}")
  find "$base" -type f -name '*.qc' -print0 | while IFS= read -r -d '' file; do
    echo "$file"
    ${QCC} -std=gmqcc -fftepp ${predefs[@]} "$file" >/dev/null
  done
}

# TODO: `sort -V` all the includes

clientdefs=("-DCSQC" "common/util-pre.qh" "dpdefs/csprogsdefs.qh")
check client clientdefs[@]
