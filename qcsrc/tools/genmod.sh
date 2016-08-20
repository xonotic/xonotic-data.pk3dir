#!/usr/bin/env bash
set -eu
cd ${0%/*}
cd ..
ROOT=$PWD/

MOD=_mod

function genmod() {
    # use context to work around cmake issue #12619
    CTX="${PWD#$ROOT}/"
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
    # echo >> ${MOD}
    for f in *; do if [ -d "$f" ]; then
        (cd -- "$f" && genmod)
        # echo "#include \"$f/MOD\"" >> ${MOD}
    fi; done
}

(cd lib; genmod)
(cd common; genmod)
(cd ecs; genmod)
(cd client; genmod)
(cd server; genmod)
(cd menu; genmod)
