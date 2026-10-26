"""Find the cypresses in the market town's front layer and write a mask the sway shader reads: red marks a tree's
pixels, green how far up the tree each one is, so the tops move with the wind and the trunks stay put.

Usage: python tools/art/make_town_sway_mask.py game/assets/backgrounds/market/sky
Run it again after re-splitting the town painting.
"""
import colorsys
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


def main():
    folder = Path(sys.argv[1])
    a = np.array(Image.open(folder / "front.png").convert("RGBA")).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    lit = (al > 0) & (g >= r) & (g > b + 4) & (r + g + b < 420)
    lab, _ = ndimage.label(lit)
    out = np.zeros(a.shape, np.uint8)
    for i, s in enumerate(ndimage.find_objects(lab)):
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
        tree = ndimage.binary_closing(tree, iterations=1)
        ys, xs = np.nonzero(tree)
        for y, x in zip(ys, xs):
            up = (y1 - y) / max(1, h)
            out[y, x] = (255, int(255 * min(1.0, up ** 1.4)), 0, 255)
    Image.fromarray(out).save(folder / "sway_mask.png")
    print("mask", int((out[..., 0] > 0).sum()), "pixels")


if __name__ == "__main__":
    main()
