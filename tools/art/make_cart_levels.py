"""Draw the trader's cart at each upgrade as a cart of its own rather than a stretched copy: the near side is repainted
as one run of long planks with their own grain and knots, the ends and shafts are the original's, and each level adds
something new: upright stakes, then a wicker rail above the planks, then iron-bound corners and a red stripe on a
four-wheeled wagon. The bed grows to the right and upwards, so the wheel and shafts stay at the original's height.

Usage: python tools/art/make_cart_levels.py
Writes game/assets/sprites/farm/cart_back_<n>.png and cart_front_<n>.png for levels 1 to 3; the game reads GROW for
how much longer and taller each one is.
"""
from pathlib import Path

import numpy as np
from PIL import Image

DIR = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites" / "farm"
# How much longer and taller each level's bed is than the first cart's.
GROW = {1: (12, 3), 2: (24, 6), 3: (36, 8)}
TOP = 15
BOTTOM = 29
LEFT, RIGHT = 9, 28
RIM = [(224, 153, 92), (194, 121, 70)]
PLANK = [(180, 109, 63), (165, 99, 59), (151, 91, 55), (97, 59, 41)]
BEAM = [(134, 83, 51), (115, 71, 46), (58, 35,40), (165, 99, 59)]
POST = [(69, 42, 42), (180, 109, 63)]
WICKER = [(196, 158, 96), (150, 112, 66), (110, 78, 48)]
IRON = [(70, 66, 72), (120, 116, 122)]
RED = [(150, 46, 38), (182, 64, 48)]
BACK = [(151, 91, 55), (97, 59, 41), (82, 49, 41)]


def stretch_rows(img, gy):
    """The original picture with gy rows slipped in where the near side begins, so the rim rises and the rest stays."""
    h, w = img.shape[:2]
    out = np.zeros((h + gy, w, 4), np.uint8)
    out[:TOP] = img[:TOP]
    out[TOP + gy:] = img[TOP:]
    return out


def shift_right(img, gx, from_x):
    h, w = img.shape[:2]
    out = np.zeros((h, w + gx, 4), np.uint8)
    out[:, :from_x] = img[:, :from_x]
    out[:, from_x + gx:] = img[:, from_x:]
    return out


def side(level, gx, gy, rng):
    """The near side board from LEFT to the right end: a lit rim, long planks with grain and knots, and the bottom beam."""
    width = RIGHT - LEFT + gx
    rows = BOTTOM - TOP + 1 + gy
    out = np.zeros((rows, width, 4), np.uint8)
    grain = np.cumsum(rng.normal(0, 0.35, (rows, width)), axis=1)
    grain -= grain.mean(axis=1, keepdims=True)
    for y in range(rows):
        for x in range(width):
            if y == 0:
                c = RIM[(x // 5) % 2]
            elif y >= rows - 4:
                c = BEAM[y - (rows - 4)]
            else:
                band = (y - 1) % 4
                c = PLANK[band] if band != 1 else PLANK[1 + (grain[y, x] > 0.9)]
                if band == 3 and rng.random() < 0.06:
                    c = PLANK[2]
            out[y, x] = c + (255,)
    # A few knots in the wood, and a joint where one plank ends and the next begins.
    for _ in range(width // 10):
        x, y = int(rng.integers(2, width - 2)), int(rng.integers(2, rows - 5))
        if (y - 1) % 4 in (0, 1, 2):
            out[y, x] = PLANK[3] + (255,)
            out[y, x + 1] = PLANK[2] + (255,)
    for y0 in range(1, rows - 4, 4):
        x = int(rng.integers(6, width - 6))
        for y in range(y0, min(y0 + 3, rows - 4)):
            out[y, x] = PLANK[3] + (255,)
    return out


def post(img, x, top, bottom, poke=0):
    for y in range(top - poke, bottom):
        img[y, x] = POST[0] + (255,)
        img[y, x + 1] = POST[1] + (255,)
    if poke:
        img[top - poke, x] = POST[1] + (255,)


def build(level):
    gx, gy = GROW[level]
    rng = np.random.default_rng(40 + level)
    front = np.array(Image.open(DIR / "cart_front.png").convert("RGBA"))
    back = np.array(Image.open(DIR / "cart_back.png").convert("RGBA"))
    front = shift_right(stretch_rows(front, gy), gx, RIGHT)
    back = shift_right(stretch_rows(back, gy), gx, RIGHT)
    board = side(level, gx, gy, rng)
    rows, width = board.shape[:2]
    front[TOP:TOP + rows, LEFT:LEFT + width] = board
    # Behind the goods, the far rim and the shadowed inside of the bed run the new length.
    for x in range(LEFT, RIGHT + gx):
        for k, c in enumerate(BACK):
            back[11 + k + (1 if k else 0), x] = c + (255,)
    right = RIGHT + gx
    if level >= 1:
        for x in range(LEFT + 6, right - 3, 14):
            post(front, x, TOP, TOP + rows - 3, poke=3)
    if level >= 2:
        # A woven wicker rail on top of the planks makes the sides higher.
        for y in range(TOP - 5, TOP):
            for x in range(LEFT - 3, right):
                weave = (x + y) % 4 < 2 if (x // 4) % 2 else (x - y) % 4 < 2
                front[y, x] = WICKER[0 if weave else 1] + (255,)
            front[y, LEFT - 3] = WICKER[2] + (255,)
        for x in range(LEFT - 3, right):
            front[TOP - 6, x] = POST[1] + (255,)
    if level >= 3:
        for x in (LEFT, right - 2):
            for y in range(TOP, TOP + rows - 3):
                front[y, x] = IRON[(y % 3 == 0)] + (255,)
                front[y, x + 1] = IRON[0] + (255,)
        for x in range(LEFT + 2, right - 2):
            front[TOP + 2, x] = RED[x % 7 == 0] + (255,)
    Image.fromarray(front).save(DIR / f"cart_front_{level}.png")
    Image.fromarray(back).save(DIR / f"cart_back_{level}.png")


def main():
    for level in GROW:
        build(level)
    print("cart levels")


if __name__ == "__main__":
    main()
