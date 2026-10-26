"""Paint the Roman road that replaces the dirt road when it is paved: irregular basalt blocks fitted together, a row of
kerbstones along the field side, and two smooth wheel ruts.

Usage: python tools/art/make_paved_road.py game/assets/backgrounds/estate/road_paved.png
The picture is as wide as the ground strip and covers its road rows, from ROAD_TOP to the bottom.
"""
import sys

import numpy as np
from PIL import Image

W, TOP, H = 2480, 270, 290
STONES = [(96, 94, 98), (110, 106, 108), (88, 86, 92), (122, 117, 114), (104, 100, 104), (116, 112, 116)]
JOINT = (56, 52, 54)
KERB = [(150, 144, 136), (138, 132, 126), (160, 154, 146)]


def main():
    rng = np.random.default_rng(23)
    h = H - TOP
    img = np.zeros((h, W, 4), np.uint8)
    # Each block grows from a seed on a jittered grid; a pixel belongs to the nearest seed, measured a little wider
    # than tall so the blocks lie along the road.
    seeds = []
    for gy in range(3, h, 6):
        for gx in range(0, W + 10, 9):
            seeds.append((gx + rng.uniform(-3, 3), gy + rng.uniform(-1.5, 1.5)))
    seeds = np.array(seeds)
    colours = [STONES[rng.integers(len(STONES))] for _ in seeds]
    ys, xs = np.mgrid[0:h, 0:W]
    owner = np.zeros((h, W), np.int32)
    best = np.full((h, W), np.inf)
    for i, (sx, sy) in enumerate(seeds):
        x0, x1 = int(max(0, sx - 12)), int(min(W, sx + 13))
        d = ((xs[:, x0:x1] - sx) * 0.75) ** 2 + (ys[:, x0:x1] - sy) ** 2
        closer = d < best[:, x0:x1]
        best[:, x0:x1][closer] = d[closer]
        owner[:, x0:x1][closer] = i
    for y in range(h):
        for x in range(W):
            o = owner[y, x]
            c = np.array(colours[o], int)
            right = owner[y, x + 1] if x + 1 < W else o
            below = owner[y + 1, x] if y + 1 < h else o
            left = owner[y, x - 1] if x > 0 else o
            above = owner[y - 1, x] if y > 0 else o
            if right != o or below != o:
                c = np.array(JOINT)
            elif left != o or above != o:
                c = np.minimum(c + 22, 255)
            elif (x + y * 3) % 17 == 0:
                c = c - 10
            img[y, x] = (*c, 255)
    # Wheels polish two lanes smooth and a little lighter.
    for lane in (8, 15):
        for y in (lane, lane + 1):
            row = img[y, :, :3].astype(int)
            joint = (row == JOINT).all(axis=1)
            row[~joint] = np.minimum(row[~joint] + 10, 255)
            img[y, :, :3] = row
    # Kerbstones: two rows of long blocks with joints every so often, lit along the top.
    x = 0
    while x < W:
        length = int(rng.integers(10, 17))
        c = np.array(KERB[rng.integers(len(KERB))])
        img[0, x:x + length, :3] = np.minimum(c + 16, 255)
        img[1, x:x + length, :3] = c
        img[2, x:x + length, :3] = c - 28
        img[0:3, x:x + length, 3] = 255
        img[0:3, min(W - 1, x + length - 1), :3] = JOINT
        x += length
    Image.fromarray(img).save(sys.argv[1])
    print("road", W, "x", h)


if __name__ == "__main__":
    main()
