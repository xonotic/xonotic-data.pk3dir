#!/bin/sh

set -eu


# Check that we got an argument
if [ -z "${1-}" ]
then
	echo
	echo "$0: No argument provided"
	echo
	exit 1
fi


# Check that we do not already have changes
STATE="$(git diff)"
if [ -n "$STATE" ]
then
	echo
	echo "$0: Do not run this script with changes in git index"
	echo
	exit 2
fi


# Run if argument is executable
if [ -x "${0%/*}/$1" ]
then
	# Run the given script
	"${0%/*}/$1" || {
		echo
		echo "$0: ${0%/*}/$1 ran into an error while executing"
		echo
		exit 3
	}
else
	echo "$0: ${0%/*}/$1 is not an executable"
	exit 4
fi


# Check that we did not produce changes
STATE="$(git diff)"
if [ -n "$STATE" ]
then
	echo
	echo "$0: ${0%/*}/$1 produced a change in the repository:"
	echo
	echo
	echo "$STATE"
	echo
	echo
	exit 5
fi
