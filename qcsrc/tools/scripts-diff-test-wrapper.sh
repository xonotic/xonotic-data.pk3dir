#!/bin/sh

set -eu


# This script is a wrapper for running other scripts to test whether
# or not they produce a change, such as a file modification,
# creation, or deletion.
#
# In order to test it accurately this # script should not be
# ran with uncommitted changes.
#
# In the case that there are changes produced this wrapper script
# mentions that there has been a change and exits with an error.
#
# Any of the potential changes are left in the git index so that
# if this script is run in a developer setup they can easily see
# the changes and commit them or address them without the need
# to re-run any scripts.
#
# This script is also intended for GitLab CI/CD pipelines so that
# we're able to have tests which track the output of certain scripts.


# Check that we got an argument
if [ -z "${1-}" ]
then
	echo
	echo "$0: No argument provided"
	echo
	exit 1
fi


# Check that we do not already have changes
if [ -n "$(git status --porcelain=v1)" ]
then
	echo
	echo "$0: Do not run this script with changes in git index"
	echo
	echo
	git status
	echo
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
if [ -n "$(git status --porcelain=v1)" ]
then
	echo
	echo "$0: ${0%/*}/$1 produced a change in the repository:"
	echo
	echo
	git status
	echo
	echo
	exit 5
fi
