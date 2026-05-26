#!/usr/bin/env python3
"""
export_sprites.py — Sprite atlas JSON emitter for Emberfall

Emberfall Character Sprite Spec §5 / Art Bible §6 compliant output:
  name, frameWidth, frameHeight, pivotX, pivotY,
  states: [{ state, startFrame, endFrame, fps, loop }]

Usage: python3 tools/export_sprites.py <source_dir> <output_dir>
"""

import json
import os
import sys
import argparse
from pathlib import Path
from typing import Any


DEFAULT_PIVOT = {"x": 0.5, "y": 0.5}
DEFAULT_FPS = 12
VALID_EXTENSIONS = {".png", "jpg", "jpeg"}


def build_atlas(source_dir: Path) -> dict[str, Any]:
    """Walk source_dir and emit one atlas entry per sprite sub-directory."""
    atlas: dict[str, Any] = {"format_version": "1.0.0", "entries": []}

    for sub in sorted(source_dir.iterdir()):
        if not sub.is_dir():
            continue

        frames = sorted(
            f for f in sub.iterdir() if f.suffix.lower() in VALID_EXTENSIONS
        )
        if not frames:
            continue

        # Derive dimensions from the first frame
        # (In production this would read image headers; stubbed for portability.)
        entry: dict[str, Any] = {
            "name": sub.name,
            "frameWidth": 128,   # placeholders; replace with image header read
            "frameHeight": 128,
            "pivotX": DEFAULT_PIVOT["x"],
            "pivotY": DEFAULT_PIVOT["y"],
            "frameCount": len(frames),
            "states": [],
        }

        # Simple heuristic: filenames like idle_001.png, walk_001.png
        state_map: dict[str, list[int]] = {}
        for idx, frame in enumerate(frames):
            # Split on underscore or dash; first token is state name
            raw = frame.stem.split("_")[0].split("-")[0]
            state_name = raw.lower() if raw else "default"
            state_map.setdefault(state_name, []).append(idx)

        for state_name, indices in sorted(state_map.items()):
            entry["states"].append(
                {
                    "state": state_name,
                    "startFrame": indices[0],
                    "endFrame": indices[-1],
                    "fps": DEFAULT_FPS,
                    "loop": True,
                }
            )

        # If no states found, add a generic default state covering all frames
        if not entry["states"]:
            entry["states"].append(
                {
                    "state": "default",
                    "startFrame": 0,
                    "endFrame": entry["frameCount"] - 1,
                    "fps": DEFAULT_FPS,
                    "loop": True,
                }
            )

        atlas["entries"].append(entry)

    return atlas


def main() -> int:
    parser = argparse.ArgumentParser(description="Emberfall sprite atlas exporter")
    parser.add_argument("source_dir", help="Directory containing sprite sub-folders")
    parser.add_argument("output_dir", help="Directory to write JSON atlas files")
    args = parser.parse_args()

    src = Path(args.source_dir)
    out = Path(args.output_dir)

    if not src.is_dir():
        print(f"ERROR: source_dir not found: {src}", file=sys.stderr)
        return 1

    out.mkdir(parents=True, exist_ok=True)

    atlas = build_atlas(src)
    out_path = out / "sprite_atlas.json"
    with out_path.open("w", encoding="utf-8") as fh:
        json.dump(atlas, fh, indent=2)

    print(f"Wrote {len(atlas['entries'])} entries to {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
