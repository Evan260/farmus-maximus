"""Paint the estate's ground strip: grass in the olive grove, tilled soil on the farm, packed earth in the workshop yard, grass in the vineyard, a flowery meadow in the pasture, and the road to town along the bottom of the last two.

Usage: python tools/art/make_estate_ground.py game/assets/backgrounds/estate/ground.png --villa-door 851
The image is 40 pixels wider than the estate on each side, so the camera never reaches its edge.
"""
import argparse

import numpy as np
from PIL import Image

W, H = 2400 + 80, 272
TOP = 232
ZONES = [(0, 480, "grass"), (480, 960, "soil"), (960, 1440, "yard"), (1440, 1920, "grass"), (1920, 2400, "meadow")]
ROAD_FROM = 1420


def main():
    p = argparse.ArgumentParser()
    p.add_argument("out")
    p.add_argument("--villa-door", type=int, default=851)
    a = p.parse_args()
    rng = np.random.default_rng(7)
    img = np.zeros((H, W, 4), np.uint8)
    edge = TOP + np.cumsum(rng.integers(-1, 2, W)).clip(-3, 3)

    wobble = rng.integers(-5, 6, H)

    def kind_at(x, y):
        # Borders between zones shift a few pixels row by row, so the ground blends rather than meeting in a straight line.
        wx = x - 40 - int(wobble[y]) - int(4 * np.sin(y * 0.45))
        for x0, x1, k in ZONES:
            if x0 <= wx < x1:
                return k
        return "grass"

    for x in range(W):
        for y in range(edge[x], H):
            k = kind_at(x, y)
            r = rng.random()
            if k == "grass":
                c = (96, 122, 58) if r > 0.25 else ((82, 108, 50) if r > 0.08 else (118, 140, 66))
            elif k == "meadow":
                # The pasture's grass is grazed short and dotted with small flowers.
                c = (104, 128, 60) if r > 0.25 else ((90, 114, 54) if r > 0.06 else ((226, 214, 160) if r > 0.03 else (196, 150, 196)))
            elif k == "soil":
                furrow = (y - TOP) % 6 in (0, 1)
                c = (100, 70, 47) if furrow else (118, 84, 56)
                c = (c[0] + 12, c[1] + 9, c[2] + 6) if r < 0.05 else ((c[0] - 12, c[1] - 9, c[2] - 6) if r < 0.1 else c)
            elif k == "yard":
                c = (150, 124, 92) if r > 0.12 else ((128, 106, 80) if r > 0.04 else (176, 156, 124))
            img[y, x] = (*c, 255)
        # Grass tufts overhang the top edge everywhere, so the ground meets the meadow softly.
        for k2 in range(rng.integers(0, 3)):
            y = edge[x] + k2
            if y < H:
                img[y, x] = (104, 128, 60, 255) if rng.random() < 0.6 else (86, 110, 50, 255)

    # The road to town leaves the yard along the bottom of the vineyard, where the cart's wheels roll.
    road_top = 248 + np.cumsum(rng.integers(-1, 2, W)).clip(-2, 2)
    for x in range(ROAD_FROM + 40, W):
        fade = min(1.0, (x - ROAD_FROM - 40) / 30)
        for y in range(road_top[x], H):
            if y == road_top[x] and rng.random() < 0.4:
                continue
            if rng.random() > 0.35 + 0.65 * fade:
                continue
            r = rng.random()
            c = (146, 118, 84) if r > 0.1 else ((128, 102, 72) if r > 0.03 else (170, 146, 110))
            # Two wheel ruts, worn darker and a little wavy.
            if abs(y - (258 + (x // 37) % 2)) == 0 or abs(y - (265 + (x // 41) % 2)) == 0:
                c = (118, 92, 64) if rng.random() > 0.15 else c
            img[y, x] = (*c, 255)
        # A grass tuft now and then sprouts along the road's crown, between the ruts.
        if rng.random() < 0.12:
            img[261, x] = (98, 120, 58, 255)

    # The path from the villa steps runs down across the farm.
    door = a.villa_door + 40
    for y in range(233, H):
        cx = door - (y - 233) * 0.3
        half = 13 + (y - 233) * 0.3
        for x in range(int(cx - half - 1), int(cx + half + 2)):
            edge_px = x < cx - half or x > cx + half
            if 0 <= x < W and (not edge_px or rng.random() < 0.5):
                r = rng.random()
                img[y, x] = (176, 142, 98, 255) if r > 0.2 else ((154, 122, 82, 255) if r > 0.06 else (192, 160, 114, 255))
    Image.fromarray(img).save(a.out)
    print("ground", W, "x", H)


if __name__ == "__main__":
    main()
