# Test helpers
SUCCESS_PREFIX='  ✔ '
FAILURE_PREFIX='  ✖ '
RED=$(echo -en "\e[31m")
GREEN=$(echo -en "\e[32m")
NORMAL=$(echo -en "\e[00m")
BOLD=$(echo -en "\e[01m")

function assert_equal() {
	local actual="$1"
	local expected="$2"
	local message="$3"
	
	local success=
	if [ "$expected" == "$actual" ]; then
		success=t
	fi

	if [[ ! -z "$message" ]]; then
		[ -z $success ] && echo "$RED" "$FAILURE_PREFIX" "$message" "$NORMAL" || echo "$GREEN" "$SUCCESS_PREFIX" "$message" "$NORMAL" 
	fi

	[ -z $success ] && return 0 || return 1
}


# 1. Copy sample scenes
mkdir -p test-scenes-copy
cp ./test-scenes/*.tscn test-scenes-copy/

# 2. Stage them
git add -- test-scenes-copy/

# 3. Run tests

## Test - Revert changes of 1 file
echo "$BOLD" '1. Successfully reverts frame only changes in one file' "$NORMAL"

### Set up
TEST_SCENE_1='test-scenes/Test1.tscn'
TEST_SCENE_COPY_1='test-scenes-copy/Test1.tscn'

grep 'frame = 1' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Frame 1 is contained in the test file"

sed -i 's/frame = 1/frame = 2/' "$TEST_SCENE_COPY_1"

grep 'frame = 2' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Changed frame in the test file"

### Run script
../diff_checker.sh

diff "$TEST_SCENE_COPY_1" "$TEST_SCENE_1" > /dev/null
assert_equal $? 0 "Changes reverted"


# 4. Clean up
git rm -rf -- test-scenes-copy/ > /dev/null
