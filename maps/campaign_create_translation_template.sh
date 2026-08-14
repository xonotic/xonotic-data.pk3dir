#!/bin/sh

# This script creates translation template files for every campaign*.txt file
# in the current directory

for campaign_filename in campaign*.txt; do
	# convert Windows newlines (\r\n) to Unix newlines (\n)
	# ^//campaign: --> @@@@//campaign:
	# remove comments
	# remove level settings and add translation lines with //tr:  "",           ""
	# remove empty lines
	# ^@@@@//campaign:* --> //campaign:*\n//tr:  \n\n//translators: ""
	# add empty lines above English strings
	sed \
		-e 's/\r\n/\n/g' \
		-e 's/^\/\/campaign:/@@@@\/\/campaign:/g' \
		-e 's/^\/\/.*//g' \
		-e 's/\([^,]*,\)\{7\} *\(.*\)/       \2\n\/\/tr:  \"\"\,           \"\"/g' \
		-e '/^$/d' \
		-e 's/^@@@@\/\/campaign:\(.*\)/\/\/campaign:\1\n\/\/tr:  \"\"\n\n\/\/translators: /g' \
		-e 's/^       /\n       /g' \
		< "${campaign_filename}" > "${campaign_filename}.tr._template"
done
