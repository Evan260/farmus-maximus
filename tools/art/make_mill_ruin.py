"""Make the ruined mill from the working one, front on like the other ruins and the same shape as the building it
becomes: a roof with tiles fallen away, a collapsed top corner, cracks and fallen plaster showing the stonework,
the doorway dark with the sweep beam gone, rubble where the flour sacks stood, and ivy and weeds taking hold.

Usage: python tools/art/make_mill_ruin.py
Reads and writes game/assets/sprites/buildings/mill_working.png and mill_ruin.png.
"""
from pathlib import Path

import numpy as np
from PIL import Image

DIR = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites" / "buildings"
LEAVES = [(59, 68, 39), (77, 88, 42), (93, 103, 45), (120, 129, 46)]
STONE = [(168, 150, 120), (148, 130, 104), (124, 108, 88)]
RUBBLE = [(150, 138, 120), (122, 112, 100), (176, 164, 144), (98, 90, 84)]
CRACK = (110, 86, 64)
INSIDE = (34, 24, 30)


def main():
    rng = np.random.default_rng(31)
    a = np.array(Image.open(DIR / "mill_working.png").convert("RGBA")).astype(int)
    out = a.copy()
    op = a[..., 3] > 0
    # Weathered: the whitewash dulls towards grey-brown.
    wall = op & (a[..., :3].sum(-1) > 600)
    out[wall, :3] = (out[wall, :3] * 0.86 + np.array([150, 130, 100]) * 0.14).astype(int)

    # The roof: whole runs of tiles gone, the rest dark and patchy.
    for x in range(9, 87):
        gone = (20 <= x <= 27) or (54 <= x <= 59) or rng.random() < 0.05
        # Elsewhere the tiles have slipped, the row sagging a pixel here and there.
        sag = 1 if (x // 5) % 3 == 1 else 0
        for y in range(13, 6, -1):
            if not op[y - sag, x]:
                continue
            if gone and y < 12 + (x % 3 == 0):
                out[y, x] = (0, 0, 0, 0)
            else:
                out[y, x, :3] = (a[y - sag, x, :3] * 0.82).astype(int)
                out[y, x, 3] = 255
        if sag and op[7, x]:
            out[7, x] = (0, 0, 0, 0)

    # The top right corner of the wall has fallen in, leaving a stepped, broken edge.
    for x in range(64, a.shape[1]):
        drop = int((x - 64) * 0.75) + rng.integers(0, 3)
        for y in range(7, 14 + drop):
            out[y, x] = (0, 0, 0, 0)
        edge = 14 + drop
        if edge < a.shape[0] and op[edge, x]:
            out[edge, x, :3] = STONE[2]

    # Patches where the plaster has come away and the stone shows.
    for cx, cy, w, h in [(18, 22, 9, 6), (72, 40, 8, 7), (20, 44, 6, 5)]:
        for y in range(cy, cy + h):
            for x in range(cx, cx + w):
                if wall[y, x] and abs(x - cx - w / 2) / w + abs(y - cy - h / 2) / h < 0.62:
                    brick = ((y // 2) % 2 * 2 + x) // 4
                    out[y, x, :3] = STONE[2] if (y % 2 == 0 or x % 4 == (y // 2 % 2) * 2) else STONE[brick % 2]
    # Cracks running down from the broken corner and the doorway.
    for x0, y0, steps in [(64, 16, 16), (28, 24, 12), (69, 46, 10)]:
        x, y = x0, y0
        for _ in range(steps):
            if 0 <= y < a.shape[0] and wall[y, x]:
                out[y, x, :3] = CRACK
            y += 1
            x += int(rng.integers(-1, 2))

    # The doorway: darker inside, the sweep beam gone, only its stub on the shaft.
    for y in range(28, 44):
        for x in range(31, 64):
            beam = 37 <= y <= 41 and 31 <= x <= 61
            if op[y, x] and (a[y, x, :3].sum() < 360 or beam) and not (48 <= x <= 51):
                out[y, x, :3] = INSIDE
    # Rubble heaped where the flour sacks stood, and a few stones spilled at the foot of the wall.
    for y in range(50, 72):
        for x in range(9, 29):
            if a[y, x, 3]:
                out[y, x] = (wall_colour(out, y) + (255,)) if y < 70 and x >= 12 else (0, 0, 0, 0)
    for k in range(26):
        x = int(rng.integers(12, 34))
        y = int(70 - rng.integers(0, 9) * (1 - abs(x - 22) / 14))
        c = RUBBLE[k % len(RUBBLE)]
        for dx in range(int(rng.integers(2, 4))):
            if x + dx < a.shape[1]:
                out[y, x + dx] = c + (255,)
                if y + 1 < a.shape[0]:
                    out[y + 1, x + dx] = tuple(int(v * 0.8) for v in c) + (255,)

    # Damp and dirt creep up the foot of the walls.
    for y in range(50, 71):
        dim = 1.0 - 0.16 * (y - 50) / 20
        for x in range(a.shape[1]):
            if out[y, x, 3] and out[y, x, :3].sum() > 520:
                out[y, x, :3] = (out[y, x, :3] * (dim - (0.05 if rng.random() < 0.15 else 0.0))).astype(int)
    # Ivy climbing from the ground at both corners and trailing down from the broken roof.
    for x0, top in [(13, 26), (17, 40), (60, 34), (66, 50)]:
        x = x0
        for y in range(71, top, -1):
            if rng.random() < 0.7:
                x += int(rng.integers(-1, 2))
            leaf(out, x, y, rng)
            # Leaves bunch along the stem in clumps.
            if rng.random() < 0.45:
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (1, -1)]:
                    if rng.random() < 0.7:
                        leaf(out, x + dx, y + dy, rng)
    for x0 in [24, 35, 46, 62]:
        for y in range(13, 13 + int(rng.integers(4, 10))):
            leaf(out, x0 + int(rng.integers(-1, 2)), y, rng)
    # Weeds along the foot of the building.
    for x in range(10, 86):
        if rng.random() < 0.6:
            for d in range(int(rng.integers(1, 5))):
                out[71 - d, x] = LEAVES[min(3, d)] + (255,)
    Image.fromarray(out.astype(np.uint8)).save(DIR / "mill_ruin.png")
    print("mill ruin")


def wall_colour(a, y):
    row = a[y, 70:84]
    good = row[row[:, 3] > 0]
    return tuple(int(v) for v in good[:, :3].mean(0)) if len(good) else (230, 214, 172)


def leaf(out, x, y, rng):
    if 0 <= y < out.shape[0] and 0 <= x < out.shape[1]:
        out[y, x] = LEAVES[int(rng.integers(0, len(LEAVES)))] + (255,)


if __name__ == "__main__":
    main()
