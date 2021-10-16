# 1. Copy sample scenes

mkdir -p test-scenes
cp ../SampleProject/TestScenes/*.tscn test-scenes/

# 2. Stage them
git add -- test-scenes/

# 3. Run tests
# TODO

# 4. Clean up
git rm -rf -- test-scenes/
