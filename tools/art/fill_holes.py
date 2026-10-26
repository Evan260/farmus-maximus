"""Fill the small see-through specks that generated sprites sometimes have inside the figure, such as at a shoulder,
with the colours around them. Larger enclosed gaps, gaps ringed by dark outline and any down among the legs and feet
are real gaps (an arm on a hip, a curled tail, the space between legs) and are left alone.

Usage: python tools/art/fill_holes.py FOLDER [FOLDER ...]
Every PNG under each folder is checked and fixed in place; it prints how many specks it filled. It is run over
game/assets/sprites/people, dog and dog_breeds; most farm animals' small gaps are real (tails, halters, horns).
"""
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

LARGEST = 8
# A gap whose edge is mostly this dark is drawn on purpose, like the loop of a curled tail, and stays open.
OUTLINED = 0.5
# Specks lower than this share of the figure's height are among the legs and feet, where gaps are real.
LEGS = 0.72
# These carry a staff or stick, or have a curled tail, so their small gaps are drawn on purpose.
KEEP_OPEN = {"shepherd", "traveller", "sighthound"}


def fill(path):
    a = np.array(Image.open(path).convert("RGBA"))
    solid = a[..., 3] > 0
    if not solid.any():
        return 0
    ys = np.nonzero(solid)[0]
    top, height = ys.min(), ys.max() - ys.min() + 1
    light = a[..., :3].astype(float) @ [0.3, 0.59, 0.11]
    dark = light <= np.percentile(light[solid], 15)
    holes = ndimage.binary_fill_holes(solid) & ~solid
    lab, n = ndimage.label(holes)
    todo = np.zeros_like(holes)
    count = 0
    for k in range(1, n + 1):
        part = lab == k
        size = int(part.sum())
        centre = np.nonzero(part)[0].mean()
        edge = ndimage.binary_dilation(part, np.ones((3, 3))) & ~part
        if size <= LARGEST and centre < top + LEGS * height and dark[edge].mean() < OUTLINED:
            todo |= part
            count += 1
    # Fill from the edges of each speck inwards, each pixel taking the commonest colour of its filled neighbours.
    while todo.any():
        filled = []
        for y, x in zip(*np.nonzero(todo)):
            around = [tuple(a[yy, xx]) for yy in range(y - 1, y + 2) for xx in range(x - 1, x + 2)
                      if 0 <= yy < a.shape[0] and 0 <= xx < a.shape[1] and a[yy, xx, 3] > 0 and not todo[yy, xx]]
            if around:
                filled.append((y, x, Counter(around).most_common(1)[0][0]))
        if not filled:
            break
        for y, x, c in filled:
            a[y, x] = c
            todo[y, x] = False
    if count:
        Image.fromarray(a).save(path)
    return count


def main():
    total = 0
    for folder in sys.argv[1:]:
        for path in sorted(Path(folder).rglob("*.png")):
            if KEEP_OPEN & set(path.parts):
                continue
            total += fill(path)
    print("filled", total, "specks")


if __name__ == "__main__":
    main()
