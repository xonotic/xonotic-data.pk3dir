#!/bin/sh

errord=false

check_files()
{
	for b in $2
	do
		if [ "$b" = "balance-testing.cfg" ] || [ "$b" = "balance-testingxpm.cfg" ]
		then
			continue
		fi

		A=`mktemp || echo a.tmp`
		B=`mktemp || echo b.tmp`
		awk ''"$3"' { print $2; }' "$1" | sort -u | tr -d '\r' > "$A"
		awk ''"$3"' { print $2; }' "$b" | sort -u | tr -d '\r' > "$B"
		extra=""
		if $4
		then
			extra="$(diff "$A" "$B" | grep '^>' | sort)"
			# only extract cvars that are in $b but not $1
			#   $b is allowed to override $1, but not change anything else
		else
			extra="$(diff "$A" "$B" | grep '^[<>]' | sort)"
		fi
		if [ "$extra" != "" ]
		then
			echo "Cvar mismatch between $1 and $b. Aborting."
			if $4
			then
				echo "The following are missing from $1, so must be either added to $1 or more likely removed from $b:"
			else
				echo "Differences are:"
				echo "< missing in $b"
				echo "> must be removed from $b"
			fi
			echo "$extra"
			errord=true
		fi
		rm -f "$A" "$B"
	done
}

check_files "balance-xonotic.cfg"    "balance-*.cfg"  "/^seta? +g_/"    true
check_files "bal-wep-xonotic.cfg"    "bal-wep-*.cfg"  "/^seta? +g_/"    true
check_files "_hud_descriptions.cfg"  "hud_*.cfg"      "/^seta? +hud_/"  false

if $errord
then
	if [ "$CMAKE" != "" ]
	then
		exit 1
	fi
	echo "Please wait for 30 seconds, so you have had enough time to read this..."
	sleep 30
fi
