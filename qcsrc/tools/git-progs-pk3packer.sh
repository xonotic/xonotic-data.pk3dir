#!/bin/sh

#########################################
#                                       #
#     Git progs pk3 packager script     #
#                                       #
#########################################



# This script compiles and packages progs into
# a pk3 which is meant to be distributable
# to players without compiling dev environments
# and allow them to host a listen or dedicated
# server with these progs.



# Please say to anyone who these progs are given to
# that they should not have multiple prog containing
# pk3s in their userfolder to avoid conflicts...



# Shipped files include:
#
# progs.dat for server VM.
# csprogs.dat for client VM.
# menu.dat for menu VM.
#
# progs-HASH.dat, csprogs-HASH.dat and progs.txt
#     for hosting a dedicated server
#     which uses these new progs and
#     hopefully sends this pk3 to clients.
#     These 3 files are all required
#     due to some builds having a named
#     progs-something.dat which server
#     could prefer over our unnamed progs.dat.
#
# changes.diff which tries to list all code changes
#     since common ancestor with master branch.
#
# All .cfg files which have been edited.



# The pk3 is moved to Downloads directory for
# easy sharing and house keeping. If the user
# has set their xdg directories' DOWNLOAD dir
# then it'll be respected. Second option is
# ~/Downloads directory. If neither of those
# exists then it's left in the current working
# directory, the root of xonotic-data.pk3dir



# abort on error(non-0 return code) and abort on unset variable
set -eu

# cd to xonotic-data.pk3dir
cd "$(dirname "$0")"../../../

# check for uncommitted changes and abort if found
if [ -n "$(git diff)" ] || [ -n "$(git diff --staged)" ]
then
	printf "\n\n%s\n\n%s\n\n\n%s\n%s\n\n\n" "WARNING: Found local uncommitted changes." \
		"Please only run this script without local changes." \
		"You can use 'git stash' and 'git stash pop' to store and later restore your changes." \
		"Or 'git reset --hard' to nuke all of them."
	exit 1
fi

# make sure progs are latest
make "-j$(nproc)" qc

HASH="$(git rev-parse --short=7 HEAD)"
BRANCH="$(git branch --show-current | sed 's#/#-#g')"
[ -z "$BRANCH" ] && BRANCH="headless"

packagercleanup() {
	# allow for error return codes in this function as this may be ran on interrupt
	# right after starting where all files to clean up don't exist yet
	set +e

	rm "csprogs-$HASH.dat"
	rm "progs-$HASH.dat"
	rm progs.txt
	rm changes.diff

	rm git-progspk3.zip 2> /dev/null
}
trap 'packagercleanup' EXIT INT QUIT TERM

# QoL: duplicate progs in case someone happens to run dedicated server with these progs
cp -v "$PWD/csprogs.dat" "csprogs-$HASH.dat"
cp -v "$PWD/progs.dat" "progs-$HASH.dat"
printf "%s\n" "$HASH" > progs.txt

# find list of edited cfg files
# changes of this branch from master
EDITEDCFGS="$(git diff --name-status master...HEAD | grep "\.cfg$" | cut -d "$(printf '\t')" -f 2)"
# include configs which have been outdated by a change in master
EDITEDCFGS="$EDITEDCFGS $(git diff --name-status HEAD...master | grep "\.cfg$" | cut -d "$(printf '\t')" -f 2)"

# try to include list of all changes in the package
if [ "$BRANCH" = "headless" ]
then
	printf "%s\n\n" "## Package creator could not fetch changes compared to master branch from headless commit." > changes.diff

elif [ -n "$(git diff master...HEAD)" ]
then
	printf "%s\n\n" "## Changes compared to master branch:" > changes.diff
	git diff master...HEAD >> changes.diff

else
	printf "%s\n" "No changes compared to latest local master branch." > changes.diff
fi

# zip everything into git-progspk3.zip
# shellcheck disable=SC2086 # Intended splitting of EDITEDCFGS
zip git-progspk3.zip csprogs.dat progs.dat menu.dat progs.txt "csprogs-$HASH.dat" "progs-$HASH.dat" $EDITEDCFGS changes.diff

# Move the package to Downloads directory for easy sharing and house keeping
if [ "$(xdg-user-dir DOWNLOAD)" != "$HOME" ] && [ -d "$(xdg-user-dir DOWNLOAD)" ]
then
	mv -v "$PWD/git-progspk3.zip" "$(xdg-user-dir DOWNLOAD)/git-progs-$BRANCH-$HASH.pk3"
	printf "\n%s\n%s\n\n" "Packaged progs based on $BRANCH's $HASH commit" \
		"and moved them to $(xdg-user-dir DOWNLOAD)/git-progs-$BRANCH-$HASH.pk3"

elif [ -d "$HOME/Downloads" ]
then
	mv -v "$PWD/git-progspk3.zip" "$HOME/Downloads/git-progs-$BRANCH-$HASH.pk3"
	printf "\n%s\n%s\n\n" "Packaged progs based on $BRANCH's $HASH commit" \
		"and moved them to ~/Downloads/git-progs-$BRANCH-$HASH.pk3"

else
	mv -v "git-progspk3.zip" "git-progs-$BRANCH-$HASH.pk3"
	printf "\n%s\n%s\n%s\n\n" "Packaged progs based on $BRANCH's $HASH commit" \
		"but could not move it out to Downloads dir" \
		"git-progs-$BRANCH-$HASH.pk3 resides in $PWD"
fi

printf '%s\n%s\n%s\n\n' "The pk3 can be moved to Xonotic's userdir which is:" \
	'On Linux or Mac the "~/.xonotic/data/" directory' \
	'On Windows the "C:\users\%userprofile%\Saved Games\xonotic\data\" folder'
