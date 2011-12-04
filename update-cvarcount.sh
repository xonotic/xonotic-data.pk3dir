#!/bin/sh

maincfg[0]=balanceXonotic.cfg
   cfgs[0]=balance*.cfg
 prefix[0]="/^seta? g_/"

maincfg[1]=_hud_descriptions.cfg
   cfgs[1]=hud_*.cfg
 prefix[1]="/^seta? hud_/"

errord=false

for index in 0 1; do
	countw=`awk ''"${prefix[index]}"' { print $2; }' "${maincfg[index]}" | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
	for b in ${cfgs[index]}; do
		countb=`awk ''"${prefix[index]}"' { print $2; }' "$b" | sort -u | tr -d '\r' | git hash-object --stdin | cut -c 1-32`
		if [ "$countw" != "$countb" ]; then
			echo "Mismatch between "${maincfg[index]}" and $b. Aborting."
			echo "Differences are:"
			echo "< missing in $b"
			echo "> must get removed from $b"
			A=`mktemp || echo a.tmp`
			B=`mktemp || echo b.tmp`
			awk ''"${prefix[index]}"' { print $2; }' "${maincfg[index]}"      | sort -u | tr -d '\r' > "$A"
			awk ''"${prefix[index]}"' { print $2; }' "$b"                     | sort -u | tr -d '\r' > "$B"
			diff "$A" "$B" | grep '^[<>]' | sort
			rm -f "$A" "$B"
			errord=true
		fi
	done
done

if $errord; then
	echo "Please wait for 30 seconds, so you have had enough time to read this..."
	sleep 30
fi
