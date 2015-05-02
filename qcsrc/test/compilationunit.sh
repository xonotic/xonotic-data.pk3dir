#!/bin/bash
set -eu
cd "$(dirname "$0")"
cd ..

declare QCC=../../../gmqcc/gmqcc

function check() {
  declare -l base="$1"
  declare -la predefs=("${!2}")
  find "$base" -type f -name '*.qc' -print0 | sort -z | while IFS= read -r -d '' file; do
    echo "$file"
    ${QCC} -std=gmqcc -fftepp -fftepp-predefs -futf8 -O3 "${predefs[@]}" "$file" >/dev/null
  done
}

clientdefs=("-DCSQC" "common/util-pre.qh" "dpdefs/csprogsdefs.qh")
check client clientdefs[@]
