#!/bin/bash
# This script checks all the changed tracked files to check if the only difference is in the AnimatedSprite frame number.

DRY_RUN=
VERBOSE=


function show_usage() {
	echo "usage: $0 [-n]"
	echo ''
	echo '    -n: Dry run. Shows the files that will be restored.'
	echo '    -v: Verbose. Explain the process, useful for debugging the script.'
	echo ''
}

while getopts 'nv' opt; do
    case "$opt" in
        n) DRY_RUN=t; VERBOSE=t;;
        v) VERBOSE=t ;;
        *) show_usage;
           exit 1
    esac
done

function log() {
	if [ -z "$VERBOSE" ]; then
		return 1
	fi
	echo "$@"
}

function validate_node_type() {
	local filepath="$1"
	local line="$2"

	local stop=1
	local previousline=$((line-1))
	while [ $stop -eq 1 ]; do
		local linetext=$(git diff -U$(wc -l "$filepath") | sed "${previousline}q;d") 
		echo "$linetext" | grep "^ *$" > /dev/null
		stop=$?
		
		echo "$linetext" | grep --extended-regexp "\[node.*\" type=\"AnimatedSprite\"" > /dev/null
		if [ $? = 0 ]; then
			log '    O Confirmed AnimatedSprite node: ' "$linetext"
			return 0
		fi

		previousline=$((previousline-1))
	done
	log '    X Not an AnimatedSprite node!'
	return 1
}

function validate_playing() {
	local filepath="$1"
	local line="$2"

	local stop=1
	local nextline=$((line+1))
	while [ $stop -eq 1 ]; do
		local linetext=$(git diff -U$(wc -l "$filepath") | sed "${nextline}q;d") 
		echo "$linetext" | grep "^ *$" > /dev/null
		stop=$?
		
		echo "$linetext" | grep "playing = true" > /dev/null
		if [ $? = 0 ]; then
			log '    O Confirmed that the animation is running: ' "$linetext"
			return 0
		fi

		nextline=$((nextline+1))
	done
	log '    X The animation is not running!'
	return 1
}

function validate_file_frame_changes() {
	local filepath="$1"
	local framelines="$(git diff -U$(wc -l "$filepath") | grep -n '^+frame' | cut -d':' -f1)"
	for line in $(echo "$framelines"); do
		log '  > Verifying frame change on line' $line # for file $filepath
		validate_node_type "$filepath" "$line"
		if [ $? -ne 0 ]; then
			return 1
		fi
		validate_playing "$filepath" "$line"
		if [ $? -ne 0 ]; then
			return 1
		fi
	done
	return 0
}

function validate_and_revert_changes() {
	for filepath in "$@"; do
		log ""
		log "- Validating: " "$filepath"
		validate_file_frame_changes "$filepath"
		if [ $? -ne 0 ]; then
			log '  The script will not revert this file as it looks like it contains intended changes!'
			continue
		fi

		if [ -z "$DRY_RUN" ]; then
			git restore -- "$filepath"
			log '  Restored changes.'
		else
			log '  DRY RUN MODE - Did not restore changes.'
		fi

	done
	return 0
}

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd "$SCRIPT_DIR"

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
	log 'Identified files with only frame changes: '
	log ''
	for file in ${ONLY_FRAME_CHANGED_FILES[@]}; do log "$file"; done;
	validate_and_revert_changes "${ONLY_FRAME_CHANGED_FILES[@]}"
else
	log 'No files with only frame changes found.'
fi
