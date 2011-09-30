#!/bin/sh

errord=false
countw=`awk '/^seta? g_/ { print $2; }' balanceXonotic.cfg       | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
for b in balance*.cfg; do
	countb=`awk '/^seta? g_/ { print $2; }' "$b"  | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
	if [ "$countw" != "$countb" ]; then
		echo "Mismatch between balanceXonotic.cfg and $b. Aborting."
		echo "Differences are:"
		echo "< missing in $b"
		echo "> must get removed from $b"
		A=`mktemp || echo a.tmp`
		B=`mktemp || echo b.tmp`
		awk '/^seta? g_/ { print $2; }' balanceXonotic.cfg       | sort -u | tr -d '\r' > "$A"
		awk '/^seta? g_/ { print $2; }' "$b"                     | sort -u | tr -d '\r' > "$B"
		diff "$A" "$B" | grep '^[<>]' | sort
		rm -f "$A" "$B"
		errord=true
	fi
done
if $errord; then
	echo "Please wait for 30 seconds, so you have had enough time to read this..."
	sleep 30
fi
