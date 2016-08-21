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
    declare -l prog="${1}"
    declare -l file="${2}"
    MODE=${prog}
    qpp ${file} test.dat \
            -include lib/_all.inc -include ${prog}/_all.qh \
            -I. ${QCCIDENT} ${QCCDEFS} > ${WORKDIR}/${prog}.qc
    qcc ${QCCFLAGS} -o ../${WORKDIR}/test.dat ../${WORKDIR}/${prog}.qc >/dev/null
}

function check() {
    declare -l prog="${1}"
    find ${prog} -type f -name '*.qc' -print0 | sort -z | while read -r -d '' file; do
        check1 ${prog} ${file}
    done
}

check client
check server
check menu
