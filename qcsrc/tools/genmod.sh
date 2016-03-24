#!/bin/bash
set -eu
cd "$(dirname "$0")"
cd ..

MOD=_mod.inc

function genmod() {
    echo '// generated file; do not modify' > ${MOD}
    for f in $(ls | sort -k 1,1 -t .); do
        if [[ "$f" == *.qc ]]; then echo "#include \"$f\"" >> ${MOD}; fi
    done
    # echo >> ${MOD}
    for f in *; do if [ -d "$f" ]; then
        (cd -- "$f" && genmod)
        # echo "#include \"$f/MOD\"" >> ${MOD}
    fi; done
}

(cd lib; genmod)
(cd common; genmod)
(cd client; genmod)
(cd server; genmod)
(cd menu; genmod)
