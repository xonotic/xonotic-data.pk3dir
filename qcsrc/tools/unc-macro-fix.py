#!/usr/bin/env python3

# removes redundant { and } from macros because uncrustify is too dumb to indent them properly (or even not touch them)

# all those fancy unix utilities like grep, sed and awk are either woefully inadequate for this or just completely
# unreadable with their arcane syntaxes - and yes, the plural is intentional because why extend existing tools
# when you can write your own with incompatible flags, commands and regex flavors, pass strings between them
# and call it the unix "philosophy"

import re
import glob

all_files = set(glob.glob("**/*.qc", recursive=True) + glob.glob("**/*.qh", recursive=True))
all_files = {f for f in all_files if not f.startswith('qcsrc/dpdefs')}

for file_name in all_files:
	with open(file_name, "r+") as f:
		s = f.read()
		s = re.sub(r"MACRO_BEGIN *(?:\\\s*)?{((?:.|\n)*?)} *(?:\\\s*)?MACRO_END", r"MACRO_BEGIN\1MACRO_END", s)
		f.seek(0)
		f.truncate()
		f.write(s)
