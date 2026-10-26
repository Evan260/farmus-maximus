"""Make the short loops that play while a building works, from its working picture: the mill's upper stone turns,
its furrows sliding past, with the sweep beam swinging round the shaft; the olive and wine presses turn their screws;
flames lick along the floor of the bakery oven.

Usage: python tools/art/make_working_frames.py
Writes game/assets/sprites/buildings/<id>_working_anim/frame_00.png and on, eight frames each.
"""
import colorsys
import math
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DIR = ROOT / "game" / "assets" / "sprites" / "buildings"
FRAMES = 8


def load(name):
    return np.array(Image.open(DIR / f"{name}_working.png").convert("RGBA"))


def save(name, frames):
    out = DIR / f"{name}_working_anim"
    out.mkdir(exist_ok=True)
    for k, f in enumerate(frames):
        Image.fromarray(f).save(out / f"frame_{k:02d}.png")
    print(name, len(frames))


def is_stone(px):
    r, g, b, a = (int(v) for v in px)
    if a == 0:
        return False
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return s < 0.3 and v > 0.32


def mill():
    base = load("mill")
    back = base[36, 40].copy()
    beam_rows = [base[38, 40].copy(), base[39, 40].copy(), base[40, 40].copy()]
    shaft = (48, 52)
    frames = []
    for k in range(FRAMES):
        f = base.copy()
        # The upper stone turns: a chiselled furrow every eight pixels slides along it.
        for y in range(45, 55):
            xs = [x for x in range(38, 63) if is_stone(base[y, x])]
            if len(xs) < 3:
                continue
            for x in range(xs[0] + 1, xs[-1]):
                if not is_stone(base[y, x]):
                    continue
                phase = (x + k) % 8
                if phase == 0:
                    f[y, x, :3] = (base[y, x, :3] * 0.72).astype(np.uint8)
                elif phase == 1:
                    f[y, x, :3] = np.minimum(base[y, x, :3].astype(int) + 18, 255).astype(np.uint8)
        # The sweep beam swings round the shaft, so from the side it looks shorter as it turns towards us.
        for y in range(36, 44):
            for x in range(33, 62):
                beam = y in (38, 39, 40) or 55 <= x <= 59
                if beam and not shaft[0] <= x < shaft[1] and base[y, x, 3]:
                    f[y, x] = back
        reach = round(15 * abs(math.cos(math.pi * k / FRAMES)))
        for i, y in enumerate((38, 39, 40)):
            for x in range(shaft[0] - reach, shaft[1] + reach):
                if not shaft[0] <= x < shaft[1]:
                    f[y, x] = beam_rows[i]
        frames.append(f)
    save("mill", frames)


def screw(name, box, period):
    """Turns a press screw: its threads move down by a pixel each frame, repeating every period rows."""
    base = load(name)
    x0, y0, x1, y1 = box
    frames = []
    for k in range(FRAMES):
        f = base.copy()
        shift = k % period
        for y in range(y0, y1):
            src = y - shift
            if src < y0:
                src += period
            for x in range(x0, x1):
                if base[y, x, 3] and base[src, x, 3]:
                    f[y, x] = base[src, x]
        frames.append(f)
    save(name, frames)


def oven():
    """Flames along the oven floor, a different height at each place in each frame, and a warm glow on the dark
    inside of the mouth that rises and falls with them."""
    base = load("bakery")
    rng = np.random.default_rng(5)
    fire = [(110, 30, 20), (176, 62, 24), (226, 118, 36), (250, 186, 76), (255, 230, 150)]
    heights = rng.integers(1, 5, size=(FRAMES, 16))
    frames = []
    for k in range(FRAMES):
        f = base.copy()
        glow = 0.15 + 0.1 * math.sin(k / FRAMES * 2 * math.pi * 2)
        for y in range(46, 61):
            for x in range(53, 71):
                r, g, b, a = (int(v) for v in base[y, x])
                if a and r + g + b < 200:
                    warm = glow * (y - 44) / 16
                    f[y, x, :3] = (min(255, r + int(150 * warm)), min(255, g + int(60 * warm)), b)
        for i, x in enumerate(range(55, 70)):
            h = int(heights[k, i] + heights[(k + 1) % FRAMES, (i + 1) % 16]) // 2 + 1
            for d in range(h):
                y = 59 - d
                r, g, b, a = (int(v) for v in base[y, x])
                if a and r + g + b < 260:
                    f[y, x, :3] = fire[min(len(fire) - 1, h - d)]
        frames.append(f)
    save("bakery", frames)


if __name__ == "__main__":
    mill()
    screw("olive_press", (39, 20, 46, 33), 4)
    screw("wine_press", (29, 17, 36, 30), 4)
    oven()
