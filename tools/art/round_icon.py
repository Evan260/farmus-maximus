"""Rounds the game's icon into a tile with a dark rim, as Fishus Maximus's is, so the three games' icons match on the
taskbar. The corners and the rim are worked out on a 64 pixel grid and scaled up, so they step in the same blocks as
Fishus's. The square picture is kept in tools/art/icon_square.png; this writes game/icon.png and game/icon.ico with
every size Windows asks for. Usage: python tools/art/round_icon.py"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SQUARE = Path(__file__).with_name("icon_square.png")
SIZES = [16, 24, 32, 48, 64, 128, 256]
GRID = 64
CORNER = 11
RIM = (38, 34, 48)


def masks() -> tuple:
    """The tile's shape and its rim on the 64 pixel grid."""
    ys, xs = np.mgrid[0:GRID, 0:GRID]
    cx = np.clip(xs, CORNER, GRID - 1 - CORNER)
    cy = np.clip(ys, CORNER, GRID - 1 - CORNER)
    tile = (xs - cx) ** 2 + (ys - cy) ** 2 <= CORNER ** 2
    inner = tile.copy()
    inner[1:, :] &= tile[:-1, :]
    inner[:-1, :] &= tile[1:, :]
    inner[:, 1:] &= tile[:, :-1]
    inner[:, :-1] &= tile[:, 1:]
    inner[0, :] = inner[-1, :] = inner[:, 0] = inner[:, -1] = False
    return tile, tile & ~inner


def rounded(square: Image.Image, size: int = 256) -> Image.Image:
    art = np.array(square.convert("RGBA").resize((size, size), Image.LANCZOS))
    tile, rim = masks()
    scale = size // GRID
    tile = np.kron(tile, np.ones((scale, scale), bool))
    rim = np.kron(rim, np.ones((scale, scale), bool))
    art[~tile] = 0
    art[rim] = (*RIM, 255)
    return Image.fromarray(art)


def main():
    big = rounded(Image.open(SQUARE))
    big.save(ROOT / "game" / "icon.png")
    frames = [big.resize((s, s), Image.LANCZOS) for s in SIZES]
    frames[-1].save(ROOT / "game" / "icon.ico", sizes=[(s, s) for s in SIZES], append_images=frames[:-1])
    print("icon written", SIZES)


if __name__ == "__main__":
    main()
