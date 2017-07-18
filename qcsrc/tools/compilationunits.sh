#!/usr/bin/env bash
set -eu
cd ${0%/*}

# This script attempts to build the codebase in every possible header configuration,
# to check that all files #include what they need, so that we can eventually move away
# from a unity build and into incremental compilation.

# If these files exist from previous compilation, `./all compile` will stop
# detecting changes after running this script so delete them to trigger
# a recompile next time.
if [ -f ../../csprogs.dat ]; then
    rm ../../csprogs.dat
fi

if [ -f ../../menu.dat ]; then
    rm ../../menu.dat
fi

if [ -f ../../progs.dat ]; then
    rm ../../progs.dat
fi

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
