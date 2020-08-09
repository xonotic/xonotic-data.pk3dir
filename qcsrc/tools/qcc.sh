#!/usr/bin/env bash
set -euo pipefail
IFS=$' \n\t'

WORKDIR=${WORKDIR}
CPP=${CPP}
QCC=${QCC}
QCCIDENT="-DGMQCC"
QCCDEFS=${QCCDEFS}
QCCFLAGS=${QCCFLAGS}

function qpp() {
    IN=$1
    OUT=$2
    case ${MODE} in
        client) DEFS="-DGAMEQC -DCSQC"
        ;;
        menu) DEFS="-DMENUQC"
        ;;
        server) DEFS="-DGAMEQC -DSVQC"
        ;;
    esac
    #>&2 echo + ${CPP} "${@:3}" ${DEFS} "${IN}"
    set +e
    # additional information
    ${CPP} "${@:3}" ${DEFS} \
        -dM 1>"${WORKDIR}/${MODE}_macros.txt" \
        -H 2>"${WORKDIR}/${MODE}_includes.txt" \
        "${IN}"
    # main step
    ${CPP} "${@:3}" ${DEFS} -MMD -MP -MT "${OUT}" -Wall -Wundef -Werror "${IN}" -o "${WORKDIR}/${MODE}.txt"
    err=$?
    set -e
    if [ ${err} -ne 0 ]; then return ${err}; fi
    sed -E 's/^#(line)? ([[:digit:]]+) "(.*)".*/'$'\\\n''#pragma file(\3)'$'\\\n''#pragma line(\2)/g' "${WORKDIR}/${MODE}.txt"
}

function qcc() {
    #>&2 echo + $(basename ${QCC}) $@
    # FIXME: relative compiler path is too deep
    (cd tools && ${QCC} "$@")
}

$(return >/dev/null 2>&1) || {
    MODE=$1
    OUT=$2
    IN=$3
    case "${OUT}" in
      /*)
        OUT_ABSOLUTE=${OUT}
        ;;
      *)
        OUT_ABSOLUTE=${PWD}/${OUT}
        ;;
    esac
    set -x
    qpp "${IN}" "${OUT}" -I. ${QCCIDENT} ${QCCDEFS} > "${WORKDIR}/${MODE}.qc"
    qcc ${QCCFLAGS} -o "${OUT_ABSOLUTE}" "../${WORKDIR}/${MODE}.qc"
}
