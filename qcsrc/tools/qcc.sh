#!/bin/bash
set -eu

WORKDIR=${WORKDIR}
CPP=${CPP}
QCC=${QCC}
QCCIDENT="-DGMQCC"
QCCDEFS=${QCCDEFS}
QCCFLAGS=${QCCFLAGS}

function qpp() {
    IN=$1
    OUT=$2
    >&2 echo + ${CPP} ${@:3} ${IN}
    # additional information
    ${CPP} ${@:3} \
        -dM 1>${WORKDIR}/${MODE}_macros.txt \
        -H 2>${WORKDIR}/${MODE}_includes.txt \
        ${IN}
    # main step
    ${CPP} ${@:3} -MMD -MP -MT ${OUT} -Wall -Wundef -Werror ${IN} -o ${WORKDIR}/${MODE}.txt
    sed 's/^#\(line\)\? \([[:digit:]]\+\) "\(.*\)".*/\n#pragma file(\3)\n#pragma line(\2)/g' ${WORKDIR}/${MODE}.txt
}

function qcc() {
    >&2 echo + $(basename ${QCC}) $@
    # FIXME: relative compiler path is too deep
    (cd tools && ${QCC} $@)
}

$(return >/dev/null 2>&1) || {
    MODE=$1
    OUT=$2
    IN=$3

    case ${MODE} in
        client) PROG=CSQC
        ;;
        menu) PROG=MENUQC
        ;;
        server) PROG=SVQC
        ;;
    esac

    qpp ${IN} ${OUT} -I. ${QCCIDENT} ${QCCDEFS} -D${PROG} > ${WORKDIR}/${MODE}.qc
    qcc ${QCCFLAGS} -o ${OUT} ../${WORKDIR}/${MODE}.qc
}
