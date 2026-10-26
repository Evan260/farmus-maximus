"""Paint the Roman road that replaces the dirt road when it is paved, seen from the low angle of the rest of the estate:
the far kerb is a thin lit edge, and the rows of flat basalt stones grow taller and wider towards the viewer.

Usage: python tools/art/make_paved_road.py game/assets/backgrounds/estate/road_paved.png
The picture is as wide as the ground strip and covers its road rows, from ROAD_TOP to the bottom.
"""
import sys

import numpy as np
from PIL import Image

W, TOP, H = 2480, 270, 290
STONES = [(124, 118, 112), (134, 127, 118), (116, 111, 108), (128, 124, 120), (140, 132, 122), (120, 114, 106)]
# Rows of paving from the far kerb to the near edge: thin far away, taller close by.
ROWS = [2, 2, 3, 3, 4, 3]
# How far a joint leans to the right for each pixel it rises.
SLANT = 0.8


def main():
    rng = np.random.default_rng(23)
    h = H - TOP
    img = np.zeros((h, W, 4), np.uint8)
    img[..., 3] = 255
    # The far kerb: a lit top, its face, and the shadow it throws on the first row.
    img[0, :, :3] = (176, 168, 156)
    img[1, :, :3] = (150, 142, 132)
    img[2, :, :3] = (96, 90, 86)
    y = 3
    for k, rows in enumerate(ROWS):
        x = -int(rng.integers(0, 8)) - 12
        while x < W:
            width = int(rng.integers(7 + 2 * k, 11 + 3 * k))
            c = np.array(STONES[rng.integers(len(STONES))], int) + int(rng.integers(-6, 7))
            for yy in range(y, min(h, y + rows)):
                # The joints run away from the viewer, so they lean: each stone is a slanted four-sided slab, its far
                # edge further right than its near one.
                lean = round((y + rows - 1 - yy) * SLANT)
                left, right = x + lean, x + width + lean
                shade = c.copy()
                if yy == y:
                    shade = np.minimum(shade + 12, 255)
                elif yy == y + rows - 1 and rows > 2:
                    shade = shade - 10
                img[yy, max(0, left):max(0, min(W, right)), :3] = shade
                # The joint between two stones is only a little darker than the stones, as seen from above.
                if 0 <= right - 1 < W:
                    img[yy, right - 1, :3] = np.clip(c - 26, 0, 255)
            x += width
        y += rows
    # Wheels have polished two lanes a shade lighter.
    for lane in (8, 14):
        img[lane, :, :3] = np.minimum(img[lane, :, :3].astype(int) + 8, 255)
    Image.fromarray(img).save(sys.argv[1])
    print("road", W, "x", h)


if __name__ == "__main__":
    main()
