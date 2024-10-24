#!/usr/bin/env bash
set -eu

export LC_ALL=C.UTF-8

# This script creates / updates the _mod.qc / _mod.qh / _mod.inc files based on
# the qc / qh files present in the qcsrc folder.

cd "${0%/*}" # Move to qcsrc/tools
cd .. # Move to qcsrc

ROOT="$PWD/"

MOD=_mod

function hash() {
	git hash-object "$1"
}

function genmod() {
	# use context to work around cmake issue #12619
	CTX="${PWD#"$ROOT"}/"

	if [ -f "${MOD}.inc" ]
	then
		oldHashC="$(hash ${MOD}.inc)"
		oldTimeC="$(stat -c "%Y" ${MOD}.inc)"
	fi
	if [ -f "${MOD}.qh" ]
	then
		oldHashH="$(hash ${MOD}.qh)"
		oldTimeH="$(stat -c "%Y" ${MOD}.qh)"
	fi

	echo "// $(basename "$0") autogenerated file; do not modify" > "${MOD}.inc"
	echo "// $(basename "$0") autogenerated file; do not modify" > "${MOD}.qh"

	# Dr. Jaska: TODO: replace ls with something else
	# LSP note: "Use find instead of ls to better handle non-alphanumeric filenames."
	# Dr. Jaska: find without some configuration would prefix everything with ./ which is likely unwanted
	for f in $(ls | sed -e "s/^cl_//" -e "s/^sv_//" -e "s/^ui_//" | sort -u)
	do
		# skip all files which aren't .qc files
		if [[ "$f" != *.qc ]]; then continue; fi

		# Print the following line:
		#
		# #include <file.q{c,h}>
		#
		# file.qc into _mod.inc
		# file.qh into _mod.qh
		if [[ -f "$f"          ]]; then printf "#include <%s>\n" "${CTX}$f"          >> ${MOD}.inc; fi
		if [[ -f "${f%.qc}.qh" ]]; then printf "#include <%s>\n" "${CTX}${f%.qc}.qh" >> ${MOD}.qh;  fi

		# Print the following template:
		#
		# #ifdef {CS,SV,MENU}QC
		# 	#include <file.q{c,h}>
		# #endif
		#
		# CSQC
		# cl_file.qc into _mod.inc
		# cl_file.qh into _mod.qh
		if [[ -f "cl_$f"          ]]; then printf "#ifdef %s\n\t#include <%s>\n#endif\n"   CSQC "${CTX}cl_$f"          >> ${MOD}.inc; fi
		if [[ -f "cl_${f%.qc}.qh" ]]; then printf "#ifdef %s\n\t#include <%s>\n#endif\n"   CSQC "${CTX}cl_${f%.qc}.qh" >> ${MOD}.qh;  fi
		# SVQC
		# sv_file.qc into _mod.inc
		# sv_file.qh into _mod.qh
		if [[ -f "sv_$f"          ]]; then printf "#ifdef %s\n\t#include <%s>\n#endif\n"   SVQC "${CTX}sv_$f"          >> ${MOD}.inc; fi
		if [[ -f "sv_${f%.qc}.qh" ]]; then printf "#ifdef %s\n\t#include <%s>\n#endif\n"   SVQC "${CTX}sv_${f%.qc}.qh" >> ${MOD}.qh;  fi
		# MENUQC
		# ui_file.qc into _mod.inc
		# ui_file.qh into _mod.qh
		if [[ -f "ui_$f"          ]]; then printf "#ifdef %s\n\t#include <%s>\n#endif\n" MENUQC "${CTX}ui_$f"          >> ${MOD}.inc; fi
		if [[ -f "ui_${f%.qc}.qh" ]]; then printf "#ifdef %s\n\t#include <%s>\n#endif\n" MENUQC "${CTX}ui_${f%.qc}.qh" >> ${MOD}.qh;  fi
	done

	declare -l rec=1

	if [[ -f "_all.inc" ]]
	then
		rec=0
	fi

	for f in *
	do
		if [ -d "$f" ]
		then
			(cd -- "$f" && genmod)
			if [[ $rec == 1 ]]
			then
				rec=2
				echo >> ${MOD}.inc
				echo >> ${MOD}.qh
			fi
			if [[ $rec != 0 ]]
			then
				declare -l mod=_mod

				if [[ -f "$f/_all.inc" ]]
				then
					mod=_all
				fi

				echo "#include <${CTX}$f/${mod}.inc>" >> "${MOD}.inc"
				echo "#include <${CTX}$f/${mod}.qh>"  >> "${MOD}.qh"
			fi
		fi
	done

	newHashC="$(hash ${MOD}.inc)"

	if [[ "$newHashC" == "$oldHashC" ]]
	then
		touch -d @"$oldTimeC" "${MOD}.inc"
	fi

	newHashH="$(hash ${MOD}.qh)"

	if [[ "$newHashH" == "$oldHashH" ]]
	then
		touch -d @"$oldTimeH" "${MOD}.qh"
	fi
}

(cd lib; genmod)
(cd common; genmod)
(cd ecs; genmod)
(cd client; genmod)
(cd server; genmod)
(cd menu; genmod)
