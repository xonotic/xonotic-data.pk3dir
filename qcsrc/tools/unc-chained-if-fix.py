#!/usr/bin/env python3

import regex # needs regex instead of re for multiple captures of a group
import glob

# this is soooooo not regular ;)
CHAINED_IF_REGEX = regex.compile(r"""
(?:^|\n)
(?<indent>
    [\t ]*
)
if[\t ]*\(                          # the first condition
    (?<cond>
        (?<expr1>
            [^()\n]*
        |
            [^()\n]*\(
                (?&expr1)           # this is to match nested parentheses correctly
            \)[^()\n]*
        )+
    )
\)[\t ]*
(?://.*|/\*.*\*/)?                  # comments
\n
(?:                                 # all subsequent conditions with the same indentation
    \1
    if[\t ]*\(
        (?<conds>
            (?<expr2>
                [^()\n]*
            |
                [^()\n]*\(
                    (?&expr2)
                \)[^()\n]*
            )+
        )
    \)[\t ]*
    (?://.*|/\*.*\*/)?
    \n
)+
""", regex.VERBOSE)

all_files = set(glob.glob('**/*.qc', recursive=True) + glob.glob('**/*.qh', recursive=True))
all_files = sorted({f for f in all_files if not f.startswith('qcsrc/dpdefs')})

if 0:  # for debugging
    all_files = ["qcsrc/common/mutators/mutator/campcheck/sv_campcheck.qc", "qcsrc/common/weapons/weapon/minelayer.qc", "qcsrc/server/bot/default/navigation.qc"]

total = 0
for file_name in all_files:
    with open(file_name, 'r+') as f:
        print()
        print(file_name)
        print("=================")
        print()

        def repl(match):
            global total
            total += 1

            print("whole match:")
            print(match.group(0))
            print("lines:", len(match.group(0).split('\n')))
            print("captures 1:", match.captures('indent'))
            print("captures 2:", match.captures('cond'))
            print("captures 3:", match.captures('conds'))
            if '||' in match.group(0) or '^' in match.group(0):
                print("WARNING - logical ops")

            print()
            print()

            return str(match.group(0))

        old_code = f.read()
        new_code = CHAINED_IF_REGEX.sub(repl, old_code)
        #with open('new-code', 'w') as f:
        #    f.write(new_code)

        f.seek(0)
        f.truncate()
        f.write(new_code)

print("total if chains:", total)
