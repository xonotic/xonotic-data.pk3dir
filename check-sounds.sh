#!/bin/sh



# find all sound identifier keys:
# attackinfive coverme defend freelance incoming meet needhelp seenflag taunt teamshoot flagcarriertakingdamage
# getflag affirmative attacking defending roaming onmyway droppedflag negative seenenemy
allidentifiers=$(grep "^REGISTER_VOICEMSG(" qcsrc/common/effects/qc/globalsound.qh | sed -e 's#.*(##' -e 's#,.*##')

allsounds=$(find sound -name .svn -prune -o \( -name \*.ogg -o -name \*.wav \) -print)
for S in $allsounds
do
	SND=${S#sound/}
	SND=${SND%.*}
	if [ -f "sound/$SND.ogg" ] && [ -f "sound/$SND.wav" ]
	then
		echo "$SND exists twice"
	fi
	case "$SND" in
		player/*/*)
			# verified by .sounds file check
			;;
		ambient/*)
			# maps can use them always
			;;
		weather/*)
			# maps can use them always
			;;
		cdtracks/*)
			# maps can use them always
			;;
		misc/footstep*)
			;;
		misc/metalfootstep*)
			;;
		misc/hitground*)
			;;
		misc/metalhitground*)
			;;
		misc/talk*) # engine
			;;
		*)
			# FIXME: this requires updating to our macroes.
			# Atm this looks for sounds such as misc/typehit
			# only in qcsrc/server and is completely unaware of
			# qcsrc/common and SOUND macro there.
			if ! grep -Er '"'"$SND"'\.(ogg|wav)"' qcsrc/server >/dev/null
			then
				echo "$S ($SND) is unused by the code"
			fi
			;;
	esac
done

LF="
"
allsounds="$LF$(find sound/player -mindepth 2 -name .svn -prune -o \( -name \*.ogg -o -name \*.wav \) -print)$LF"
remainingsounds=$allsounds
psoundfile()
{
	snd=$1
	pat="$LF$snd$LF"
	case "$allsounds" in
		*$pat*)
			case "$remainingsounds" in
				*$pat*)
					# shellcheck disable=SC2295
					remainingsounds=${remainingsounds%%$pat*}$LF${remainingsounds#*$pat}
					;;
			esac
			return 0
			;;
		*)
			return 1
			;;
	esac
}
psoundtry()
{
	s=$1
	psoundfile "$s.ogg" || psoundfile "$s.wav"
}
psound()
{
	s=$1
	if ! psoundtry "$s"
	then
		echo "$S references nonexisting sound $s"
	fi
}

for S in models/player/*.sounds sound/player/default.sounds
do
	if [ "$S" = "sound/player/default.sounds" ] || [ -f "${S#.sounds}" ]
	then
		{
			identifiers_seen=
			# shellcheck disable=SC2034
			while read -r TITLE SOUND COUNT GENTLECOUNT
			do
				case "$TITLE" in
					//TAG*)
						;;
					//*)
						identifiers_seen="$identifiers_seen ${TITLE#//}"
						for X in $allidentifiers
						do
							if [ "$X" = "${TITLE#//}" ]
							then
								good=true
							fi
						done
						if $good; then
							good=false
							case "$COUNT" in
								0)
									if psoundtry "$SOUND"
									then
										good=false
									fi
									;;
								*)
									for i in $(seq 1 "$COUNT")
									do
										if psoundtry "$SOUND$i"
										then
											good=true
										fi
									done
									;;
							esac
							if $good
							then
								echo "$S references existing sound $SOUND but commented out"
							else
								echo "$S does not have a sound for ${TITLE#//} yet"
							fi
						fi
						;;
					*)
						identifiers_seen="$identifiers_seen $TITLE"
						case "$COUNT" in
							0)
								psound "$SOUND"
								;;
							*)
								for i in $(seq 1 "$COUNT")
								do
									psound "$SOUND$i"
								done
								;;
						esac
						;;
				esac
			done

			missing=$(
				{
					for X in $identifiers_seen
					do
						echo "$X"
						echo "$X"
					done
					for X in $allidentifiers
					do
						echo "$X"
					done
				} | sort | uniq -u
			)

			invalid=$(
				{
					for X in $identifiers_seen
					do
						echo "$X"
					done
					for X in $allidentifiers
					do
						echo "$X"
						echo "$X"
					done
				} | sort | uniq -u
			)
			# shellcheck disable=SC2116 disable=SC2086 # this removes newlines between identifiers
			[ -z "$invalid" ] || echo "$S specifies invalid sound identifiers $(echo $invalid)"
			# shellcheck disable=SC2116 disable=SC2086 # this removes newlines between identifiers
			[ -z "$missing" ] || echo "$S lacks sound identifiers $(echo $missing)"
		} < "$S"
	else
		echo "$S exists for nonexisting player model"
	fi
done
for S in $remainingsounds
do
	echo "$S is not used by any player model"
done

# tag check
for S in models/player/*.sounds
do
	printf "%s  " "$(head -n 1 "$S")"
	md5sum "$S"
done | sort
