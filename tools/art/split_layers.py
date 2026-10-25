"""Split a background painting into sky, mountain and land layers for parallax.

It finds two outlines per column: where the mountains begin and where the land begins.
Usage: python tools/art/split_layers.py PAINTING --mountain-from 120 --stone-from 180 [--preview out.png]
"""
import argparse
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


def smooth(line, k):
    pad = np.pad(line, k, mode="edge")
    return np.array([np.median(pad[i:i + 2 * k + 1]) for i in range(len(line))]).astype(int)


def fill_below(rgb, top):
    # Hidden areas are filled by repeating the colour just above the cut, which matches the horizontal banding of pixel-art skies and hazy mountains.
    out = rgb.copy()
    for x in range(rgb.shape[1]):
        y0 = max(0, top[x] - 1)
        out[y0:, x] = rgb[y0, x]
    return out


def fill_rows(rgb, holes):
    # Pixel-art skies and mountains are painted in horizontal bands, so a hole is filled from the nearest visible pixel in the same row.
    out = rgb.copy()
    for y in range(rgb.shape[0]):
        bad = np.nonzero(holes[y])[0]
        if not len(bad):
            continue
        good = np.nonzero(~holes[y])[0]
        if not len(good):
            out[y] = out[y - 1] if y else out[y]
            continue
        idx = np.searchsorted(good, bad).clip(1, len(good) - 1)
        left, right = good[idx - 1], good[idx]
        nearest = np.where(np.abs(bad - left) <= np.abs(right - bad), left, right)
        out[y, bad] = rgb[y, nearest]
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("painting")
    p.add_argument("--mountain-from", type=int, default=120, help="mountains cannot start above this row")
    p.add_argument("--stone-from", type=int, default=180, help="aqueduct stone counts as land below this row")
    p.add_argument("--preview")
    a = p.parse_args()
    src = Path(a.painting)
    rgb = np.asarray(Image.open(src).convert("RGB"))
    H, W = rgb.shape[:2]
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV).astype(int)
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    yy = np.mgrid[0:H, 0:W][0]

    land_px = (((h >= 28) & (h <= 95) & (s > 45)) | (v < 75) | (((h <= 22) | (h >= 160)) & (v < 185) & (yy >= a.stone_from)))
    land_px &= yy >= a.mountain_from
    cool = (((h >= 100) & (h <= 175) & (s < 140) & (v >= 70)) | ((h <= 25) & (s < 110) & (v >= 120) & (v <= 215)))
    cool &= yy >= a.mountain_from
    # A mountain is solid for several rows; thin purple cloud edges are not.
    solid = cool.copy()
    for k in range(1, 6):
        solid[:-k] &= cool[k:] | land_px[k:]
    cool = solid

    def first(mask):
        line = np.full(W, H, int)
        for x in range(W):
            ys = np.nonzero(mask[:, x])[0]
            if len(ys):
                line[x] = ys.min()
        return line

    land_line_raw = first(land_px)
    # The ground line ignores tree tips by taking a high percentile over neighbouring columns.
    pad = np.pad(land_line_raw, 12, mode="edge")
    ground = np.array([np.percentile(pad[i:i + 25], 70) for i in range(W)]).astype(int)
    mtn_line = smooth(np.minimum(first(cool), ground), 6)

    land = np.zeros((H, W), bool)
    for x in range(W):
        land[ground[x]:, x] = True
    # Tall trees reach above the mountains, so foliage of any height counts as land when it connects to the ground.
    foliage = ((h >= 28) & (h <= 95) & (s > 45)) | (v < 75) | land_px
    n, lab = cv2.connectedComponents(foliage.astype(np.uint8), connectivity=8)
    touching = set(np.unique(lab[land & (lab > 0)]))
    land |= np.isin(lab, list(touching)) & foliage

    mtn = np.zeros((H, W), bool)
    for x in range(W):
        mtn[mtn_line[x]:, x] = True
    mtn &= ~land

    above = yy < mtn_line[None, :]
    sky_rgb = fill_below(fill_rows(rgb, land & above), mtn_line)
    band = ~above & ~land
    mtn_rgb = fill_rows(rgb, ~band & ~above)
    for x in range(W):
        col = np.nonzero(band[:, x])[0]
        low = col.max() if len(col) else min(mtn_line[x], H - 1)
        mtn_rgb[low:, x] = mtn_rgb[low, x]
    mtn_alpha = np.zeros((H, W), np.uint8)
    for x in range(W):
        mtn_alpha[mtn_line[x]:, x] = 255

    out = src.parent
    Image.fromarray(sky_rgb).save(out / "layer_sky.png")
    Image.fromarray(np.dstack([mtn_rgb, mtn_alpha])).save(out / "layer_mountains.png")
    Image.fromarray(np.dstack([rgb, land.astype(np.uint8) * 255])).save(out / "layer_land.png")
    if a.preview:
        pv = rgb.copy()
        for x in range(W):
            if mtn_line[x] < H: pv[mtn_line[x], x] = (0, 160, 255)
            if ground[x] < H: pv[ground[x], x] = (255, 0, 255)
        Image.fromarray(pv).resize((W * 2, H * 2), Image.NEAREST).save(a.preview)


if __name__ == "__main__":
    main()
