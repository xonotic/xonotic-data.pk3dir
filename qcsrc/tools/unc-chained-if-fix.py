#!/usr/bin/env python3

# converts code like
# ```
# if (some_long_condition)
# if (some_other_long_condition)
# ```
# into
# ```
# if (some_long_condition
#     && some_other_long_condition)
# ```

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
        |
            (?:                     # i am not sure why this branch is necessary
                [^()\n]*\([^()\n]*\)[^()\n]*
            )+
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
            |
                (?:
                    [^()\n]*\([^()\n]*\)[^()\n]*
                )+
            )+
        )
    \)
    (?<comms>
        [\t ]*
        (?://.*|/\*.*\*/)?
    )
    \n
)+
(?=
    (?<then_indent>
        [\t ]*
    )
    (?<then>
        [^{}\n].*\n
    |
        \{
            (?<block>
                [^{}]*
            |
                [^{}]*
                \{
                    (?&block)*
                \}
                [^{}]*
            |
                (?:
                    [^{}]*
                    \{
                    [^{}]*
                    \}
                    [^{}]*
                )+
            )+
        \}
    )
)
""", regex.VERBOSE)

def count_indents(whitespace: str):
    count = 0.0
    for c in whitespace:
        if c == '\t':
            count += 1.0
        elif c == ' ':
            count += 0.25
        else:
            assert False
    if not count.is_integer():
        print("WARNING - non-integer sized indent")
    return count


all_files = set(glob.glob('**/*.qc', recursive=True) + glob.glob('**/*.qh', recursive=True))
all_files = sorted({f for f in all_files if not f.startswith('qcsrc/dpdefs')})

if 0:  # for debugging
    all_files = ["qcsrc/common/mutators/mutator/buffs/sv_buffs.qc", "qcsrc/common/mutators/mutator/campcheck/sv_campcheck.qc", "qcsrc/common/weapons/weapon/minelayer.qc", "qcsrc/server/bot/default/navigation.qc"]

total = 0
total_fixed = 0
for file_name in all_files:
    with open(file_name, 'r+') as f:
        print()
        print(file_name)
        print("=================")
        print()

        old_code = f.read()

        def repl(match):
            global total, total_fixed

            total += 1

            indent = match.group('indent')
            whitespace = match.group('ws')
            first_cond = match.group('cond')
            first_comment = match.group('comm')

            other_conds = match.captures('conds')
            other_comments = match.captures('comms')

            middle_conds = other_conds[0:-1]
            middle_comments = other_comments[0:-1]

            assert len(middle_conds) == len(middle_comments)

            last_cond = other_conds[-1]
            last_comment = other_comments[-1]

            then_indent = match.group('then_indent')
            then = match.group('then')
            then_end = match.end('then')
            next_code = old_code[then_end : then_end + 50]  # won't error when past end
            contains_else = regex.search("^[\n\t ]*else", next_code) != None

            if then.startswith("if"):
                print("WARNING - then if", count_indents(indent), count_indents(then_indent))
            if then.startswith("//") or then.startswith("/*"):
                print("WARNING - then comment", count_indents(indent), count_indents(then_indent))
            if contains_else:
                print("WARNING - else after {} ifs - skipping".format(len(other_conds) + 1))
            print("whole match:")
            print(match.group(0))
            print("lines:", len(match.group(0).split('\n')))
            print("indent:", indent)
            print("first cond:", first_cond)
            print("first comm:", first_comment)
            print("other conds:", other_conds)
            print("other comms:", other_comments)
            print("then:", then)
            print("next:", next_code)

            if contains_else:
                return str(match.group(0))

            total_fixed += 1

            print()
            print()

            def fix_logical_ops(cond):
                #return cond  # for debugging
                if '||' in cond or '^' in cond:
                    return '(' + cond + ')'
                else:
                    return cond

            #replacement = "\n{}if{}({}){}\n".format(indent, whitespace, fix_logical_ops(first_cond), first_comment)
            #for cond, comm in zip(middle_conds, middle_comments):
            #    replacement += "{}if{}({}){}\n".format(indent, whitespace, fix_logical_ops(cond), comm)
            #replacement += "{}if{}({}){}\n".format(indent, whitespace, fix_logical_ops(last_cond), last_comment)

            replacement = "\n{}if{}({}{}\n".format(indent, whitespace, fix_logical_ops(first_cond), first_comment)
            for cond, comm in zip(middle_conds, middle_comments):
                replacement += "{}\t&& {}{}\n".format(indent, fix_logical_ops(cond), comm)
            replacement += "{}\t&& {}){}\n".format(indent, fix_logical_ops(last_cond), last_comment)

            return replacement

        new_code = CHAINED_IF_REGEX.sub(repl, old_code)

        f.seek(0)
        f.truncate()
        f.write(new_code)

print("total if chains:", total)
print("fixed:", total_fixed)
