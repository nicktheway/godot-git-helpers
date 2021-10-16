# 1. Copy sample scenes

mkdir -p test-scenes-copy
cp ./test-scenes/*.tscn test-scenes-copy/

# 2. Stage them
git add -- test-scenes-copy/

# 3. Run tests
# TODO

# 4. Clean up
git rm -rf -- test-scenes-copy/ > /dev/null
