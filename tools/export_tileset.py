#!/usr/bin/env python3
"""
export_tileset.py — Tileset PNG + JSON emitter for Emberfall

Emberfall Environment Tileset Spec §6 compliant output:
  Collision bytes: 0=walkable, 1=solid, 2=platform, 3=hazard, 4=cover

Supports filename suffix tags for collision type overrides:
  _solid, _platform, _hazard, _cover

Usage: python3 tools/export_tileset.py <source_dir> <output_prefix>
"""

import json
import os
import sys
import argparse
from pathlib import Path
from typing import Any


COLLISION_TAG_MAP = {
    "_walkable": 0,
    "_solid": 1,
    "_platform": 2,
    "_hazard": 3,
    "_cover": 4,
}
DEFAULT_COLLISION = 1  # tiles with alpha are solid unless tagged


def derive_collision_byte(stem: str, has_alpha: bool = True) -> int:
    """Return collision byte from filename suffix or default."""
    lower = stem.lower()
    for tag, value in COLLISION_TAG_MAP.items():
        if lower.endswith(tag):
            return value
    if not has_alpha:
        return 0  # fully transparent tile = walkable
    return DEFAULT_COLLISION


def build_manifest(source_dir: Path) -> dict[str, Any]:
    """Build tileset manifest from source directory."""
    manifest: dict[str, Any] = {
        "format_version": "1.0.0",
        "tile_size": 32,
        "gutter": 2,
        "tiles": [],
    }

    tiles: list[dict[str, Any]] = []
    # Expect files named <id>_<name>_<tag>.png, e.g. 05_wall_solid.png
    for file in sorted(source_dir.iterdir()):
        if file.suffix.lower() != ".png":
            continue

        stem = file.stem
        parts = stem.split("_")
        tile_id = parts[0] if parts else stem
        collision = derive_collision_byte(stem)

        tiles.append(
            {
                "id": tile_id,
                "file": file.name,
                "collision_byte": collision,
                "collision_name": {v: k for k, v in COLLISION_TAG_MAP.items()}.get(
                    collision, "default_solid"
                ).lstrip("_"),
            }
        )

    manifest["tiles"] = tiles
    manifest["collision_summary"] = {
        "walkable": sum(1 for t in tiles if t["collision_byte"] == 0),
        "solid": sum(1 for t in tiles if t["collision_byte"] == 1),
        "platform": sum(1 for t in tiles if t["collision_byte"] == 2),
        "hazard": sum(1 for t in tiles if t["collision_byte"] == 3),
        "cover": sum(1 for t in tiles if t["collision_byte"] == 4),
    }
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description="Emberfall tileset exporter")
    parser.add_argument("source_dir", help="Directory containing 32×32 tile PNGs")
    parser.add_argument(
        "output_prefix",
        help="Output prefix (e.g. assets/texture/tileset/dungeon)",
    )
    args = parser.parse_args()

    src = Path(args.source_dir)
    prefix = Path(args.output_prefix)

    if not src.is_dir():
        print(f"ERROR: source_dir not found: {src}", file=sys.stderr)
        return 1

    prefix.parent.mkdir(parents=True, exist_ok=True)

    manifest = build_manifest(src)
    json_path = prefix.parent / (prefix.name + ".json")
    with json_path.open("w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2)

    print(f"Wrote manifest with {len(manifest['tiles'])} tiles to {json_path}")
    print(
        "Collision breakdown:",
        json.dumps(manifest["collision_summary"], separators=(",", ":")),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
