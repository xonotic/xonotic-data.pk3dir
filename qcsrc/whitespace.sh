#!/usr/bin/env bash

find . -type f -print0 |                                    \
    xargs -0 sed -i                                         \
        `# strip trailing spaces`                           \
        -e 's/[[:space:]]*$//'                              \
        `# line feed at EOF for #include to work properly`  \
        -e '$a\'
