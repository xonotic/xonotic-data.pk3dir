#!/bin/sh

errord=false

# Make sure the config file doesn't set cvars with the wrong prefix
correct_prefixes()
{
	local allRegex="$1"
	local validRegex="$2"
	local configFile="$3"
	local tmpFile="$4"

	awk ''"$allRegex"' && !'"$validRegex"' { print $2; }' "$configFile" | tr -d '\r' | sort -u > "$tmpFile"
	if [ -s "$tmpFile" ]
	then
		printf "\033[31m%s\033[0m\n" "Invalid cvars changed in $configFile. Aborting."
		echo "The following cvars are in $configFile but shouldn't be there:"
		diff /dev/null "$tmpFile" | grep "^>"
		echo
		errord=true
	fi
}

# Make sure the files set the same cvars, or the custom doesn't set any which the default doesn't
correct_cvars()
{
	local validRegex="$1"
	local customFile="$2"
	local defaultFile="$3"
	local mustSetAll="$4"
	local A="$5"
	local B="$6"

	awk ''"$validRegex"' { print $2; }' "$defaultFile" | tr -d '\r' | sort -u > "$A"
	awk ''"$validRegex"' { print $2; }' "$customFile"  | tr -d '\r' | sort -u > "$B"
	extra=""
	if $mustSetAll
	then
		# Files must change identical cvars, extract all differences
		extra="$(diff "$A" "$B" | grep "^[<>]")"
	else
		# Only extract cvars that are in $customFile but not $defaultFile
		#   $customFile is allowed to override $defaultFile, but not change anything else
		extra="$(diff "$A" "$B" | grep "^>")"
	fi
	if [ "$extra" != "" ]
	then
		printf "\033[31m%s\033[0m\n" "Cvar mismatch between $defaultFile and $customFile. Aborting."
		if $mustSetAll
		then
			echo "Differences are:"
			echo "< missing in $customFile"
			echo "> must be removed from $customFile"
		else
			echo "The following cvars are missing from $defaultFile, so must be either added to $defaultFile or more likely removed from $customFile:"
		fi
		echo "$extra"
		echo
		errord=true
	fi
}

check_files()
{
	local defaultFile="$1"
	local customFiles="$2"
	local validRegex="$3"
	local allRegex="$4"
	local mustSetAll="$5"

	A="$(mktemp || echo a.tmp)"
	B="$(mktemp || echo b.tmp)"

	# First check defaultFile
	correct_prefixes "$allRegex" "$validRegex" "$defaultFile" "$A"

	# Now compare defaultFile to the customFiles
	for customFile in $customFiles
	do
		if [ "$customFile" = "balance-testing.cfg" ] \
		|| [ "$customFile" = "balance-testingxpm.cfg" ] \
		|| [ "$customFile" = "$defaultFile" ]
		then
			continue
		fi
		correct_prefixes "$allRegex" "$validRegex" "$customFile" "$B"
		correct_cvars "$validRegex" "$customFile" "$defaultFile" "$mustSetAll" "$A" "$B"
	done
	rm -f "$A" "$B"
}

check_files "balance-xonotic.cfg"    "balance-*.cfg"  "/^seta? +g_/"      "/^seta? +/"  false
check_files "bal-wep-xonotic.cfg"    "bal-wep-*.cfg"  "/^seta? +g_/"      "/^seta? +/"  false
check_files "_hud_descriptions.cfg"  "hud_*.cfg"      "/^seta? +_?hud_/"  "/^seta? +/"  true

if $errord
then
	if [ "$CMAKE" != "" ]
	then
		exit 1
	fi
	echo "Please wait for 30 seconds, so you have had enough time to read this..."
	sleep 30
fi
