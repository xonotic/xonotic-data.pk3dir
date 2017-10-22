#!/usr/bin/env python3

import regex # needs regex instead of re for multiple captures of a group
import glob

# this is soooooo not regular ;)
CHAINED_IF_REGEX = regex.compile(r"""
(?:^|\n)
(?<indent>
    [\t ]*
)
if(?<ws>[\t ]*)                     # the first if
\(
    (?<cond>                        # the condition itself
        (?<expr1>                   # various parts of the condition, not exactly an expression but anything separated by parens
            [^()\n]*
        |
            [^()\n]*\(
                (?&expr1)           # this is to match nested parentheses correctly
            \)[^()\n]*
        )+
    )
\)
(?<comm>                            # trailing comments
    [\t ]*
    (?://.*|/\*.*\*/)?
)
\n
(?:                                 # all subsequent ifs with the same indentation
    \1
    if[\t ]*
    \(
        (?<conds>
            (?<expr2>
                [^()\n]*
            |
                [^()\n]*\(
                    (?&expr2)
                \)[^()\n]*
            )+
        )
    \)
    (?<comms>
        [\t ]*
        (?://.*|/\*.*\*/)?
    )
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

            indent = match.group('indent')
            whitespace = match.group('ws')
            first_cond = match.group('cond')
            first_comment = match.group('comm')

            other_conds = match.captures('conds')
            other_comments = match.captures('comms')
            assert len(middle_conds) == len(middle_comments)

            middle_conds = other_conds[0:-1]
            middle_comments = other_comments[0:-1]

            last_cond = other_conds[-1]
            last_comment = other_comments[-1]

            #logical_ops = '||' in match.group(0) or '^' in match.group(0)

            print("whole match:")
            print(match.group(0))
            print("lines:", len(match.group(0).split('\n')))
            print("indent:", indent)
            print("first cond:", first_cond)
            print("first comm:", first_comment)
            print("other conds:", other_conds)
            print("other comms:", other_comments)
            #print("captures expr1:", match.captures('expr1'))
            #print("captures expr2:", match.captures('expr2'))
            #if logical_ops:  # TODO per cond
            #    print("WARNING - logical ops")

            print()
            print()

            def fix_logical_ops(cond):
                if '||' in cond or '^' in cond:
                    return '(' + cond + ')'
                else:
                    return cond

            replacement = "\n{}if{}({}){}\n".format(indent, whitespace, fix_logical_ops(first_cond), first_comment)
            for cond, comm in zip(middle_conds, middle_comments):
                replacement += "{}if{}({}){}\n".format(indent, whitespace, fix_logical_ops(cond), comm)
            replacement += "{}if{}({}){}\n".format(indent, whitespace, fix_logical_ops(last_cond), last_comment)

            #replacement = "\n{}if{}({}{}\n".format(indent, whitespace, fix_logical_ops(first_cond), first_comment)
            #for cond, comm in zip(middle_conds, middle_comments):
            #    replacement += "{}\t&& {}{}\n".format(indent, fix_logical_ops(cond), comm)
            #replacement += "{}\t&& {}){}\n".format(indent, fix_logical_ops(last_cond), last_comment)

            #return str(match.group(0))
            return replacement

        old_code = f.read()
        new_code = CHAINED_IF_REGEX.sub(repl, old_code)
        #with open('new-code', 'w') as f:
        #    f.write(new_code)

        f.seek(0)
        f.truncate()
        f.write(new_code)

print("total if chains:", total)
