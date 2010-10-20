#!/bin/sh

countw=`awk '/^seta? g_/ { print $2; }' balanceXonotic.cfg       | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
for b in balance*.cfg; do
	countb=`awk '/^seta? g_/ { print $2; }' "$b"  | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
	if [ "$countw" != "$countb" ]; then
		echo "Mismatch between balanceXonotic.cfg and $b. Aborting."
		echo "Differences are:"
		A=`mktemp`
		B=`mktemp`
		awk '/^seta? g_/ { print $2; }' balanceXonotic.cfg       | sort -u | tr -d '\r' > "$A"
		awk '/^seta? g_/ { print $2; }' "$b"                     | sort -u | tr -d '\r' > "$B"
		echo "< missing in $b"
		echo "> must get removed from $b"
		diff "$A" "$B" | grep '^[<>]' | sort
		rm -f "$A" "$B"
		exit 1
	fi
done
