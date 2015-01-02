#!/bin/sh

errord=false

check_files()
{
	countw=`awk ''"$3"' { print $2; }' "$1" | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
	for b in $2; do
		countb=`awk ''"$3"' { print $2; }' "$b" | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
		if [ "$countw" != "$countb" ]; then
			echo "Mismatch between "$1" and $b. Aborting."
			echo "Differences are:"
			echo "< missing in $b"
			echo "> must get removed from $b"
			A=`mktemp || echo a.tmp`
			B=`mktemp || echo b.tmp`
			awk ''"$3"' { print $2; }' "$1"      | sort -u | tr -d '\r' > "$A"
			awk ''"$3"' { print $2; }' "$b"                     | sort -u | tr -d '\r' > "$B"
			diff "$A" "$B" | grep '^[<>]' | sort
			rm -f "$A" "$B"
			errord=true
		fi
	done
}

check_files "balance-xonotic.cfg" "balance-*.cfg" "/^seta? g_/"
check_files "_hud_descriptions.cfg" "hud_*.cfg" "/^seta? hud_/"

if $errord; then
	echo "Please wait for 30 seconds, so you have had enough time to read this..."
	sleep 30
fi
