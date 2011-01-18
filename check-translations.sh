find qcsrc/menu -type f -not -name \*.po -not -name \*.txt | xgettext -LC -k_ -f- --from-code utf-8 -o menu.dat.pot >&2

for X in menu.dat.*.po; do
	msgmerge -U "$X" menu.dat.pot >&2
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
