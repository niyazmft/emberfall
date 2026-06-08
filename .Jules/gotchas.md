# Godot Gotchas & Quirks

## 2026-06-08 - Clean up orphaned .gd.uid files after script deletion

**Learning:** Deleting GDScript files outside of the Godot editor (e.g., via git or filesystem) often leaves behind orphaned `.gd.uid` sidecar files. These files are used by Godot's resource system for tracking but become redundant clutter once the main script is gone, potentially causing import warnings in the editor.

**Action:** When deleting `.gd` scripts from the repository, always check for and remove any corresponding `.gd.uid` files to maintain repository cleanliness.
