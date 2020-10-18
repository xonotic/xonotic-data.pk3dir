#!/bin/sh

# We store:
#   .tx/merge-base - changed whenever translations get merged

mergebase=`git log --pretty=oneline -1 .tx/merge-base | cut -d ' ' -f 1`

set -e

mode=$1
case "$mode" in
	all)
		push_pot=true
		sync_po=true
		;;
	pot)
		push_pot=true
		sync_po=false
		;;
	po)
		push_pot=false
		sync_po=true
		;;
	*)
		echo "Usage: $0 [all|pot|po]"
		exit 1
		;;
esac

if $push_pot; then
	# Update the .pot.
	sh check-translations.sh pot

	# First upload our current .pot.
	mkdir -p translations/xonotic.commonpot/
	cp common.pot translations/xonotic.commonpot/en..po
	tx push -s
fi

if $sync_po; then
	# Then pull the rest.
	tx pull -f -a

	for f in common.*.po; do
		lang=${f%.po}
		lang=${lang#common.}
		case "$lang" in
			de_CH)
				continue
				;;
		esac
		tcurfile=translations/xonotic.commonpot/$lang..po
		goldfile=translations/xonotic.commonpot/$lang..po.orig
		gnewfile=common.$lang.po
		if [ -f "$tcurfile" ]; then
			git show "$mergebase":"$gnewfile" > "$goldfile"
			msgmerge -N -F -U "$tcurfile" common.pot
			msgmerge -N -F -U "$goldfile" common.pot
			msgmerge -N -F -U "$gnewfile" common.pot
			if diff -u "$goldfile" "$gnewfile" >/dev/null; then
				# no change on git, changed on tx only
				msgmerge -N -F -U "$tcurfile" common.pot
				cp "$tcurfile" "$gnewfile"
			else
				if ! diff -u "$goldfile" "$gnewfile" | patch "$tcurfile"; then
					if [ -z "$BATCH" ]; then
						while :; do
							vim -o "$tcurfile.rej" "$tcurfile"
							echo "OK?"
							read -r OK || exit 1
							[ x"$OK" != x"y" ] || break
						done
						rm -f "$tcurfile.rej"
					fi
				fi
				msgmerge -N -F -U "$tcurfile" common.pot
				cp "$tcurfile" "$gnewfile"
			fi
			rm "$goldfile"
		else
			msgmerge -N -F -U "$gnewfile" common.pot
			cp "$gnewfile" "$tcurfile"
		fi
	done
	for f in translations/xonotic.commonpot/*..po; do
		lang=${f%..po}
		lang=${lang#translations/xonotic.commonpot/}
		[ x"$lang" != x"en" ] || continue
		tcurfile=translations/xonotic.commonpot/$lang..po
		gnewfile=common.$lang.po
		if ! [ -f "$gnewfile" ]; then
			touch "$gnewfile"
			git add "$gnewfile"
			cp "$tcurfile" "$gnewfile"
		fi
	done
	tx push -t --skip
	date > .tx/merge-base

	# Generate Swiss Standard German from German.
	msgfilter -i common.de.po -o common.de_CH.po perl -pe '
		# Character filters go here.
		s/ß/ss/g;
		# Word filters go here. By default we match even inside words, as there
		# are constructs like ^BGflag where "flag" is the actual word. Make
		# sure to not commit the clbuttical mistake.
		s/eventuell/allfällig/g;
	'

	# Build new languages list.
	sh check-translations.sh txt > languages.txt.new
	mv languages.txt.new languages.txt

	# Report stats.
	git diff --stat
	git diff --color-words languages.txt
fi
