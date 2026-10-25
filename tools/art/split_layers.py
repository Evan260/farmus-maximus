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

    # Hazy distant mountains can be faintly green, so foliage must be clearly green and saturated to count as land.
    land_px = (((h >= 28) & (h <= 85) & (s > 60)) | (v < 75) | (((h <= 22) | (h >= 160)) & (v < 185) & (yy >= a.stone_from)))
    land_px &= yy >= a.mountain_from
    # The sky near the horizon is warm and bright; hazy mountains are blue or a dusty pink that is paler or duller than the sky.
    sky_px = (((h >= 11) & (h <= 24) & (s >= 100) & (v >= 180)) | ((h >= 19) & (h <= 24) & (v >= 245))) | (yy < a.mountain_from)

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

    land = np.zeros((H, W), bool)
    for x in range(W):
        land[ground[x]:, x] = True
    # Tall trees reach above the mountains, so foliage of any height counts as land when it connects to the ground.
    foliage = ((h >= 28) & (h <= 85) & (s > 60)) | (v < 75) | land_px
    n, lab = cv2.connectedComponents(foliage.astype(np.uint8), connectivity=8)
    touching = set(np.unique(lab[land & (lab > 0)]))
    land |= np.isin(lab, list(touching)) & foliage

    # A mountain top is the first row that stays non-sky for a few rows, so a stray dark cloud pixel does not count.
    solid = ~sky_px
    for k in range(1, 4):
        solid[:-k] &= ~sky_px[k:]
    raw = first(solid)
    # Where land is the first thing below the sky, the mountain behind it is hidden, so its outline is bridged from its visible neighbours.
    known = np.array([raw[x] < H and not land[raw[x], x] for x in range(W)])
    xs = np.arange(W)
    mtn_line = np.interp(xs, xs[known], raw[known]).astype(int) if known.any() else ground.copy()
    mtn_line = np.minimum(smooth(mtn_line, 2), ground)

    above = yy < mtn_line[None, :]
    sky_rgb = rgb.copy()
    hidden = ~above | land
    for y in range(H):
        seen = ~hidden[y]
        # The hidden part of each row takes that row's typical visible colour, because horizon skies are painted in flat horizontal bands.
        sky_rgb[y, ~seen] = np.median(rgb[y, seen], axis=0).astype(np.uint8) if seen.sum() >= 8 else sky_rgb[y - 1, ~seen]
    band = ~above & ~land
    mtn_rgb = fill_rows(rgb, ~band & ~above)
    # Below the mountains, the hidden area becomes an even haze in the valley's average colour, because panning
    # reveals it and repeated column colours would show as stripes.
    lows = []
    for x in range(W):
        col = np.nonzero(band[:, x])[0]
        lows.append(col.max() if len(col) else min(mtn_line[x], H - 1))
    haze = np.median(np.array([mtn_rgb[lows[x], x] for x in range(W)]), axis=0).astype(np.uint8)
    for x in range(W):
        low = lows[x]
        for y in range(low + 1, H):
            t = min(1.0, (y - low) / 4.0)
            mtn_rgb[y, x] = (mtn_rgb[low, x] * (1 - t) + haze * t).astype(np.uint8)
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
