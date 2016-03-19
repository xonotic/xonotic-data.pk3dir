#!/bin/bash
QCC=${QCC:-$(dirname "$0")/../../../gmqcc/gmqcc}
case $1 in
    compile)
        echo $@
        cpp ${@:3} | sed 's/^#\(line\)\? \([[:digit:]]\+\) "\(.*\)".*/\n#pragma file(\3)\n#pragma line(\2)/g' > $2
    ;;
    link)
        ${QCC} \
        -std=gmqcc \
        -Ooverlap-locals \
        -O3 \
        -Werror -Wall \
        -Wno-field-redeclared \
        -flno -futf8 -fno-bail-on-werror \
        -frelaxed-switch -freturn-assignments \
        ${@:2}
    ;;
esac
