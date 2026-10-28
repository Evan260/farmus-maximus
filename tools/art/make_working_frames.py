"""Make the short loops that play while a building works, from its working picture: the mill's upper stone turns,
its furrows sliding past, with the sweep beam swinging round the shaft; the olive press turns its screw and swings the
bar through its nut, and the wine press turns its screw and rocks its weighted beam;
flames lick along the floor of the bakery oven.

Usage: python tools/art/make_working_frames.py
Writes game/assets/sprites/buildings/<id>_working_anim/frame_00.png and on.
"""
import colorsys
import math
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DIR = ROOT / "game" / "assets" / "sprites" / "buildings"
FRAMES = 8
# The presses' levers take a slow, whole turn or rock, so they have more frames than the other loops.
LEVER_FRAMES = 16


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


def screw_frame(base, box, period, k):
    """The press screw turned by k steps: its threads move down a pixel each step, repeating every period rows."""
    x0, y0, x1, y1 = box
    f = base.copy()
    shift = k % period
    for y in range(y0, y1):
        src = y - shift
        if src < y0:
            src += period
        for x in range(x0, x1):
            if base[y, x, 3] and base[src, x, 3]:
                f[y, x] = base[src, x]
    return f


def olive_press():
    """The olive press: its screw turns, and the bar through the screw's nut swings round with it, shortening as it
    turns towards or away from us and passing behind the press while it points away."""
    base = load("olive_press")
    bar_box = (47, 33, 82, 43)
    x0, y0, x1, y1 = bar_box
    bar = base[y0:y1, x0:x1].copy()
    empty = base.copy()
    empty[y0:y1, x0:x1] = 0
    nut_left = 35
    frames = []
    for k in range(LEVER_FRAMES):
        f = screw_frame(empty, (39, 20, 46, 33), 4, k)
        c = math.cos(2 * math.pi * k / LEVER_FRAMES)
        # Pointing away, the bar stops short of the picture's edge, behind the near post.
        length = round(abs(c) * (bar.shape[1] if c >= 0 else min(bar.shape[1], nut_left - 3)))
        for i in range(length):
            col = bar[:, int(i * bar.shape[1] / max(1, length))]
            x = x0 + i if c >= 0 else nut_left - 1 - i
            for r in range(bar.shape[0]):
                if not col[r, 3]:
                    continue
                y = y0 + r
                # Pointing away, the bar is behind the press and shows only against the open air.
                if c < 0 and f[y, x, 3]:
                    continue
                f[y, x] = col[r]
        frames.append(f)
    save("olive_press", frames)


def wine_press():
    """The wine press: its screw turns while the long beam rocks on the press head, the hanging stone weight at its
    far end sinking and rising a few pixels as the grapes are squeezed."""
    base = load("wine_press")
    pivot_x, x0, y0, x1, y1 = 38, 38, 25, 82, 48
    stone = (68, 82)
    moving = base[y0:y1, x0:x1].copy()
    empty = base.copy()
    empty[y0:y1, x0:x1] = 0
    frames = []
    for k in range(LEVER_FRAMES):
        f = screw_frame(empty, (29, 17, 36, 30), 4, k)
        tilt = 0.075 * math.sin(2 * math.pi * k / LEVER_FRAMES)
        drop_at_stone = round((sum(stone) / 2 - pivot_x) * tilt)
        for i in range(moving.shape[1]):
            x = x0 + i
            # The beam leans from its pivot; the stone hangs level and moves as one block with the beam's end.
            dy = drop_at_stone if stone[0] <= x < stone[1] else round((x - pivot_x) * tilt)
            for r in range(moving.shape[0]):
                if moving[r, i, 3]:
                    y = y0 + r + dy
                    if 0 <= y < f.shape[0]:
                        f[y, x] = moving[r, i]
        frames.append(f)
    save("wine_press", frames)


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
    olive_press()
    wine_press()
    oven()
