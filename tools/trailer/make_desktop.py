"""Draw a made-up computer desktop for showing the game's desktop strip: an original abstract wallpaper, a few desktop
icons with everyday names, and a plain taskbar along the bottom. Nothing in it copies a real operating system's logo,
wallpaper or icons; it only has to read at a glance as somebody's desktop with the farm running along its bottom.

Usage: python tools/trailer/make_desktop.py
Writes game/tools/trailer/desktop_1920x1080.png for the trailer's desktop shot, and desktop_2560x1440.png for the
store screenshot, which make_store_art.py lays the strip over. The labels use the system's Segoe UI.
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "tools" / "trailer"
FONT = "C:/Windows/Fonts/segoeui.ttf"
ICON = ROOT / "store" / "steam_page" / "community_icon_184x184.jpg"
# Each icon on the desktop, down the left edge: what it looks like and its name.
ICONS = [("bin", "Recycle Bin"), ("game", "Farmus Maximus"), ("folder", "Homework"), ("folder", "Taxes 2026"),
         ("sheet", "Quarterly report.xlsx"), ("doc", "Definitely working.docx")]


def wallpaper(w, h):
    """A deep blue field with soft glowing ribbons sweeping across it, drawn smooth rather than in pixels."""
    y, x = np.mgrid[0:h, 0:w].astype(float)
    u, v = x / w, y / h
    base = np.stack([14 + 20 * v, 22 + 40 * v, 58 + 70 * (1 - abs(u - 0.6))], -1)
    img = base.copy()
    for k, (hue, width, amp, phase, height) in enumerate([
            ((90, 150, 255), 0.07, 0.10, 0.0, 0.58), ((150, 110, 255), 0.05, 0.13, 1.7, 0.50),
            ((80, 210, 255), 0.04, 0.08, 3.1, 0.66), ((200, 140, 255), 0.03, 0.06, 4.4, 0.44)]):
        centre = height + amp * np.sin(u * math.pi * 1.6 + phase) + 0.05 * np.sin(u * 7.0 + phase * 2)
        glow = np.exp(-((v - centre) / width) ** 2) * (0.35 + 0.65 * np.exp(-((u - 0.55) / 0.5) ** 2))
        img += glow[..., None] * np.array(hue) * 0.8
    img = np.clip(img, 0, 255).astype(np.uint8)
    return Image.fromarray(img).filter(ImageFilter.GaussianBlur(w / 400))


def draw_icon(kind, size):
    """A simple flat icon of each kind, size pixels square."""
    pic = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(pic)
    s = size / 64
    if kind == "folder":
        d.rounded_rectangle((4 * s, 12 * s, 30 * s, 24 * s), 3 * s, fill=(224, 170, 50))
        d.rounded_rectangle((4 * s, 18 * s, 60 * s, 54 * s), 4 * s, fill=(250, 200, 80))
        d.rectangle((4 * s, 22 * s, 60 * s, 24 * s), fill=(255, 220, 120))
    elif kind in ("doc", "sheet"):
        colour = (40, 120, 220) if kind == "doc" else (30, 150, 80)
        d.polygon([(12 * s, 4 * s), (42 * s, 4 * s), (54 * s, 16 * s), (54 * s, 60 * s), (12 * s, 60 * s)], fill=(250, 250, 252))
        d.polygon([(42 * s, 4 * s), (54 * s, 16 * s), (42 * s, 16 * s)], fill=(210, 214, 222))
        for k in range(5):
            d.rectangle((18 * s, (24 + 6 * k) * s, 48 * s, (26 + 6 * k) * s), fill=(200, 205, 214))
        d.rounded_rectangle((6 * s, 34 * s, 30 * s, 56 * s), 3 * s, fill=colour)
        d.text((18 * s, 45 * s), "W" if kind == "doc" else "X", fill="white", anchor="mm",
               font=ImageFont.truetype(FONT, int(16 * s)))
    elif kind == "bin":
        d.rounded_rectangle((14 * s, 16 * s, 50 * s, 60 * s), 4 * s, fill=(225, 230, 240), outline=(170, 180, 200), width=max(1, int(2 * s)))
        d.rectangle((10 * s, 10 * s, 54 * s, 16 * s), fill=(200, 208, 222))
        d.rectangle((26 * s, 6 * s, 38 * s, 10 * s), fill=(200, 208, 222))
        for k in range(3):
            x = (22 + 10 * k) * s
            d.rectangle((x, 22 * s, x + 2 * s, 54 * s), fill=(180, 188, 205))
    elif kind == "game":
        art = Image.open(ICON).convert("RGBA").resize((int(52 * s), int(52 * s)), Image.LANCZOS)
        mask = Image.new("L", art.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, art.size[0] - 1, art.size[1] - 1), int(10 * s), fill=255)
        pic.paste(art, (int(6 * s), int(6 * s)), mask)
    return pic


def desktop(w, h):
    scale = h / 1080
    img = wallpaper(w, h).convert("RGBA")
    font = ImageFont.truetype(FONT, int(15 * scale))
    icon = int(56 * scale)
    cell = int(104 * scale)
    for k, (kind, name) in enumerate(ICONS):
        x, y = int(18 * scale), int(14 * scale) + k * cell
        img.alpha_composite(draw_icon(kind, icon), (x + (cell - icon) // 2 - int(12 * scale), y))
        # Labels wrap onto two lines under the icon, with a soft shadow so they read on any wallpaper.
        words, lines, line = name.split(), [], ""
        for word in words:
            trial = (line + " " + word).strip()
            if font.getlength(trial) > cell * 0.95 and line:
                lines.append(line)
                line = word
            else:
                line = trial
        lines.append(line)
        text = Image.new("RGBA", img.size, (0, 0, 0, 0))
        td = ImageDraw.Draw(text)
        cx = x + (cell - icon) // 2 - int(12 * scale) + icon // 2
        for n, ln in enumerate(lines[:2]):
            ty = y + icon + int(4 * scale) + n * int(18 * scale)
            td.text((cx + 1, ty + 1), ln, font=font, fill=(0, 0, 0, 200), anchor="ma")
            td.text((cx, ty), ln, font=font, fill=(255, 255, 255, 255), anchor="ma")
        img.alpha_composite(text)
    # The taskbar: a dark translucent band with a row of plain app buttons in the middle and a clock on the right.
    bar = int(48 * scale)
    band = Image.new("RGBA", (w, bar), (24, 26, 38, 225))
    img.alpha_composite(band, (0, h - bar))
    d = ImageDraw.Draw(img)
    colours = [(90, 140, 230), (240, 190, 80), (80, 190, 140), (220, 90, 90), (160, 120, 230), (90, 200, 220)]
    size = int(30 * scale)
    gap = int(12 * scale)
    total = len(colours) * size + (len(colours) - 1) * gap + int(200 * scale) + gap
    x = (w - total) // 2
    y = h - bar + (bar - size) // 2
    d.rounded_rectangle((x, y, x + int(200 * scale), y + size), size // 2, fill=(50, 54, 72))
    d.text((x + int(16 * scale), y + size // 2), "Search", font=font, fill=(190, 194, 210), anchor="lm")
    x += int(200 * scale) + gap
    for c in colours:
        d.rounded_rectangle((x, y, x + size, y + size), int(7 * scale), fill=c)
        x += size + gap
    clock = ImageFont.truetype(FONT, int(14 * scale))
    d.text((w - int(18 * scale), h - bar + int(14 * scale)), "10:42 AM", font=clock, fill="white", anchor="ra")
    d.text((w - int(18 * scale), h - bar + int(31 * scale)), "28/10/2026", font=clock, fill="white", anchor="ra")
    return img.convert("RGB"), bar


def main():
    for w, h in ((1920, 1080), (2560, 1440)):
        img, bar = desktop(w, h)
        img.save(OUT / f"desktop_{w}x{h}.png")
        print(f"desktop {w}x{h}, taskbar {bar} tall")


if __name__ == "__main__":
    main()
