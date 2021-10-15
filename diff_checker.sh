#!/bin/bash
# This script checks all the changed tracked files to check if the only difference is in the AnimatedSprite frame number.

DRY_RUN=

function show_usage() {
	echo "usage: $0 [-n]"
	echo ''
	echo '    -n: Dry run. Shows the files that will be restored.'
	echo ''
}

while getopts 'n' opt; do
    case "$opt" in
        n) DRY_RUN=t ;;
        *) show_usage;
           exit 1
    esac
done

CHANGED_FILES="$(git diff --name-only | fmt -w1)"
CHANGED_SCENES=$(echo "$CHANGED_FILES" | grep \.tscn$)
ONLY_FRAME_CHANGED_FILES=()

for FILE in $CHANGED_SCENES; do
	git diff -U0 -- $FILE | grep '^[+-]' | grep -Ev '^(--- a/|\+\+\+ b/)' | grep --extended-regexp -v "[-+]frame = [0-9]+" > /dev/null

	if [ $? -eq 1 ]; then
		ONLY_FRAME_CHANGED_FILES+=($FILE)
	fi
done

if [ -n "$ONLY_FRAME_CHANGED_FILES" ]; then
	if [ -z "$DRY_RUN" ]; then
		echo "${ONLY_FRAME_CHANGED_FILES[@]}" | fmt -w1 | xargs -l bash -c 'git restore -- "$0"'
	else
		echo "${ONLY_FRAME_CHANGED_FILES[@]}"
	fi
fi
