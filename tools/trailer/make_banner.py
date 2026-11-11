"""Make the YouTube channel banner from a picture the game renders at one screen pixel to the game pixel.

The banner is 2560x1440, but computers and phones show only a strip across its middle (1546x423 at the narrowest,
2560x423 at the widest) and only televisions show the whole of it. So the estate is enlarged a whole number of times,
which keeps its pixels square, and placed so the strip holds the hills and the farm with the logo in the sky above
them, at the same pixel size as the estate. Below the road, which only a television shows, the ground fades to dark.

Usage: python tools/trailer/make_banner.py RENDER.png OUT.png [shift]
  RENDER.png is a game screenshot taken at one screen pixel to the game pixel and at least 1280x720, such as
  --window=1600x720 --scale=1 --shot=RENDER.png --quit; the banner shows its middle 1280 columns, or shift game pixels
  to the right of the middle, so a building can stand clear of the logo.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
LOGO = HERE.parents[1] / "game" / "tools" / "trailer" / "logo.png"
SIZE = (2560, 1440)
# Two screen pixels to the game pixel leave room in the strip for sky, hills and the farm below the logo.
SCALE = 2
STRIP = (508, 931)
# The game draws its road along the bottom 16 game pixels of the picture.
ROAD = 16


def main():
    render = Image.open(sys.argv[1]).convert("RGB")
    out_path = sys.argv[2]
    shift = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    left = (render.width - SIZE[0] // SCALE) // 2 + shift
    render = render.crop((left, 0, left + SIZE[0] // SCALE, render.height))
    scale = SCALE
    big = render.resize((render.width * scale, render.height * scale), Image.NEAREST)
    banner = Image.new("RGB", SIZE, (20, 16, 22))
    # The road's foot sits at the strip's foot.
    top = STRIP[1] - big.height
    banner.paste(big, (0, top))
    # Under the road the ground takes the road's own darkest colour and fades towards black, in bands a game pixel tall.
    pixels = np.array(banner)
    road = np.array(big.crop((0, big.height - ROAD * scale, big.width, big.height))).reshape(-1, 3)
    ground = np.percentile(road, 20, axis=0)
    for y in range(STRIP[1], SIZE[1], scale):
        dark = max(0.12, 0.8 - (y - STRIP[1]) / 600.0)
        pixels[y:y + scale] = (ground * dark).astype(np.uint8)
    banner = Image.fromarray(pixels)
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.resize((logo.width * scale, logo.height * scale), Image.NEAREST)
    # The logo sits in the upper part of the strip, over the sky, leaving the farm beneath it in view.
    at = ((SIZE[0] - logo.width) // 2, STRIP[0] + 16)
    banner.paste(logo, at, logo)
    banner.save(out_path)
    print(f"banner: {out_path}")


if __name__ == "__main__":
    main()
