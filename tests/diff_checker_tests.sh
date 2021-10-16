TEST_COMMAND='../diff_checker.sh'

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd "$SCRIPT_DIR"

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


# 2. Run tests

## Test 1 - Revert changes of 1 file
echo "$BOLD" '1. Successfully reverts frame only changes in one file' "$NORMAL"

### Set up
cp ./test-scenes/*.tscn test-scenes-copy/
git add -- test-scenes-copy/

TEST_SCENE_1='test-scenes/Test1.tscn'
TEST_SCENE_COPY_1='test-scenes-copy/Test1.tscn'

grep 'frame = 1' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Frame 1 is contained in the test file"

sed -i 's/frame = 1/frame = 2/' "$TEST_SCENE_COPY_1"

grep 'frame = 2' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Changed frame in the test file"

### Run script
$TEST_COMMAND

diff "$TEST_SCENE_COPY_1" "$TEST_SCENE_1" > /dev/null
assert_equal $? 0 "Changes reverted"


## Test 2 - Don't revert changes if node is not an AnimatedSprite
echo "$BOLD" '2. Does not revert changes when node is not an AnimatedSprite' "$NORMAL"

cp ./test-scenes/*.tscn test-scenes-copy/
git add -- test-scenes-copy/
TEST_SCENE_1='test-scenes/Test1.tscn'
TEST_SCENE_COPY_1='test-scenes-copy/Test1.tscn'

# Change node type and stage
sed -i 's/type="AnimatedSprite"/type="CustomNode"/' "$TEST_SCENE_COPY_1"
git add -- "$TEST_SCENE_COPY_1"

grep 'frame = 1' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Frame 1 is contained in the test file"

sed -i 's/frame = 1/frame = 2/' "$TEST_SCENE_COPY_1"

grep 'frame = 2' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Changed frame in the test file"

### Run script
$TEST_COMMAND

grep 'frame = 2' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Changed frame still in the test file"


## Test 3 - Don't revert changes if AnimatedSprite's animation isn't actively playing
echo "$BOLD" '2. Does not revert changes when AnimatedSprite is not playing' "$NORMAL"

cp ./test-scenes/*.tscn test-scenes-copy/
git add -- test-scenes-copy/
TEST_SCENE_1='test-scenes/Test1.tscn'
TEST_SCENE_COPY_1='test-scenes-copy/Test1.tscn'

# Change node type and stage
sed -i 's/playing = true/playing = false/' "$TEST_SCENE_COPY_1"
git add -- "$TEST_SCENE_COPY_1"

grep 'frame = 1' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Frame 1 is contained in the test file"

sed -i 's/frame = 1/frame = 2/' "$TEST_SCENE_COPY_1"

grep 'frame = 2' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Changed frame in the test file"

### Run script
$TEST_COMMAND

grep 'frame = 2' "$TEST_SCENE_COPY_1" > /dev/null
assert_equal $? 0 "Changed frame still in the test file"



# 4. Clean up
git rm -rf -- test-scenes-copy/ > /dev/null
