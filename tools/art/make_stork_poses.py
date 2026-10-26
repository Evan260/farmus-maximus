"""Make the stork's other poses from its picture on the nest: looking back the other way, blinking, and bowing its
head a pixel, which the game switches between so the bird on the roof is never quite still.

Usage: python tools/art/make_stork_poses.py game/assets/sprites/animals/stork
"""
import sys
from pathlib import Path

from PIL import Image

# The head and bill sit above the body in rows 0 to 8, turning about the neck at x 24.5.
HEAD = (18, 0, 33, 9)
NECK_X2 = 49


def main():
    folder = Path(sys.argv[1])
    base = Image.open(folder / "nest.png").convert("RGBA")
    px = base.load()
    x0, y0, x1, y1 = HEAD

    look = base.copy()
    lp = look.load()
    for y in range(y0, y1):
        for x in range(x0, x1):
            lp[x, y] = (0, 0, 0, 0)
    for y in range(y0, y1):
        for x in range(x0, x1):
            if px[x, y][3] and 0 <= NECK_X2 - x < base.width:
                lp[NECK_X2 - x, y] = px[x, y]
    look.save(folder / "nest_look.png")

    blink = base.copy()
    bp = blink.load()
    white = px[24, 3]
    for y in range(y0, 4):
        for x in range(21, 28):
            r, g, b, a = px[x, y]
            if a and r + g + b < 300:
                bp[x, y] = white
    blink.save(folder / "nest_blink.png")

    nod = base.copy()
    npx = nod.load()
    for y in range(y1 - 1, y0, -1):
        for x in range(x0, x1):
            npx[x, y] = px[x, y - 1] if px[x, y - 1][3] or y < y1 - 1 else px[x, y]
    for x in range(x0, x1):
        npx[x, y0] = (0, 0, 0, 0)
    nod.save(folder / "nest_nod.png")
    print("stork poses")


if __name__ == "__main__":
    main()
