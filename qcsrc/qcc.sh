#!/bin/sh
set -eu

MODE=$1
IN=$3
OUT=$2

QCC=${QCC}
QCCIDENT="-DGMQCC"

case ${MODE} in
    client) PROG=CSQC
    ;;
    menu) PROG=MENUQC
    ;;
    server) PROG=SVQC
    ;;
esac

CPP="${CPP} -I. ${QCCIDENT} ${QCCDEFS} -D${PROG}"
set -x
${CPP} -CC -MMD -MP -MT ${OUT} -Wall -Wundef -Werror -o ./tmp/${MODE}.qc ${IN}
${CPP} -dM 1>./tmp/${MODE}_macros.txt -H 2>./tmp/${MODE}_includes.txt ${IN}
sed -i 's/^#\(line\)\? \([[:digit:]]\+\) "\(.*\)".*/\n#pragma file(\3)\n#pragma line(\2)/g' ./tmp/${MODE}.qc
cd ${MODE}
${QCC} ${QCCFLAGS} -o ../${OUT} ../tmp/${MODE}.qc
