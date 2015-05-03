#!/bin/bash
set -eu
cd "$(dirname "$0")"
cd ..

declare -a NOWARN=(
  '-Wno-field-redeclared'
  '-Wno-unused-variable'
  '-Wno-implicit-function-pointer'
)
declare -a FEATURES=(
  '-DVEHICLES_ENABLED=1'
  '-DVEHICLES_USE_ODE=0'
)
declare QCC=../../../gmqcc/gmqcc

function check() {
  declare -l base="$1"
  declare -la predefs=("${!2}")
  find "$base" -type f -name '*.qc' -print0 | sort -z | while IFS= read -r -d '' file; do
    echo "$file"
    ${QCC} -std=gmqcc -fftepp -fftepp-predefs -Werror -Wall "${NOWARN[@]}" "${FEATURES[@]}" -futf8 -O3 "${predefs[@]}" "$file" >/dev/null
  done
}

clientdefs=("-DCSQC" "common/util-pre.qh" "dpdefs/csprogsdefs.qh")
check "client" clientdefs[@]

serverdefs=("-DSVQC" "common/util-pre.qh" "server/sys-pre.qh" "dpdefs/progsdefs.qh" "dpdefs/dpextensions.qh" "server/sys-post.qh" "server/defs.qh" "server/autocvars.qh")
check "server" serverdefs[@]

menudefs=("-DMENUQC" "common/util-pre.qh" "dpdefs/menudefs.qh")
check "menu" menudefs[@]
