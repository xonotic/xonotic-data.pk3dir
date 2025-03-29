#!/bin/bash

# abort on error(non-0 return code) and abort on unset variable
set -eu

# refuse to run on Windows' MINGW due to symlinking issues
# `ln -s "$PWD" data/xonotic-data.pk3dir` seems to not work in any form
# even with fully relative paths or `ln -s ../ xonotic-data.pk3dir`
# FIXME?
case "$(uname)" in
	MINGW*) printf "%s\n%s\n" "This file is not suitable for Windows' MINGW" \
		"without modifications due to the lack of proper symlink support"; exit 1 ;;
esac

printf "Testing for dependencies\n"
# command -q / --quiet one day? :(
command -V awk       > /dev/null
command -V chmod     > /dev/null
command -V git       > /dev/null
command -V grep      > /dev/null
command -V make      > /dev/null
command -V md5sum    > /dev/null
command -V mkdir     > /dev/null
command -V mktemp    > /dev/null
command -V rm        > /dev/null
command -V sed       > /dev/null
command -V tee       > /dev/null
command -V test      > /dev/null
command -V true      > /dev/null
command -V printf    > /dev/null
command -V wget      > /dev/null
printf "All dependencies found\n"

createdtoday() {
	# check if a file's creation date is today
	if [ "$(stat -c '%y' "$1" | cut -d ' ' -f 1)" = "$(date -I)" ]
	then
		#echo "$1 was created today"
		return 0
	else
		#echo "$1 was not created today"
		return 1
	fi
}

hashtestcleanup() {
	# allow for error return codes in this function as this may be ran on interrupt
	# right after starting where all files to clean up don't exist yet
	set +e

	# unset trap
	trap - EXIT INT QUIT TERM

	# Few files' removal has been disabled for file reuse
	# It's possible to get rate limited with enough testing

	rm -fv lock
	rm -fv data/darkplaces_history.txt
	rm -fv data/xonotic-data.pk3dir
	#rm -fv data/stormkeep.pk3
	rm -fv data/data/defaultSVQC.cfg
	rm -fv data/data/hits---1.plot
	rm -fv data/data/hits---2.plot
	rm -fv data/data/hits---3.plot
	rm -fv data/data/notifications_dump.cfg
	rm -fv data/data/server.db
	rm -dfv data/data/
	#rm -fv data/maps/_init.bsp
	#rm -dfv data/maps/

	set -e
}
trap "hashtestcleanup" EXIT INT QUIT TERM

# cd xonotic-data.pk3dir
cd "$(dirname "$0")/../../"

WORKINGDIR="$PWD"

TMPDIR="$PWD/.tmp"

# if xonotic-data.pk3dir/data/xonotic-data.pk3dir isn't a symlink then link it
if [ -e data/xonotic-data.pk3dir ]
then # file exists
	if ! [ -L data/xonotic-data.pk3dir ]
	then # file exists but it's not a symlink, replace it
		if [ -d data/xonotic-data.pk3dir ]
		then # it's a dir
			rm -dfv data/xonotic-data.pk3dir
			ln -s "$PWD" data/xonotic-data.pk3dir
		else # it's not a dir
			rm data/xonotic-data.pk3dir
			ln -s "$PWD" data/xonotic-data.pk3dir
		fi
	else # it is a symlink, verify where it points
		if [ "$(realpath data/xonotic-data.pk3dir)" != "$PWD" ]
		then # wrong place, recreate it
			rm data/xonotic-data.pk3dir
			ln -s "$PWD" data/xonotic-data.pk3dir
		fi
	fi
else # no file exists there
	ln -s "$PWD" data/xonotic-data.pk3dir
fi

MAKEFLAGS=-j$(nproc)
export MAKEFLAGS
printf "%s\n" "MAKEFLAGS=$MAKEFLAGS"
export CC="gcc -pipe"

# precompiled binary is executable and its creation date is today
if [ -x "$TMPDIR/gmqcc-bin" ] && createdtoday "$TMPDIR/gmqcc-bin"
then
	export QCC="$TMPDIR/gmqcc-bin"
else # previously compiled is executable and its creation date is today
	if [ -x "$TMPDIR/gmqcc/gmqcc" ] && createdtoday "$TMPDIR/gmqcc/gmqcc"
	then
		export QCC="$TMPDIR/gmqcc/gmqcc"
	else # nothing reusable exists
		# prefer a precompiled binary
		if wget -nv https://beta.xonotic.org/pipeline-bin/gmqcc -O "$TMPDIR/gmqcc-bin"
		then
			export QCC="$TMPDIR/gmqcc-bin"
			chmod +x "$QCC"
		else
			if [ -d "$TMPDIR/gmqcc" ]
			then
				cd "$TMPDIR/gmqcc"
				git checkout main
				git pull
				cd "$WORKINGDIR"
			else
				git clone --depth=1 --branch=main https://gitlab.com/xonotic/gmqcc.git "$TMPDIR/gmqcc"
			fi
			make -C "$TMPDIR/gmqcc" || exit 1
			export QCC="$TMPDIR/gmqcc/gmqcc"
		fi
	fi
fi

# Makefile: don't complain about lack of tags (fetching them is slow)
export QCCFLAGS_WATERMARK=gitlab_pipeline
# Makefile: don't compress anything or complain about lack of zip program
export ZIP=true


if [ "$(uname):$(uname -m)" = "Linux:x86_64" ] && [ -x "$TMPDIR/xonotic-linux64-dedicated" ] && createdtoday "$TMPDIR/xonotic-linux64-dedicated"
then # precompiled binary is executable and its creation date is today
	export ENGINE="$TMPDIR/xonotic-linux64-dedicated"
else
	if [ -x "$TMPDIR/darkplaces/darkplaces-dedicated" ] && createdtoday "$TMPDIR/darkplaces/darkplaces-dedicated"
	then # previously compiled is executable and its creation date is today
		export ENGINE="$TMPDIR/darkplaces/darkplaces-dedicated -xonotic"
	else # nothing reusable exists
		# prefer a precompiled binary
		if [ "$(uname):$(uname -m)" = "Linux:x86_64" ] && wget -nv https://beta.xonotic.org/pipeline-bin/xonotic-linux64-dedicated -O "$TMPDIR/xonotic-linux64-dedicated"
		then
			export ENGINE="$TMPDIR/xonotic-linux64-dedicated"
			chmod +x "$ENGINE"
		else
			if [ -d "$TMPDIR/darkplaces" ]
			then
				cd "$TMPDIR/darkplaces"
				#git checkout master
				git pull --autostash
				cd "$WORKINGDIR"
			else
				git clone --depth=1 https://gitlab.com/xonotic/darkplaces.git "$TMPDIR/darkplaces"
			fi
			make -C "$TMPDIR/darkplaces" sv-release || exit 1
			export ENGINE="$TMPDIR/darkplaces/darkplaces-dedicated -xonotic"
		fi
	fi
fi
export ENGINE="$ENGINE -noconfig -nohome +sys_stdout_blocks 1"

make qc || exit 1

mkdir -p data/maps

createdtoday "data/maps/_init.bsp" \
	|| wget -nv -O data/maps/_init.bsp https://gitlab.com/xonotic/xonotic-maps.pk3dir/raw/master/maps/_init/_init.bsp

PASS=0
while read -r LINE
do
	printf "%s\n" "$LINE"
	printf "%s\n" "$LINE" | grep -q ".*All tests OK$" && PASS=1
done < <(${ENGINE} +developer 1 +map _init +sv_cmd dumpnotifs +sv_cmd runtest +wait +quit)
test "$PASS" = "1" || { printf "\033[1;31m%s\033[0m\n" "sv_cmd runtest failed!"; exit 1; }
diff notifications.cfg data/data/notifications_dump.cfg ||
	{ printf "Please update notifications.cfg using \`dumpnotifs\`!"; exit 1; }

createdtoday "data/stormkeep.pk3" \
	|| wget -nv -O data/stormkeep.pk3 https://beta.xonotic.org/pipeline-bin/stormkeep.pk3

if [ -z "${EXPECT-}" ]
then
	# find the line with expected hash from .gitlab-ci.yml, extract the hash and remove carriage return
	EXPECT="$(grep 'EXPECT=' './.gitlab-ci.yml' | cut -d '=' -f 2 | tr -d $'\r')"
fi
HASH=$(${ENGINE} +exec serverbench.cfg \
      | tee /dev/stderr \
      | grep '^:' \
      | grep -v '^:gamestart:' \
      | grep -v '^:anticheat:' \
      | md5sum | awk '{ print $1 }')

hashtestcleanup

if [ "$HASH" = "$EXPECT" ]
then # green ok print
	printf "\033[32m%s\033[0m\n" "expected: $EXPECT"
	printf "\033[32m%s\033[0m\n" "  actual: $HASH"
	printf "\033[32m%s\033[0m\n" "hashes match"
	exit 0
else # red error print
	printf "\033[31m%s\033[0m\n" "expected: $EXPECT"
	printf "\033[31m%s\033[0m\n" "  actual: $HASH"
	printf "\033[1;31m%s\033[0m\n" "!!! ERROR: HASHES DO NOT MATCH !!!"
	printf "\033[35mThis is expected if the number or execution order of random() calls changed,\n"
	printf "otherwise it indicates a more meaningful change in gameplay and match outcomes.\033[0m\n"
	exit 1
fi
