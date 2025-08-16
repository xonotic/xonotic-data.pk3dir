#!/usr/bin/env bash

set -euo pipefail
IFS=$' \n\t'

# check that we have all necessary env vars
if [ -z "${WORKDIR-}" ] \
|| [ -z "${CPP-}" ] \
|| [ -z "${QCC-}" ]
then
	printf "%s: Necessary env vars were not set\n" \
		"${BASH_SOURCE[0]}" > /dev/stderr
	exit 1
fi

# make sure to initialize these variables,
# give them default values if they are valueless
NDEBUG="${NDEBUG:-1}"
XONOTIC="${XONOTIC:-1}"
QCCFLAGS_WATERMARK="${QCCFLAGS_WATERMARK:-"$(git describe --tags --dirty='~')"}"
ENABLE_EFFECTINFO="${ENABLE_EFFECTINFO:-0}"
ENABLE_DEBUGDRAW="${ENABLE_DEBUGDRAW:-0}"
ENABLE_DEBUGTRACE="${ENABLE_DEBUGTRACE:-0}"

case "$QCC" in
	*/fteqcc*)
		QCCIDENT="-DFTEQCC"
		;;
	*)
		QCCIDENT="-DGMQCC"
		;;
esac

# {{{ QCCDEFS

declare -a QCCDEFS=(
	-DNDEBUG="$NDEBUG"
	-DXONOTIC="$XONOTIC"
	-DWATERMARK="\"$QCCFLAGS_WATERMARK\""
	-DENABLE_EFFECTINFO="$ENABLE_EFFECTINFO"
	-DENABLE_DEBUGDRAW="$ENABLE_DEBUGDRAW"
	-DENABLE_DEBUGTRACE="$ENABLE_DEBUGTRACE"
)
if [ -n "${BUILD_MOD-}" ]
then
	QCCDEFS+=(
		-DBUILD_MOD=\""$BUILD_MOD"\"
		-I"$BUILD_MOD"
	)
fi
for extradef in ${QCCDEFS_EXTRA-}
do
	QCCDEFS+=("$extradef")
done

# }}}

# {{{ QCCFLAGS

# Set to empty string to temporarily enable warnings when debugging
for flag in ${QCCFLAGS_WERROR-'-Werror'}
do
	QCCFLAGS_WERROR+=("$flag")
done

# We eventually need to get rid of these
for flag in ${QCCFLAGS_WTFS-'-Wno-field-redeclared'}
do
	QCCFLAGS_WTFS+=("$flag")
done

declare -a QCCFLAGS=(
	-std=gmqcc
	# Without -O3, GMQCC thinks some variables are used uninitialized if the initialization is done inside an `if (1)` block
	# (which is created by e.g. BEGIN_MACRO) which would cause the compilation units test to fail.
	# There doesn't appear to be any measurable increase in compile time
	# and it allows us to get rid of some explicit initializations which are just useless noise.
	-O3
	"${QCCFLAGS_WERROR[@]}"
	-Wall
	"${QCCFLAGS_WTFS[@]}"
	-futf8
	-freturn-assignments
	-frelaxed-switch
	# -Ooverlap-locals is required
	-Ooverlap-locals
)

for extraflag in ${QCCFLAGS_EXTRA-}
do
	QCCFLAGS+=("$extraflag")
done

# }}}

function qpp() {
	IN="$1"
	OUT="$2"
	case "$MODE" in
		client)
			DEFS=("-DGAMEQC" "-DCSQC")
			;;
		menu)
			DEFS=("-DMENUQC")
			;;
		server)
			DEFS=("-DGAMEQC" "-DSVQC")
			;;
	esac

	#>&2 echo + $CPP "${@:3}" "${DEFS[@]}" "$IN"

	# don't exit from additional info step
	set +e

	# additional information
	$CPP "${@:3}" "${DEFS[@]}" \
		-dM 1>"$WORKDIR/${MODE}_macros.txt" \
		-H 2>"$WORKDIR/${MODE}_includes.txt" \
		"$IN"

	# main step
	$CPP "${@:3}" "${DEFS[@]}" -MMD -MP -MT "$OUT" -Wall -Wundef -Werror "$IN" -o "$WORKDIR/$MODE.txt"

	err=$?

	# exit with error code if main step gave one
	[ "$err" != "0" ] && return "$err"

	set -e

	# TODO: document what this does
	sed -E 's/^#(line)? ([[:digit:]]+) "(.*)".*/'$'\\\n''#pragma file(\3)'$'\\\n''#pragma line(\2)/g' "$WORKDIR/$MODE.txt"
}

function qcc() {
	#>&2 echo + $(basename $QCC) $@

	# FIXME: relative compiler path is too deep
	(cd tools && $QCC "$@")
}

# Driver code which is not ran if this file is sourced from elsewhere.
# If it is not sourced then the driver code block is executed.
# If it is sourced from elsewher then the driver code bock
# is not executed and this file gives the above functions.
#
# Bashism: if this script file is the main executing program
if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then
	MODE="$1"
	OUT="$2"
	IN="$3"
	case "$OUT" in
	/*)
		OUT_ABSOLUTE="$OUT"
		;;
	*)
		OUT_ABSOLUTE="$PWD/$OUT"
		;;
	esac

	QCCFLAGS+=(
		-flno
		-fno-bail-on-werror
	)

	set -x
	qpp "$IN" "$OUT" -I. "$QCCIDENT" "${QCCDEFS[@]}" > "$WORKDIR/$MODE.qc"
	qcc "${QCCFLAGS[@]}" -o "$OUT_ABSOLUTE" "../$WORKDIR/$MODE.qc"
fi
