"""Draw the golden laurel wreath given for the Triumph achievement: a journal picture and the small wreath that hangs
above the villa door. It is drawn pixel by pixel as a ring of leaves pointing up both sides from a red ribbon at
the bottom, open at the top like a real victor's wreath.

Usage: python tools/art/make_laurel.py
"""
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites"
DARK, MID, LIGHT, SHINE = (128, 86, 30), (186, 132, 42), (230, 182, 70), (252, 222, 130)
RIBBON, RIBBON_DARK = (190, 48, 46), (128, 28, 32)


def wreath(size, radius, band, leaf):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx, cy = size / 2 - 0.5, size / 2 - 1.0
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy)
            off = r - radius
            if abs(off) > band:
                continue
            # Angle up from the bottom of the ring, the same on both sides, so the leaves point up each side.
            up = math.degrees(math.atan2(abs(dx), dy))
            if up < 12 or up > 160:
                continue
            along = math.radians(up) * radius
            phase = (along + abs(off) * 1.3) % leaf
            if phase > leaf - 0.9:
                if abs(off) > band - 1:
                    continue
                colour = DARK
            elif phase < 1.0:
                colour = SHINE if off < 0 else LIGHT
            else:
                colour = LIGHT if off < 0 else MID
            img.putpixel((x, y), colour + (255,))
    # The ribbon tied at the bottom, with its two ends hanging down.
    bx, by = round(cx), round(cy + radius)
    for x, y, c in [(0, 0, RIBBON), (-1, 0, RIBBON), (1, 0, RIBBON), (0, -1, RIBBON_DARK), (-1, 1, RIBBON_DARK), (1, 1, RIBBON_DARK),
                    (-2, 2, RIBBON), (2, 2, RIBBON), (-2, 3, RIBBON_DARK), (2, 3, RIBBON_DARK)]:
        if 0 <= bx + x < size and 0 <= by + y < size:
            img.putpixel((bx + x, by + y), c + (255,))
    return img


if __name__ == "__main__":
    wreath(32, 10.5, 3.2, 3.4).save(ROOT / "icons32" / "laurel.png")
    wreath(15, 4.6, 1.6, 2.6).save(ROOT / "decorations" / "laurel_wreath.png")
    print("laurel")
