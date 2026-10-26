"""Lift the cypresses out of the market town's front layer so they can sway in the wind like the estate's trees.
Each tree is saved as its own picture, and the front layer is saved again without them, the gap each leaves filled
from the colours on either side of it, so a tree leaning a pixel shows mountain or sky behind it rather than a hole.

Usage: python tools/art/make_town_sway_mask.py game/assets/backgrounds/market/sky
Writes front_still.png, tree_0.png and on, and trees.json there. Run it again after re-splitting the town painting.
"""
import colorsys
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def tree_masks(a):
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    lit = (al > 0) & (g >= r) & (g > b + 4) & (r + g + b < 420)
    lab, _ = ndimage.label(lit)
    for s in ndimage.find_objects(lab):
        h, w = s[0].stop - s[0].start, s[1].stop - s[1].start
        # Cypresses are the tall narrow green shapes; bushes and awnings are left alone.
        if h < 30 or h < w * 1.6:
            continue
        y0, y1 = s[0].start, s[0].stop
        x0, x1 = max(0, s[1].start - 8), min(a.shape[1], s[1].stop + 8)
        tree = np.zeros(a.shape[:2], bool)
        for y in range(y0, y1):
            for x in range(x0, x1):
                if al[y, x] == 0:
                    continue
                hh, ss, vv = colorsys.rgb_to_hsv(r[y, x] / 255, g[y, x] / 255, b[y, x] / 255)
                if (0.1 < hh < 0.5 and ss > 0.2) or vv < 0.3:
                    tree[y, x] = True
        yield ndimage.binary_closing(tree, iterations=1) & (al > 0)


def main():
    folder = Path(sys.argv[1])
    a = np.array(Image.open(folder / "front.png").convert("RGBA"))
    still = a.copy()
    trees = []
    for k, mask in enumerate(tree_masks(a)):
        ys, xs = np.nonzero(mask)
        top, left, bottom, right = ys.min(), xs.min(), ys.max() + 1, xs.max() + 1
        sprite = np.zeros((bottom - top, right - left, 4), np.uint8)
        sprite[mask[top:bottom, left:right]] = a[top:bottom, left:right][mask[top:bottom, left:right]]
        Image.fromarray(sprite).save(folder / f"tree_{k}.png")
        trees.append({"file": f"tree_{k}.png", "x": int(left), "y": int(top)})
        for y in range(top, bottom):
            row = np.nonzero(mask[y])[0]
            if row.size == 0:
                continue
            l, r = row.min() - 1, row.max() + 1
            for x in row:
                # Whichever side is nearer gives the colour behind; open sky on that side stays open.
                src = l if (x - l) <= (r - x) and l >= 0 else r
                src = min(max(src, 0), a.shape[1] - 1)
                still[y, x] = a[y, src] if not mask[y, src] else (0, 0, 0, 0)
    Image.fromarray(still).save(folder / "front_still.png")
    (folder / "trees.json").write_text(json.dumps(trees, indent=1))
    old = folder / "sway_mask.png"
    if old.exists():
        old.unlink()
    print(len(trees), "trees")


if __name__ == "__main__":
    main()
