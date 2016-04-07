#!/bin/bash
set -eu
cd "$(dirname "$0")"
cd ..

MOD=_mod

function genmod() {
    echo '// generated file; do not modify' > ${MOD}.inc
    echo '// generated file; do not modify' > ${MOD}.qh
    for f in $(ls | sort -k 1,1 -t .); do
        if [[ "$f" == cl_* ]]; then if [[ -f "${f#cl_}" ]]; then continue; fi; fi
        if [[ "$f" == sv_* ]]; then if [[ -f "${f#sv_}" ]]; then continue; fi; fi
        if [[ "$f" == ui_* ]]; then if [[ -f "${f#ui_}" ]]; then continue; fi; fi
        if [[ "$f" == *.qc ]]; then
            echo "#include \"$f\"" >> ${MOD}.inc
            echo "#include \"${f%.qc}.qh\"" >> ${MOD}.qh
            if [[ -f "cl_$f" ]]; then echo -e "#ifdef CSQC\n    #include \"cl_$f\"\n#endif" >> ${MOD}.inc; fi
            if [[ -f "sv_$f" ]]; then echo -e "#ifdef SVQC\n    #include \"sv_$f\"\n#endif" >> ${MOD}.inc; fi
            if [[ -f "ui_$f" ]]; then echo -e "#ifdef MENUQC\n    #include \"ui_$f\"\n#endif" >> ${MOD}.inc; fi
        fi
    done
    # echo >> ${MOD}
    for f in *; do if [ -d "$f" ]; then
        (cd -- "$f" && genmod)
        # echo "#include \"$f/MOD\"" >> ${MOD}
    fi; done
}

(cd lib; genmod)
(cd ecs; genmod)
(cd common; genmod)
(cd client; genmod)
(cd server; genmod)
(cd menu; genmod)
