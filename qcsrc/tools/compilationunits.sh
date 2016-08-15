#!/usr/bin/env bash
set -eu
cd ${0%/*}

WORKDIR=../.tmp

CPP="cc -xc -E"
: ${QCC:=$PWD/../../../../gmqcc/gmqcc}

declare -a QCCDEFS=(
    -DNDEBUG=1
    -DXONOTIC=1
    -DWATERMARK="\"$(git describe --tags --dirty='~')\""
)
QCCDEFS="${QCCDEFS[@]}"

declare -a QCCFLAGS=(
    -std=gmqcc
    -Wall -Werror
    -futf8
    -freturn-assignments
    -frelaxed-switch
    -Ooverlap-locals
)
declare -a NOWARN=(
    -Wno-field-redeclared
    -Wno-unused-variable
    -Wno-implicit-function-pointer
    -Wno-missing-return-values
)
QCCFLAGS="${QCCFLAGS[@]} ${NOWARN[@]}"

. qcc.sh
cd ..

function check1() {
    declare -l base="${1}"
    MODE=${2}
    declare -l file="${3}"
    qpp ${file} test.dat \
            -include lib/_all.inc -include ${base}/_all.qh \
            -I. ${QCCIDENT} ${QCCDEFS} -D${MODE} > ${WORKDIR}/${MODE}.qc
    qcc ${QCCFLAGS} -o ../${WORKDIR}/test.dat ../${WORKDIR}/${MODE}.qc >/dev/null
}

function check() {
    declare -l base="${1}"
    MODE=${2}
    find ${base} -type f -name '*.qc' -print0 | sort -z | while read -r -d '' file; do
        check1 ${base} ${MODE} ${file}
    done
}

check client CSQC
check server SVQC
check menu MENUQC
