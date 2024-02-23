#!/usr/bin/env bash

set -eu

cd "$(realpath "$(dirname "$0")")"

[ -z "${QCCFLAGS_WATERMARK-}" ] && \
	QCCFLAGS_WATERMARK=$(git describe --tags --dirty='~')
export QCCFLAGS_WATERMARK

# This script attempts to build the codebase in every possible header configuration,
# to check that all files #include what they need, so that we can eventually move away
# from a unity build and into incremental compilation.

# If these files exist from previous compilation, `./all compile` will stop
# detecting changes after running this script so delete them to trigger
# a recompile next time.
[ -f ../../csprogs.dat ] && rm ../../csprogs.dat
[ -f ../../menu.dat    ] && rm ../../menu.dat
[ -f ../../progs.dat   ] && rm ../../progs.dat

CPP="cc -xc -E"

[ -z "${QCC-}" ] && \
	export QCC="$PWD/../../../../gmqcc/gmqcc"

declare -a QCCDEFS=(
	-DNDEBUG=1
	-DXONOTIC=1
	-DWATERMARK="\"$QCCFLAGS_WATERMARK\""
	-DENABLE_EFFECTINFO=0
	-DENABLE_DEBUGDRAW=0
	-DENABLE_DEBUGTRACE=0
)

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
QCCFLAGS+=("${NOWARN[@]}")

# source additional functions
. qcc.sh

# when used does this lead to .tmp or qcsrc/.tmp ?? both?
WORKDIR=../.tmp

# move to qcsrc
cd ..

function check1() {
	declare -l prog="${1}"
	declare -l file="${2}"
	export MODE="$prog"

	declare -a includes=("-include lib/_all.inc")
	[ -f "${prog}/_all.qh" ] && includes+=("-include ${prog}/_all.qh")

	# FIXME: one arg array requires splitting until qcc.sh is fixed
	qpp "$file" "test-${prog}.dat" \
		${includes[@]} \
		-I. "${QCCIDENT}" "${QCCDEFS[@]}" > "${WORKDIR}/${prog}.qc"
	qcc "${QCCFLAGS[@]}" -o "../${WORKDIR}/test-${prog}.dat" "../${WORKDIR}/${prog}.qc" >/dev/null
}

function check() {
	declare -l prog="${1}"
	find "$prog" -type f -name '*.qc' -print0 | sort -z | while read -r -d '' file
	do
		check1 "$prog" "$file"
	done
}

if [ ${#@} -eq 0 ]
then # no args, check all
	check client
	check server
	check menu
else # check specific
	for var in "${@}"
	do
		var="${var#test-}"
		check "$var"
	done
fi
