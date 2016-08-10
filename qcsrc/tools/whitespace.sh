#!/usr/bin/env bash
set -eu
cd ${0%/*}
cd ..

function check() {
    declare -l base="${1}"
    find "$base" -type f -print0 | sort -z | xargs -0 sed -i \
        `# strip trailing spaces`                            \
        -e 's/[[:space:]]*$//'                               \
        `# line feed at EOF for #include to work properly`   \
        -e '$a\'
}

check lib
check common
check ecs
check client
check server
check menu
