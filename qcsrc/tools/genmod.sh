#!/usr/bin/env bash
set -eu

# This script creates / updates the _mod.qc / _mod.qh / _mod.inc files based on
# the qc / qh files present in the qcsrc folder.

cd ${0%/*}
cd ..
ROOT=$PWD/

MOD=_mod

function hash() {
    git hash-object $1
}

function genmod() {
    # use context to work around cmake issue #12619
    CTX="${PWD#$ROOT}/"
    if [ -f ${MOD}.inc ]; then
        oldHashC=$(hash ${MOD}.inc)
        oldTimeC=$(stat -c "%Y" ${MOD}.inc)
    fi
    if [ -f ${MOD}.qh ]; then
        oldHashH=$(hash ${MOD}.qh)
        oldTimeH=$(stat -c "%Y" ${MOD}.qh)
    fi
    echo '// generated file; do not modify' > ${MOD}.inc
    echo '// generated file; do not modify' > ${MOD}.qh
    for f in $(ls | sort -k 1,1 -t .); do
          if [[ "$f" == cl_* ]]; then f="${f#cl_}"; if [[ -f "$f" ]]; then continue; fi
        elif [[ "$f" == sv_* ]]; then f="${f#sv_}"; if [[ -f "$f" ]]; then continue; fi
        elif [[ "$f" == ui_* ]]; then f="${f#ui_}"; if [[ -f "$f" ]]; then continue; fi
        fi
        if [[ "$f" == *.qc ]]; then
            if [[ -f "$f" ]]; then echo -e "#include <${CTX}$f>" >> ${MOD}.inc; fi
            if [[ -f "${f%.qc}.qh" ]]; then echo -e "#include <${CTX}${f%.qc}.qh>" >> ${MOD}.qh; fi
            if [[ -f "cl_$f" ]]; then echo -e "#ifdef CSQC\n    #include <${CTX}cl_$f>\n#endif" >> ${MOD}.inc; fi
            if [[ -f "cl_${f%.qc}.qh" ]]; then echo -e "#ifdef CSQC\n    #include <${CTX}cl_${f%.qc}.qh>\n#endif" >> ${MOD}.qh; fi
            if [[ -f "sv_$f" ]]; then echo -e "#ifdef SVQC\n    #include <${CTX}sv_$f>\n#endif" >> ${MOD}.inc; fi
            if [[ -f "sv_${f%.qc}.qh" ]]; then echo -e "#ifdef SVQC\n    #include <${CTX}sv_${f%.qc}.qh>\n#endif" >> ${MOD}.qh; fi
            if [[ -f "ui_$f" ]]; then echo -e "#ifdef MENUQC\n    #include <${CTX}ui_$f>\n#endif" >> ${MOD}.inc; fi
            if [[ -f "ui_${f%.qc}.qh" ]]; then echo -e "#ifdef MENUQC\n    #include <${CTX}ui_${f%.qc}.qh>\n#endif" >> ${MOD}.qh; fi
        fi
    done
    declare -l rec=1
    if [[ -f "_all.inc" ]]; then rec=0; fi
    for f in *; do if [ -d "$f" ]; then
        (cd -- "$f" && genmod)
        if [[ $rec == 1 ]]; then
            rec=2
            echo >> ${MOD}.inc
            echo >> ${MOD}.qh
        fi
        if [[ $rec != 0 ]]; then
            declare -l mod=_mod
            if [[ -f "$f/_all.inc" ]]; then mod=_all; fi
            echo "#include <${CTX}$f/${mod}.inc>" >> ${MOD}.inc
            echo "#include <${CTX}$f/${mod}.qh>" >> ${MOD}.qh
        fi
    fi; done
    newHashC=$(hash ${MOD}.inc)
    if [[ $newHashC == $oldHashC ]]; then touch -d @$oldTimeC ${MOD}.inc; fi
    newHashH=$(hash ${MOD}.qh)
    if [[ $newHashH == $oldHashH ]]; then touch -d @$oldTimeH ${MOD}.qh; fi
}

(cd lib; genmod)
(cd common; genmod)
(cd ecs; genmod)
(cd client; genmod)
(cd server; genmod)
(cd menu; genmod)
