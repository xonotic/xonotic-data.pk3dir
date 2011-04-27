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
		msgattrib --untranslated "$X" | grep . > "$X".untranslated || rm -f "$X".untranslated
		msgattrib --fuzzy "$X"        | grep . > "$X".fuzzy        || rm -f "$X".fuzzy
		nu=$((`grep -c ^#: "$X".untranslated` + 0))
		nf=$((`grep -c ^#: "$X".fuzzy`        + 0))
		n=$(($nu + $nf))
		if [ $n -gt 0 ]; then
			echo "TODO for translation $X:"
			echo "Untranslated: $nu"
			echo "Fuzzy:        $nf"
			ltr=`grep '^"Last-Translator: ' "$X" | cut -d ' ' -f 2- | cut -d '\\' -f 1 | egrep -v '<LL@li.org>|<EMAIL@ADDRESS>'`
			ltm=`grep '^"Language-Team: ' "$X" | cut -d ' ' -f 2- | cut -d '\\' -f 1 | egrep -v '<LL@li.org>|<EMAIL@ADDRESS>'`
			echo "Translators:  $ltr, $ltm"
			case "$ltr" in
				'')
					to=$ltm
					cc=
					;;
				*)
					to=$ltr
					if [ x"$ltr" = x"$ltm" ]; then
						cc=
					else
						cc=$ltm
					fi
					;;
			esac
			if [ -n "$to" ]; then
				echo "To:           $to"
			fi
			if [ -n "$cc" ]; then
				echo "Cc:           $cc"
			fi
			if [ -n "$to" ]; then
				while :; do
					echo "Send mail? [y/n]"
					read -r yesno
					case "$yesno" in
						y)
							zip -9r "$X"-todo.zip "$X".untranslated "$X".fuzzy
							{
								cat <<EOF
Hi,

we need updates to the translations you made for Xonotic.

EOF
								if [ $nu -gt 0 ]; then
									cat <<EOF
The attached zip file contains a file
$X.untranslated
with $nu yet to be translated messages. Please translate them and reply with
the file containing the translations in the "msgstr" fields.

EOF
								fi
								if [ $nf -gt 0 ]; then
									cat <<EOF
The attached zip file contains a file
$X.fuzzy
with $nf automatically generated translations. Please verify and/or fix them
and reply with the file having been verified by you.

EOF
								fi
								cat <<EOF
Thanks in advance,

Team Xonotic
EOF
							} | mail \
								-s "Need update for translations: $X" \
								-a "$X"-todo.zip \
								-c "$cc" \
								-b "divVerent@xonotic.org" \
								-S from="divVerent@xonotic.org" \
								"$to"
EOF
						n)
							break
							;;
					esac
				done
			fi
		fi
	done
	for X in "$VM".dat.*.po.disabled; do
		[ -f "$X" ] || continue
		msgmerge -F -U "$X" "$VM".dat.pot >/dev/null 2>&1
	done
done
