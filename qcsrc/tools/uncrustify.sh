fix_function_types() {
	# Uncrustify handles QC function types (example:
	#  void(void) func;
	# ) wrong and removes the space between type and variable. Fix this by
	# a simple sed on ")letter" which should normally not occur.
	sed -e 's/)\([A-Za-z_]\)/) \1/g' "$@"
}

fix_class() {
	# uncrustify changes stuff like `class(WaypointSprite) .float helpme;`
	# into `class(WaypointSprite).float helpme;` - revert it
	sed -E -e 's/(class\([A-Za-z1-9_]+\))(\.[A-Za-z1-9_]+)/\1 \2/g' "$@"
}

if [ -z "$UNCRUSTIFY_CONFIG" ]; then
	UNCRUSTIFY_CONFIG=`git rev-parse --show-toplevel`/qcsrc/uncrustify.cfg
fi

case "$#" in
	0)
		uncrustify --frag -c "$UNCRUSTIFY_CONFIG" |\
		fix_function_types |\
		fix_class
		;;
	*)
		uncrustify --replace --no-backup -c "$UNCRUSTIFY_CONFIG" "$@" ;\
		fix_function_types -i "$@";\
		fix_class -i "$@"
		;;
esac
