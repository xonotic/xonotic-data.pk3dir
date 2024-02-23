#!/usr/bin/env bash

set -euo pipefail
IFS=$' \n\t'

QCCIDENT="-DGMQCC"

# check that we have all necessary env vars
if [ -z "${WORKDIR-}" ] \
|| [ -z "${CPP-}" ] \
|| [ -z "${QCC-}" ] \
|| [ -z "${QCCDEFS-}" ] \
|| [ -z "${QCCFLAGS-}" ]
then
	# hardcode qcc.sh name because this file is sourced
	# qcsrc/tools/compilationunits.sh: Necessary env vars were not set
	# would be very misleading
	printf "%s: qcc.sh: Necessary env vars were not set\n" "$0" > /dev/stderr
	exit 1
fi

function qpp() {
	IN=$1
	OUT=$2
	case "${MODE}" in
		client)
			DEFS="-DGAMEQC -DCSQC"
			;;
		menu)
			DEFS="-DMENUQC"
			;;
		server)
			DEFS="-DGAMEQC -DSVQC"
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
	${CPP} ${@:3} ${DEFS} -MMD -MP -MT "${OUT}" -Wall -Wundef -Werror "${IN}" -o "${WORKDIR}/${MODE}.txt"
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

# wtf is this? the file has exit on error and only has env var
# assignments before this which I assume is an implicit $? aka
# return value check of the last command? This block should never
# execute???
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
