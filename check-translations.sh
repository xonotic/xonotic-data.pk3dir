#!/bin/sh

case "$1" in
	pot)
		mode=pot
		mail=true
		;;
	po)
		mode=po
		mail=true
		language=
		;;
	'')
		echo "Sorry, you are not supposed to use this script."
		echo "This script is solely for use by the Xonotic Core Team."
		echo "Unauthorized use of it can cause HIGHLY annoying merge"
		echo "conflicts."
		exit 1
		;;
	*)
		mode=po
		mail=false
		language=$1
		;;
esac

for VM in menu csprogs; do
	case "$VM" in
		csprogs)
			VMD=client
			;;
		*)
			VMD=$VM
			;;
	esac

	if [ x"$mode" = x"pot" ]; then
		{
			find qcsrc/"$VMD" -type f -not -name \*.po -not -name \*.txt
			find qcsrc/common -type f -not -name \*.po -not -name \*.txt
			find qcsrc/server -type f -name w_\*.qc
		} | xgettext -LC -k_ -f- --from-code utf-8 -o "$VM".dat.pot >&2
	fi

	if [ x"$mode" = x"po" ]; then
		for X in "$VM".dat.*.po; do
			[ -f "$X" ] || continue
			if [ -n "$language" ]; then
				if [ x"${X#*.dat.}" != x"$language.po" ]; then
					continue
				fi
			fi
			for Y in ~/check-translations/"$X".*; do
				[ -f "$Y" ] || continue
				msgcat -F --use-first "$Y" "$X" > "$X".new
				mv "$X".new "$X"
			done
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
					while $mail; do
						echo "Send mail? [y/n]"
						read -r yesno
						case "$yesno" in
							y)
								attach=
								if [ $nu -gt 0 ]; then
									attach="$attach $X.untranslated"
								fi
								if [ $nf -gt 0 ]; then
									attach="$attach $X.fuzzy"
								fi
								{
									cat <<EOF
Hi,

as you provided us with translations in the past, we kindly ask you
to update the translation to match changes in the Xonotic source. Can
you please work on them and provide updates to us?

If you do not wish to be contacted for translation updates any more,
please tell us in a reply to this message.

EOF
									if [ $nu -gt 0 ]; then
										cat <<EOF
Attached to this message is a file
$X.untranslated
with $nu yet to be translated messages. Please translate them and reply
with the file containing the translations in the "msgstr" fields.

EOF
									fi
									if [ $nf -gt 0 ]; then
										cat <<EOF
Attached to this message is a file
$X.fuzzy
with $nf automatically generated translations. Please verify and/or fix
them and reply with the file having been verified by you.

EOF
									fi
									cat <<EOF
Thanks in advance,

Team Xonotic
EOF
								} | mutt \
									-e "set from=\"divVerent@xonotic.org\"" \
									-e "set use_from=yes" \
									-e "set use_envelope_from=yes" \
									-s "Need update for translations: $X" \
									-c "$cc" \
									-b "divVerent@xonotic.org" \
									-a $attach -- \
									"$to"
								break
								;;
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
			if [ -n "$language" ]; then
				if [ x"${X#*.dat.}" != x"$language.po" ]; then
					continue
				fi
			fi
			msgmerge -F -U "$X" "$VM".dat.pot >/dev/null 2>&1
		done
	fi
done
