#!/usr/bin/env bash

set -eu

cd "$(realpath "$(dirname "$0")")"

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

# when used does this lead to .tmp or qcsrc/.tmp ?? both?
export WORKDIR=../.tmp

# source additional functions and variables for compiling
. qcc.sh

declare -a NOWARN=(
	# -Wno-field-redeclared is included via WTFS by default
	-Wno-unused-variable
	-Wno-implicit-function-pointer
	-Wno-missing-return-values
)
QCCFLAGS+=("${NOWARN[@]}")

# move to qcsrc
cd ..

function check1() {
	declare -l prog="$1"
	declare -l file="$2"
	export MODE="$prog"

	declare -a includes=("-include" "lib/_all.inc")
	[ -f "$prog/_all.qh" ] && includes+=("-include $prog/_all.qh")

	qpp "$file" "test-$prog.dat" \
		"${includes[@]}" \
		-I. "$QCCIDENT" "${QCCDEFS[@]}" > "$WORKDIR/$prog.qc"
	qcc "${QCCFLAGS[@]}" -o "../$WORKDIR/test-$prog.dat" "../$WORKDIR/$prog.qc" >/dev/null
}

function check() {
	declare -l prog="$1"
	find "$prog" -type f -name '*.qc' -print0 | sort -z | while read -r -d '' file
	do
		check1 "$prog" "$file"
	done
}

# check argument array length
if [ "${#@}" = "0" ]
then # no args, run all checks
	check client
	check server
	check menu
else # run a specific check
	for var in "$@"
	do
		var="${var#test-}"
		check "$var"
	done
fi
