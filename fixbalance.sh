#!/bin/sh

main=balanceXonotic.cfg
for X in balance*.cfg; do
	case "$X" in
		"$main")
			;;
		*)
			perl ../../misc/tools/cfgapply.pl "$main" "$X" > "$X.new" && mv "$X.new" "$X"
			;;
	esac
done
git diff
