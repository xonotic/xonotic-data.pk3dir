#!/bin/sh

for VM in menu csprogs; do
	case "$VM" in
		csprogs)
			VMD=client
			;;
		*)
			VMD=$VM
			;;
	esac
	{
		find qcsrc/"$VMD" -type f -not -name \*.po -not -name \*.txt
		find qcsrc/common -type f -not -name \*.po -not -name \*.txt
		find qcsrc/server -type f -name w_\*.qc
	} | xgettext -LC -k_ -f- --from-code utf-8 -o "$VM".dat.pot >&2
	for X in "$VM".dat.*.po; do
		[ -f "$X" ] || continue
		msgmerge -F -U "$X" "$VM".dat.pot >&2
		todo=$(
			msgattrib --untranslated "$X" | grep -A 2147483647 "^#:"
			msgattrib --fuzzy "$X"        | grep -A 2147483647 "^#:"
		)
		if [ -n "$todo" ]; then
			echo "TODO for translation $X:"
			echo "$todo"
			echo
		fi
	done
done
