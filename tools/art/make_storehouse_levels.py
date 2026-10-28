"""Draw the storehouse as it grows with each enlargement, from its first picture, so every level looks different:
a tiled lean-to with amphorae beside it, then crates and sacks and shutters, then a loft storey with a hatch and a
hoist beam, then a second lean-to bay with great storage jars. The house keeps its place in every picture, at
HOUSE_AT in a canvas of SIZE, so the game can stand each level on the same spot.

Usage: python tools/art/make_storehouse_levels.py
Writes game/assets/sprites/farm/storehouse_1.png to storehouse_4.png.
"""
from pathlib import Path

import numpy as np
from PIL import Image

DIR = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites" / "farm"
SIZE = (112, 92)
HOUSE_AT = (46, 28)
# Rows of plain plaster just under the eaves, above the window and the door, which the loft repeats.
PLAIN = (24, 34)
LOFT = PLAIN[1] - PLAIN[0]
WOOD = [(92, 62, 40), (124, 88, 56), (156, 116, 74)]
TILE = [(150, 62, 36), (196, 90, 46), (226, 122, 62)]
CLAY = [(150, 82, 52), (184, 108, 66), (214, 140, 90)]
SACK = [(176, 150, 108), (206, 184, 140)]
STONE = (120, 110, 100)


def put(a, x, y, c):
    if 0 <= x < a.shape[1] and 0 <= y < a.shape[0]:
        a[y, x] = tuple(c) + (255,)


def rect(a, x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            put(a, xx, yy, c)


def house(loft):
    """The original storehouse, with a loft storey slipped in under the roof when it has one: the plain plaster just
    below the eaves is repeated, quoins and all, so the loft wall carries on the wall's own texture."""
    base = np.array(Image.open(DIR / "storehouse.png").convert("RGBA"))
    if not loft:
        return base
    cut = PLAIN[1]
    tall = np.concatenate([base[:cut], base[PLAIN[0]:PLAIN[1]], base[cut:]], axis=0)
    # The loft hatch: a dark opening framed in timber, its plank shutters folded back to the wall.
    hx, hy = 27, PLAIN[0] + 3
    rect(tall, hx - 1, hy - 1, 11, 11, WOOD[0])
    rect(tall, hx, hy, 9, 9, (46, 32, 30))
    # A straw bale stands just inside, lit along its top and bound with cord.
    rect(tall, hx + 1, hy + 5, 7, 4, (176, 146, 80))
    rect(tall, hx + 1, hy + 5, 7, 1, (214, 186, 110))
    rect(tall, hx + 1, hy + 8, 7, 1, (140, 112, 60))
    rect(tall, hx + 3, hy + 5, 1, 4, (120, 92, 50))
    rect(tall, hx + 6, hy + 5, 1, 4, (120, 92, 50))
    rect(tall, hx - 1, hy + 9, 11, 1, WOOD[1])
    rect(tall, hx - 1, hy - 1, 11, 1, WOOD[2])
    for sx in (hx - 4, hx + 10):
        rect(tall, sx, hy, 3, 9, WOOD[1])
        rect(tall, sx + 1, hy, 1, 9, WOOD[0])
        put(tall, sx, hy, WOOD[2])
        put(tall, sx + 2, hy, WOOD[2])
    # The hoist beam juts out from above the hatch, its end capped, for hauling goods up on a rope.
    rect(tall, hx + 2, hy - 3, 16, 2, WOOD[1])
    rect(tall, hx + 2, hy - 3, 16, 1, WOOD[2])
    rect(tall, hx + 17, hy - 4, 2, 4, WOOD[0])
    return tall


def lean_to(a, right, width, floor, roof_y):
    """A tiled lean-to roof on posts against the house's left wall."""
    left = right - width
    for x in range(left, right):
        drop = (right - x) // 4
        for y in range(roof_y + drop, roof_y + drop + 3):
            put(a, x, y, TILE[min(2, (y - roof_y - drop + (x % 3 == 0)))])
        put(a, x, roof_y + drop + 3, WOOD[0])
    for px in (left + 1, left + width // 2):
        top = roof_y + (right - px) // 4 + 4
        rect(a, px, top, 2, floor - top, WOOD[1])
        put(a, px + 1, top, WOOD[2])
    rect(a, left, floor - 1, width, 1, STONE)


def amphora(a, x, floor, tone=0):
    shape = [".###.", "#####", "#####", "#####", ".###.", ".###.", "..#..", "..#.."]
    for r, row in enumerate(shape):
        for c, ch in enumerate(row):
            if ch == "#":
                put(a, x + c, floor - len(shape) + r, CLAY[min(2, tone + (1 if c == 1 else 0))] if c < 4 else CLAY[0])
    rect(a, x + 1, floor - 9, 3, 1, CLAY[0])
    put(a, x, floor - 8, CLAY[0])
    put(a, x + 4, floor - 8, CLAY[0])


def dolium(a, x, floor):
    """A great storage jar sunk to its shoulders in the ground."""
    for r in range(7):
        half = [3, 5, 6, 6, 6, 5, 4][r]
        for c in range(-half, half + 1):
            put(a, x + c, floor - 7 + r, CLAY[2] if c < -half + 2 else (CLAY[0] if c > half - 2 else CLAY[1]))
    rect(a, x - 3, floor - 8, 7, 1, CLAY[0])
    rect(a, x - 2, floor - 8, 5, 1, (60, 40, 30))


def crate(a, x, floor, w=7, h=6):
    rect(a, x, floor - h, w, h, WOOD[1])
    rect(a, x, floor - h, w, 1, WOOD[2])
    rect(a, x + w - 1, floor - h, 1, h, WOOD[0])
    for k in range(min(w, h)):
        put(a, x + k, floor - h + k, WOOD[0])


def sack(a, x, floor):
    shape = [".##.", "####", "####", "####"]
    for r, row in enumerate(shape):
        for c, ch in enumerate(row):
            if ch == "#":
                put(a, x + c, floor - len(shape) + r, SACK[1] if c < 2 else SACK[0])


def build(level):
    a = np.zeros((SIZE[1], SIZE[0], 4), np.uint8)
    h = house(level >= 3)
    hx, hy = HOUSE_AT
    hy -= (LOFT if level >= 3 else 0)
    region = a[hy:hy + h.shape[0], hx:hx + h.shape[1]]
    region[h[..., 3] > 0] = h[h[..., 3] > 0]
    floor = HOUSE_AT[1] + 60
    wall_left = hx + 4
    lean_to(a, wall_left, 24, floor, floor - 30)
    amphora(a, wall_left - 20, floor)
    amphora(a, wall_left - 14, floor, 1)
    if level >= 2:
        crate(a, wall_left - 8, floor)
        crate(a, wall_left - 7, floor - 6, 5, 4)
        sack(a, wall_left - 25, floor)
        # Shutters either side of the window.
        for side in (-3, 8):
            rect(a, hx + 18 + side, hy + (LOFT if level >= 3 else 0) + 34, 2, 9, WOOD[1])
    if level >= 3:
        # The hoist rope hangs from the beam's end, twisted, with a sack on its way up.
        rope_x = hx + 27 + 17
        top = hy + PLAIN[0] + 3 - 1
        for k in range(11):
            put(a, rope_x, top + k, (150, 120, 80) if k % 2 else (176, 146, 100))
        put(a, rope_x - 1, top + 11, WOOD[0])
        put(a, rope_x + 1, top + 11, WOOD[0])
        for r, row in enumerate([".##.", "####", "####", ".##."]):
            for c, ch in enumerate(row):
                if ch == "#":
                    put(a, rope_x - 1 + c - 1 + 1, top + 12 + r, SACK[1] if c < 2 else SACK[0])
    if level >= 4:
        lean_to(a, wall_left - 24, 20, floor, floor - 24)
        dolium(a, wall_left - 37, floor + 1)
        dolium(a, wall_left - 28, floor + 2)
    return a


def main():
    for level in range(1, 5):
        Image.fromarray(build(level)).save(DIR / f"storehouse_{level}.png")
    print("storehouse levels")


if __name__ == "__main__":
    main()
