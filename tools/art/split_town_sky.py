"""Split the market town painting so its clouds can drift: a clean sky, one sprite per cloud, and the town in front.

The sky is found by flooding down from the top edge across small colour steps; buildings, trees and mountains stop it.
Clouds are the sky pixels in the painting's cloud colours; the sky behind them is filled in and snapped back to the
sky's own colours so it stays pixel art.
Usage: python tools/art/split_town_sky.py game/assets/backgrounds/market/painting.png game/assets/backgrounds/market/sky
Writes OUT/base.png (the sky alone), OUT/cloud_NN.png, OUT/clouds.json and OUT/front.png (the town, sky cut out).
"""
import json
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

# Points inside clouds whose edges are too sharp for the flood to cross into.
SEEDS = [(5, 240), (30, 300), (60, 200), (25, 165), (30, 150), (55, 350), (52, 380), (58, 330), (60, 320), (61, 340), (50, 412)]
STEP = 70
# Past this column the sky meets the pale stone of the right-hand house, so only very small steps count as sky.
RIGHT_EDGE = 428
LOWEST = 130
SUN = (86, 38, 122, 82)
CLOUD_COLOURS = [(212, 185, 186), (253, 235, 197), (234, 206, 191), (240, 198, 163), (254, 237, 183), (255, 249, 206), (246, 221, 188)]


def sky_mask(im):
    H, W = im.shape[:2]
    sky = np.zeros((H, W), bool)
    q = deque([(0, x) for x in range(100, 440)] + SEEDS)
    while q:
        y, x = q.popleft()
        if sky[y, x]:
            continue
        sky[y, x] = True
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < LOWEST and 0 <= nx < W and not sky[ny, nx]:
                if np.abs(im[ny, nx] - im[y, x]).sum() <= (STEP if nx <= RIGHT_EDGE else 25):
                    q.append((ny, nx))
    # Specks of cloud shading the flood could not step into are closed over.
    holes = ndimage.binary_fill_holes(sky) & ~sky
    lab, n = ndimage.label(holes)
    for i in range(1, n + 1):
        if (lab == i).sum() < 60:
            sky[lab == i] = True
    return sky


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    rgb = np.asarray(Image.open(src).convert("RGB")).astype(int)
    H, W = rgb.shape[:2]
    sky = sky_mask(rgb)
    cloud = sky & np.isin(rgb.reshape(-1, 3).dot([65536, 256, 1]), [r * 65536 + g * 256 + b for r, g, b in CLOUD_COLOURS]).reshape(H, W)
    x0, y0, x1, y1 = SUN
    cloud[y0:y1, x0:x1] = False
    # Pixels of sky colour tucked inside a cloud travel with it.
    cloud = (ndimage.binary_closing(cloud, np.ones((3, 3))) | cloud) & sky
    lab, n = ndimage.label(cloud, np.ones((3, 3)))
    clouds = []
    keep = np.zeros_like(cloud)
    for i in range(1, n + 1):
        part = lab == i
        if part.sum() < 20:
            continue
        keep |= part
        ys, xs = np.nonzero(part)
        x, y, w, h = xs.min(), ys.min(), xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
        sprite = np.zeros((h, w, 4), np.uint8)
        sprite[..., :3] = rgb[y:y + h, x:x + w]
        sprite[..., 3] = part[y:y + h, x:x + w] * 255
        name = f"cloud_{len(clouds):02d}.png"
        Image.fromarray(sprite).save(out / name)
        clouds.append({"file": name, "x": int(x), "y": int(y), "w": int(w), "h": int(h)})
    # The sky behind each cloud is filled row by row, blending from the sky just left of it to the sky just right of
    # it, and every filled pixel then takes the nearest of the sky's own colours.
    palette = np.array(sorted({tuple(c) for c in rgb[sky & ~cloud]} - set(CLOUD_COLOURS)))
    base = rgb.copy()
    for y in range(H):
        x = 0
        while x < W:
            if not cloud[y, x]:
                x += 1
                continue
            end = x
            while end < W and cloud[y, end]:
                end += 1
            left = rgb[y, x - 1] if x > 0 and sky[y, x - 1] else None
            right = rgb[y, end] if end < W and sky[y, end] else None
            left = right if left is None else left
            right = left if right is None else right
            for k in range(x, end):
                if left is None:
                    plain = rgb[y][sky[y] & ~cloud[y]]
                    base[y, k] = base[y - 1, k] if y > 0 else plain[len(plain) // 2]
                    continue
                mix = left + (right - left) * (k - x + 1) / (end - x + 1)
                base[y, k] = palette[np.abs(palette - mix).sum(1).argmin()]
            x = end
    Image.fromarray(base.astype(np.uint8)).save(out / "base.png")
    (out / "clouds.json").write_text(json.dumps(clouds, indent=1))
    front = np.dstack([rgb, np.where(sky, 0, 255)]).astype(np.uint8)
    Image.fromarray(front).save(out / "front.png")
    print(len(clouds), "clouds")


if __name__ == "__main__":
    main()
