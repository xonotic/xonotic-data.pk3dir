#!/usr/bin/env bash
CPP=${CPP:-cpp}
QCC=${QCC:-$PWD/../../gmqcc/gmqcc${CMAKE_EXECUTABLE_SUFFIX}}
case $1 in
    compile)
        for var in "$@"; do case "$var" in
            -I*)
                home=${var:2}
                break
                ;;
        esac; done
        ${CPP} ${@:3} \
            | sed -E "s|${home}|~|g" \
            | sed -E 's/^#(line)? ([[:digit:]]+) "(.*)".*/'$'\\\n''#pragma file(\3)'$'\\\n''#pragma line(\2)/g' \
            > $2
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
