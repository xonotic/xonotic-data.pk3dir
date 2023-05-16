#!/bin/sh

set -e

case "$1" in
	pot)
		mode=pot
		mail=false
		;;
	txt)
		mode=txt
		mail=false
		;;
	po)
		mode=po
		mail=true
		language=$2
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

if [ x"$mode" = x"pot" ]; then
	{
		git ls-files qcsrc | sort -u
	} | xgettext -LC -k_ -f- --from-code utf-8 -F -o common.pot.new >&2
	if msgcmp -N --use-untranslated common.pot common.pot.new && msgcmp -N --use-untranslated common.pot.new common.pot; then
		echo "No contentful changes to common.pot - OK."
		ls -la common.pot common.pot.new
		rm -f common.pot.new
	else
		echo "Updating common.pot. This probably should be committed."
		mv -v common.pot.new common.pot
	fi
fi

if [ x"$mode" = x"txt" ]; then
	{
		item=`grep "^en " languages.txt`
		echo "$item"
		for X in common.*.po; do
			[ -f "$X" ] || continue
			if [ -n "$language" ]; then
				if [ x"${X#common.}" != x"$language.po" ]; then
					continue
				fi
			else
				if [ x"${X#common.}" = x"en.po" ]; then
					continue
				fi
			fi
			# Note: we're only reporting EXISTING fuzzy matches in the Fuzzy count, thus -N.
			po=`msgmerge -N "$X" common.pot`
			ne=`printf "%s\n" "$po" | msgfmt -o /dev/null --check-format --check-header --use-fuzzy - 2>&1 | grep . | wc -l || true`
			nu=`printf "%s\n" "$po" | msgattrib --untranslated - | grep -c ^#: || true`
			nf=`printf "%s\n" "$po" | msgattrib --fuzzy - | grep -c ^#: || true`
			nt=`printf "%s\n" "$po" | grep -c ^#: || true`
			n=$(($ne + $nu + $nf))
			p=$(( (nt - n) * 100 / nt ))
			echo >&2 "TODO for translation $X:"
			echo >&2 "Errors:       $ne"
			echo >&2 "Untranslated: $nu"
			echo >&2 "Fuzzy:        $nf"
			echo >&2 "Total:        $nt"
			echo >&2 "Percent:      $p"
			l=${X#common.}
			l=${l%.po}
			if ! item=`grep "^$l " languages.txt`; then
				if [ "$p" -lt 50 ]; then
					continue
				fi
				item="$l \"$l\" \"$l\" 0%"
			fi
			printf "%s\n" "$item" | sed -e "s/[0-9][0-9]*%/$p%/"
		done
	} | LC_ALL=C sort -t '"' -k4,4
fi

if [ x"$mode" = x"po" ]; then
	for X in common.*.po; do
		[ -f "$X" ] || continue
		if [ -n "$language" ]; then
			if [ x"${X#common.}" != x"$language.po" ]; then
				continue
			fi
		else
			if [ x"${X#common.}" = x"en.po" ]; then
				continue
			fi
		fi
		# Note: no -N here, this is the point where we allow fuzzy matching.
		msgmerge -F -U "$X" common.pot >&2
		msgfmt -o /dev/null --check-format --check-header --use-fuzzy "$X" 2>&1 \
		                              | grep . > "$X".errors       || rm -f "$X".errors
		msgattrib --untranslated "$X" | grep . > "$X".untranslated || rm -f "$X".untranslated
		msgattrib --fuzzy "$X"        | grep . > "$X".fuzzy        || rm -f "$X".fuzzy
		ne=$((`wc -l <     "$X".errors       2>/dev/null` + 0))
		nu=$((`grep -c ^#: "$X".untranslated 2>/dev/null` + 0))
		nf=$((`grep -c ^#: "$X".fuzzy        2>/dev/null` + 0))
		n=$(($ne + $nu + $nf))
		changed=false
		for Y in ~/check-translations/"$X".*; do
			[ -f "$Y" ] || continue
			echo "Merging $Y..."
			vim -E "$Y" <<EOF
set fileencoding=utf-8
set nobomb
w
q
EOF
			if ! msgcat "$Y" >/dev/null; then
				echo "File $Y has syntax errors. Skipped."
				continue
			fi
			msgcat -F --use-first "$Y" "$X" > "$X".new
			mv "$X".new "$X"
			changed=true
		done
		ne0=$ne
		nu0=$nu
		nf0=$nf
		if $changed; then
			msgfmt -o /dev/null --check-format --check-header --use-fuzzy "$X" 2>&1 \
						      | grep . > "$X".errors       || rm -f "$X".errors
			msgattrib --untranslated "$X" | grep . > "$X".untranslated || rm -f "$X".untranslated
			msgattrib --fuzzy "$X"        | grep . > "$X".fuzzy        || rm -f "$X".fuzzy
			ne=$((`wc -l <     "$X".errors       2>/dev/null` + 0))
			nu=$((`grep -c ^#: "$X".untranslated 2>/dev/null` + 0))
			nf=$((`grep -c ^#: "$X".fuzzy        2>/dev/null` + 0))
			n=$(($ne + $nu + $nf))
		fi
		if [ $n -gt 0 ]; then
			echo "TODO for translation $X:"
			echo "Errors:       $ne (was: $ne0)"
			echo "Untranslated: $nu (was: $nu0)"
			echo "Fuzzy:        $nf (was: $nf0)"
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
							if [ $ne -gt 0 ]; then
								attach="$attach $X.errors"
							fi
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

For reference, the current version of the translation file is at:
http://git.xonotic.org/?p=xonotic/xonotic-data.pk3dir.git;a=blob;f=$X

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
								-b "admin@xonotic.org" \
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
		else
			echo "$X is complete!"
		fi
	done

	for X in common.*.po.disabled; do
		[ -f "$X" ] || continue
		if [ -n "$language" ]; then
			if [ x"${X#common.}" != x"$language.po" ]; then
				continue
			fi
		fi
		# Note: no -N here, this is the point where we allow fuzzy matching.
		msgmerge -F -U "$X" common.pot >/dev/null 2>&1
	done
fi
