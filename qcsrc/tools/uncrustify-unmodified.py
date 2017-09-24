#!/usr/bin/env python3

# Finds files that are not modified on any branch and formats them.

# You should be on master or a branch that just merged master since we want to avoid conflicts when merging other branches into master.

# If you're on Windows, you probably wanna fix path separators and maybe other tihngs, I am not touching that.

from datetime import datetime, timedelta, timezone
from dateutil import parser
import glob
import os.path
import shlex
import subprocess

def main():
	if not os.path.exists("qcsrc"):
		# otherwise the files reported by different commands would have different prefixes
		print("Must be run in data repo root (xonotic-data.pk3dir)")
		return

	# get the latest changes on all branches
	run('git fetch')
	# remove merged/deleted remote branches
	run('git remote prune origin')

	# get all remote branches - those would potentially get merge conflicts if we formatted everything
	branches = run('git branch --list --remotes')
	# strip the leading spaces and ignore branches that are presumably used for debugging uncrustify
	branches = [b.strip() for b in branches if "uncrustify" not in b and "uncrustified" not in b]
	branches.remove('origin/HEAD -> origin/master')
	branches.remove('origin/master')

	all_files = set(glob.glob("**/*.qc", recursive=True) + glob.glob("**/*.qh", recursive=True))
	all_files = {f for f in all_files if not f.startswith('qcsrc/dpdefs')}
	modified_files = set()

	for branch in branches:
		print(branch)

		# getting this info is a bit slow
		last_change_str = run(r'git show --pretty=format:"%ci" {}'.format(branch))[0]
		print("\t last change:", last_change_str)

		last_change = parser.parse(last_change_str)
		if datetime.now(timezone.utc) - last_change > timedelta(days=365*2):  # who cares about leap years
			print("\t ignoring")
			continue

		# If some complex branching and merging happens, there can be multiple merge bases.
		# The diff between each of them and the tip of the branch can contain changes that are not in master
		# and could cause conflicts.
		merge_bases = run('git merge-base --all origin/master {}'.format(branch))
		for base in merge_bases:
			print("\t", base)

			# with --name-only it shows only the new name when renaming so the order matters
			# i guess diff from branch to base should be enough but let's be sure
			files1 = set(run('git diff --name-only {} {}'.format(base, branch)))
			files2 = set(run('git diff --name-only {} {}'.format(branch, base)))
			files = {f for f in files1.union(files2) if f.endswith(".qc") or f.endswith(".qh")}

			for f in sorted(files):
				print("\t\t", f)

			modified_files = modified_files.union(files)

	# modified files contain newly added files so the number of remaining files will be larger than all - modified
	remaining_files = all_files - modified_files
	nonexistent_files = modified_files - all_files

	print("all on master ({}):".format(len(all_files)))
	for f in sorted(all_files):
		print("\t", f)

	print("modified on branches ({}):".format(len(modified_files)))
	for f in sorted(modified_files):
		print("\t", f)

	print("modified files that don't exist on master ({}):".format(len(nonexistent_files)))
	for f in sorted(nonexistent_files):
		print("\t", f)

	print("formatting on master ({}):".format(len(remaining_files)))
	for f in sorted(remaining_files):
		print("\t", f)
		run("bash qcsrc/tools/uncrustify.sh {}".format(shlex.quote(f)))

def run(cmd: str) -> [str]:
	process = subprocess.Popen(shlex.split(cmd), stdin=subprocess.PIPE, stdout=subprocess.PIPE)
	stdout, stderr = process.communicate()
	return stdout.decode().splitlines()

main()
