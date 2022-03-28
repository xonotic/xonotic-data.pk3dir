#!/usr/bin/env bash
[ -z "$QCCFLAGS_WATERMARK" ] && export QCCFLAGS_WATERMARK=$(git describe --tags --dirty='~')
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
    -DWATERMARK="\"$QCCFLAGS_WATERMARK\""
    -DENABLE_EFFECTINFO=0
    -DENABLE_DEBUGDRAW=0
    -DENABLE_DEBUGTRACE=0
)
QCCDEFS="${QCCDEFS[@]}"

declare -a QCCFLAGS=(
    -std=gmqcc
    # Without -O3, GMQCC thinks some variables are used uninitialized if the initialization is done inside an `if (1)` block
    # (which is created by e.g. BEGIN_MACRO) which would cause the compilation units test to fail.
    # There doesn't appear to be any measurable increase in compile time
    # and it allows us to get rid of some explicit initializations which are just useless noise.
    -O3
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
    includes="-include lib/_all.inc"
    [ -f ${prog}/_all.qh ] && includes="${includes} -include ${prog}/_all.qh"
    qpp ${file} test-${prog}.dat \
            ${includes} \
            -I. ${QCCIDENT} ${QCCDEFS} > ${WORKDIR}/${prog}.qc
    qcc ${QCCFLAGS} -o ../${WORKDIR}/test-${prog}.dat ../${WORKDIR}/${prog}.qc >/dev/null
}

function check() {
    declare -l prog="${1}"
    find ${prog} -type f -name '*.qc' -print0 | sort -z | while read -r -d '' file; do
        check1 ${prog} ${file}
    done
}

if [ ${#@} -eq 0 ]; then
    check client
    check server
    check menu
else
    for var in ${@}; do
        var=${var#test-}
        check ${var}
    done
fi
