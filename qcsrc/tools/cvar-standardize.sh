#!/usr/bin/env bash

set -eu
cd "${0%/*}" # move to qcsrc/tools
cd ../..

CONFIG_EXT=".cfg"
SCRIPT_IGNORE=' \/\/ script-ignore( [^"]+)?$'
# can add `// script-ignore` to the end of lines to ignore
# e.g. set g_ca 0 "Clan Arena: played in rounds, once you're dead you're out! The team with survivors wins the round" // script-ignore
# the script would otherwise change "Clan" -> "clan", and other changes
START='^(([[:space:]]*\/\/)?[[:space:]]*seta?[[:space:]]+(\w+|"\w+")[[:space:]]+([^"[:space:]]+|"[^"]*")[[:space:]]+")'
END='("[[:space:]]*(\/\/.*)?)$'
# selects all properly formatted set/seta lines, including commented out ones, excluding the script-ignore ones
LINE_SELECTOR="/$SCRIPT_IGNORE/!"
# combined regex: /^((\s*\/\/)?\s*seta?\s+(\w+|"\w+")\s+([^"\s]+|"[^"]*")\s+").*("\s*(\/\/.*)?)$/, ignoring / \/\/ script-ignore( [^"]+)?$/
#                   +~~~~~~~~~------------~~~~~~~~~~~---~~~~~~~~~~~~~~~~~----+  +-------------+
#                    +-------+            +---- \1 -+   +---------------+           \digit
#                       \2                    \4               \3
# replacements should start with \1, skip \2, \3, and \4, and end with \digit

# this script shouldn't be run on the user's .cfg files

function hash() {
	git hash-object "$1"
}

function remove_ending_period() {
	#- seta cl_test_cvar "1" "some test cvar."
	#+ seta cl_test_cvar "1" "some test cvar"
	sed -i -E "${LINE_SELECTOR}s/$START"'(.+)\.'"$END"'/\1\5\6/' "$1"
	# regex: /(.+)\./
	#         +--+
	#     \1   \5     \6
}
function change_colons_to_equals() {
	#- seta cl_test_cvar "1" "some test cvar; 0: do nothing, 1: do something"
	#+ seta cl_test_cvar "1" "some test cvar; 0 = do nothing, 1 = do something"
	# using label jumping instead of global since all matches overlap
	sed -i -E ":a; ${LINE_SELECTOR}s/$START"'(.*[[:space:]])?([^([:space:]][^:[:space:]]*):[[:space:]]+(.*)'"$END"'/\1\5\6 = \7\8/; ta' "$1"
	# regex: /(.*\s)?([^(\s][^:\s]*):\s+(.*)/
	#         +----+ +-------------+    +--+
	#     \1    \5         \6            \7   \8
}
function quote_options() {
	#- seta cl_test_cvar "1" "some test cvar (0 = do nothing, 1 = do something)"
	#+ seta cl_test_cvar "1" "some test cvar (\"0\" = do nothing, \"1\" = do something)"
	sed -i -E ":a; ${LINE_SELECTOR}s/$START"'(.*[[:space:]])?(\()?([^"[:space:]]+)[[:space:]]+=[[:space:]]+(.*)'"$END"'/\1\5\6\\"\7\\" = \8\9/; ta' "$1"
	# regex: /(.*\s)?(\()?([^"\s]+)\s+=\s+(.*)/
	#         +----+ +--+ +-------+       +--+
	#     \1    \5    \6     \7            \8   \9
}
function uppercase_notes() {
	#- seta cl_test_cvar "1" "some test cvar (warning: does nothing)"
	#+ seta cl_test_cvar "1" "some test cvar (WARNING: does nothing)"
	sed -i -E ":a; ${LINE_SELECTOR}s/$START"'(.*[[:space:]])?(\([a-zA-Z\-]*[a-z][a-zA-Z\-]*:)[[:space:]]+([^)]*\).*)'"$END"'/\1\5\U\6\E \7\8/; ta' "$1"
	# regex: /(.*\s)?(\([a-zA-Z\-]*[a-z][a-zA-Z\-]*:)\s+([^)]*\).*)/
	#         +----+ +------------------------------+   +---------+
	#     \1    \5                  \6                      \7       \8
}
function lowercase_option_first_letter() {
	#- seta cl_test_cvar "1" "some test cvar; \"0\" = Do nothing, \"1\" = Do something"
	#+ seta cl_test_cvar "1" "some test cvar; \"0\" = do nothing, \"1\" = do something"
	sed -i -E ":a; ${LINE_SELECTOR}s/$START"'(.*[[:space:]])?(\\"[^\\]*\\")[[:space:]]+=[[:space:]]+([A-Z][a-z\-]*[a-z]\b.*)'"$END"'/\1\5\6 = \l\7\8/; ta' "$1"
	# regex: /(.*\s)?(\\"[^\\]*\\")\s+=\s+([A-Z][a-z\-]*[a-z]\b.*)/
	#         +----+ +------------+       +----------------------+
	#     \1    \5         \6                        \7             \8
}
function lowercase_first_letter() {
	#- seta cl_test_cvar "1" "Some test CVAR"
	#+ seta cl_test_cvar "1" "some test CVAR"
	# only affects words that start with a capital letter and have no other capital letters
	# ... otherwise we assume the capitalization is intentional (e.g. StrafeHUD)
	# also doesn't affect one-letter words (e.g. description that starts with "R G B")
	sed -i -E "${LINE_SELECTOR}s/$START"'([A-Z][a-z\-]*[a-z]\b.*)'"$END"'/\1\l\5\6/' "$1"
	# regex: /([A-Z][a-z\-]*[a-z]\b.*)/
	#         +----------------------+
	#     \1             \5             \6
}
function lowercase_after_sentences() {
	#- seta cl_test_cvar "1" "some test cvar; Does nothing"
	#+ seta cl_test_cvar "1" "some test cvar; does nothing"
	# same condition as in lowercase_first_letter()
	sed -i -E ":a; ${LINE_SELECTOR}s/$START"'(.+[:;.?!])[[:space:]]+([A-Z][a-z\-]*[a-z]\b.*)'"$END"'/\1\5 \l\6\7/; ta' "$1"
	# regex: /(.+[:;.?!])\s+([A-Z][a-z\-]*[a-z]\b.*)/
	#         +---------+   +----------------------+
	#     \1      \5                   \6             \7
}

function check() {
	find "$1" -maxdepth 1 -type f -name "*${CONFIG_EXT}" -print0 \
	| sort -z \
	| while read -r -d '' file
	do
		if [[ "$file" == "./notifications${CONFIG_EXT}" ]]
		then
			echo "Skipped $file"
			continue
		else
			echo "Checking $file"
		fi

		oldHash="$(hash "$file")"
		oldTime="$(stat -c "%Y" "$file")"

		remove_ending_period "$file"
		change_colons_to_equals "$file"
		quote_options "$file"
		uppercase_notes "$file"
		lowercase_option_first_letter "$file"
		lowercase_first_letter "$file"
		lowercase_after_sentences "$file"
		# Americanizing spelling will have to be done manually

		newHash="$(hash "$file")"
		if [[ "$newHash" == "$oldHash" ]]
		then
			touch -d @"$oldTime" "$file"
		fi
	done
}

check .

if [ -n "$(git diff)" ]
then
	echo "$0: Changes produced, please commit or ignore with ' // script-ignore [reason]'"
fi
