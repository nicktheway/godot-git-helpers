# Godot Git Helpers

## Diff Checker

A lot of times, when working with godot projects I open scenes and save them without making any manual change. When those scenes contain AnimatedSprite nodes that are playing, the frame at the point of save is stored in the file and appears as a change in git.

The diff checker script will revert these non-manual changes.

Just run `./diff_checker.sh` before staging changes in git.


