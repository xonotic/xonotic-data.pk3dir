#!/bin/bash
set -eu
cd "$(dirname "$0")"
cd ..

declare -a NOWARN=(
  -Wno-field-redeclared
  -Wno-unused-variable
  -Wno-implicit-function-pointer
)
declare -a FEATURES=(
  -DVEHICLES_ENABLED=1
  -DVEHICLES_USE_ODE=0
)
declare QCC=../../../gmqcc/gmqcc

declare -a QCC_FLAGS=(
  -std=gmqcc
  -Wall -Werror
  -fftepp -fftepp-predefs -Wcpp
  -futf8
  -freturn-assignments
  -frelaxed-switch
  -O3
)

function check() {
  declare -l base="${1}"
  declare -la predefs=("-D${2}" "lib/_all.inc" "${base}/_all.qh")
  find "$base" -type f -name '*.qc' -print0 | sort -z | while read -r -d '' file; do
    echo "$file"
    ${QCC} "${QCC_FLAGS[@]}" "${NOWARN[@]}" "${FEATURES[@]}" "${predefs[@]}" "$file" >/dev/null
  done
}

check client CSQC
check server SVQC
check menu MENUQC
