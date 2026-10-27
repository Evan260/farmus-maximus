"""Make the Steam achievement icons: a 64 by 64 picture for each achievement, and a grey one for before it is earned.

Each icon is a framed tile with a piece of the game's own art in it, chosen per achievement below. Pixel art is
enlarged only by whole steps so it stays crisp; pictures too big for the tile, such as the villa, are shrunk smoothly.
Steamworks takes JPG files, so the tiles have no transparency.

Usage: python tools/art/make_achievement_icons.py
Writes store/achievements/<id>.jpg and <id>_locked.jpg, plus store/achievements/sheet.png to look them over.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[2]
SPRITES = ROOT / "game" / "assets" / "sprites"
OUT = ROOT / "store" / "achievements"
SIZE = 64
INNER = 54

INK = (74, 46, 36)
GOLD = (214, 160, 72)
GOLD_LIGHT = (246, 214, 140)
GOLD_DARK = (150, 98, 44)
CREAM = (250, 238, 210)
PARCH = (232, 210, 162)
NIGHT = (34, 40, 78)
NIGHT_LOW = (70, 64, 112)

# The picture for each achievement: a sprite path under game/assets/sprites, or the name of a drawing below.
ART = {
    "first_harvest": "lavender/bloom_3",
    "harvest_100": "icons32/lavender",
    "harvest_1000": "icons32/grapes",
    "harvest_10000": "icons32/wheat",
    "earn_1000": "icons32/sestertius",
    "earn_10000": "draw:coins",
    "earn_100000": "decorations/golden_statue",
    "cart_10": "farm/cart",
    "cart_100": "donkey/east",
    "market_visit": "people/traveller/east",
    "sell_100": "people/trader/east",
    "order_1": "icons32/honey",
    "order_25": "icons32/lavender_honey",
    "aureus": "icons32/aureus",
    "villa_2": "villa/stage2",
    "villa_3": "villa/stage3",
    "villa_4": "villa/stage4",
    "villa_5": "villa/stage5",
    "villa_6": "villa/stage6",
    "villa_7": "villa/stage7",
    "first_deed": "draw:deed",
    "all_zones": "trees/umbrella_pine_1",
    "first_building": "buildings/bakery_working",
    "all_buildings": "buildings/mill_working",
    "first_helper": "people/farmhand/east",
    "all_helpers": "draw:household",
    "fine": "draw:fine",
    "excellent": "draw:excellent",
    "lavender_oil": "icons32/lavender_oil",
    "bath_oil": "icons32/bath_oil",
    "cheese": "icons32/cheese",
    "excellent_wine": "icons32/aged_wine",
    "white_lavender": "icons32/white_lavender",
    "truffle": "icons32/truffle",
    "pets_50": "dog/happy_east/frame_04",
    "rainbow": "draw:rainbow",
    "shooting_star": "draw:shooting_star",
    "fox": "animals/fox/east",
    "cat_and_dog": "draw:cat_and_dog",
    "blessing": "buildings/lararium_working",
    "all_festivals": "decorations/garland_arch",
    "decorations_5": "decorations/fountain",
    "journal_half": "draw:journal_half",
    "journal_full": "draw:journal_full",
    "homely": "draw:hearth",
    "triumph": "icons32/laurel",
}
# Pictures given the whole inside of the frame, so a small one can be drawn at twice its size.
ROOMY = {"triumph"}
# Achievements whose tile is the night sky rather than parchment.
NIGHT_TILES = {"shooting_star"}


def sprite(path):
    img = Image.open(SPRITES / f"{path}.png").convert("RGBA")
    return img.crop(img.getbbox())


def fit(img, room=INNER):
    """The picture at the largest whole-number scale that fits the room, or shrunk smoothly if even 1x is too big."""
    scale = min(room // img.width, room // img.height)
    if scale >= 1:
        return img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    ratio = min(room / img.width, room / img.height)
    return img.resize((max(1, round(img.width * ratio)), max(1, round(img.height * ratio))), Image.LANCZOS)


def star(img, x, y, colour=GOLD_LIGHT, edge=GOLD_DARK):
    shape = ["..#..", ".###.", "#####", ".###.", ".#.#."]
    for dy, row in enumerate(shape):
        for dx, c in enumerate(row):
            if c == "#":
                for ox, oy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    px, py = x + dx + ox, y + dy + oy
                    if img.getpixel((px, py))[3] == 0 or (0 <= dx + ox < 5 and 0 <= dy + oy < 5 and shape[dy + oy][dx + ox] != "#"):
                        img.putpixel((px, py), edge + (255,))
    for dy, row in enumerate(shape):
        for dx, c in enumerate(row):
            if c == "#":
                img.putpixel((x + dx, y + dy), colour + (255,))


def drawing(name):
    canvas = Image.new("RGBA", (INNER, INNER), (0, 0, 0, 0))
    if name == "coins":
        coin = fit(sprite("icons32/sestertius"), 30)
        for i, (x, y) in enumerate(((4, 20), (20, 8), (22, 24))):
            canvas.alpha_composite(coin, (x, y))
        return canvas
    if name in ("fine", "excellent"):
        item = fit(sprite("icons32/olives" if name == "fine" else "icons32/herbs"), 44)
        canvas.alpha_composite(item, ((INNER - item.width) // 2, INNER - item.height))
        for i in range(1 if name == "fine" else 3):
            star(canvas, 4 + i * 8, 4)
        return canvas
    if name == "household":
        a = sprite("people/farmhand/east")
        b = sprite("people/beekeeper/east").transpose(Image.FLIP_LEFT_RIGHT)
        c = sprite("people/miller/east")
        for img, x in ((a, 2), (c, 19), (b, 36)):
            canvas.alpha_composite(img, (x, INNER - img.height))
        return canvas
    if name == "cat_and_dog":
        dog = sprite("dog/sleep_east/frame_08")
        cat = sprite("animals/cat_small/sleep_east/frame_05")
        # A grey tabby asleep on the dog's back, so the two coats stand apart at icon size.
        alpha = cat.getchannel("A")
        cat = ImageEnhance.Brightness(ImageEnhance.Color(cat.convert("RGB")).enhance(0.0)).enhance(1.15).convert("RGBA")
        cat.putalpha(alpha)
        pair = Image.new("RGBA", (dog.width, dog.height + cat.height - 4), (0, 0, 0, 0))
        pair.alpha_composite(dog, (0, pair.height - dog.height))
        pair.alpha_composite(cat, (dog.width - cat.width - 6, 0))
        canvas.alpha_composite(pair, ((INNER - pair.width) // 2, (INNER - pair.height) // 2 + 4))
        return canvas
    if name == "rainbow":
        bands = [(214, 70, 60), (232, 140, 60), (236, 206, 80), (110, 176, 90), (80, 130, 200), (130, 96, 180)]
        cx, cy, r0 = INNER // 2, 44, 24
        a = np.zeros((INNER, INNER, 4), np.uint8)
        ys, xs = np.mgrid[0:INNER, 0:INNER]
        d = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2)
        for i, col in enumerate(bands):
            band = (d <= r0 - i * 3) & (d > r0 - (i + 1) * 3) & (ys <= cy)
            a[band] = col + (255,)
        img = Image.fromarray(a)
        cloud = [(8, 42, 10), (16, 40, 9), (40, 42, 10), (46, 40, 8)]
        for x, y, r in cloud:
            for py in range(y - r // 2, y + r // 2):
                for px in range(x - r, x + r):
                    if ((px - x) / r) ** 2 + ((py - y) / (r / 2)) ** 2 <= 1 and 0 <= px < INNER and 0 <= py < INNER:
                        img.putpixel((px, py), (255, 255, 255, 255))
        return img
    if name == "shooting_star":
        for i in range(30):
            x, y = 8 + i, 40 - i
            fade = int(255 * i / 30)
            canvas.putpixel((x, y), (255, 240, 200, fade))
            if i > 10:
                canvas.putpixel((x, y + 1), (255, 220, 160, fade // 2))
        star(canvas, 36, 6, (255, 250, 230), (240, 200, 120))
        rng = np.random.default_rng(4)
        for _ in range(14):
            x, y = rng.integers(2, INNER - 2, 2)
            canvas.putpixel((int(x), int(y)), (230, 230, 255, 200))
        return canvas
    if name in ("journal_half", "journal_full"):
        img = Image.new("RGBA", (INNER, INNER), (0, 0, 0, 0))
        px = img.load()
        x0, x1, y0, y1, mid = 3, 50, 10, 44, 26
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                edge = x in (x0, x1) or y in (y0, y1) or x in (mid, mid + 1)
                px[x, y] = INK + (255,) if edge else CREAM + (255,)
        for y in range(y1 + 1, y1 + 3):
            for x in range(x0 + 1, x1):
                px[x, y] = (150, 70, 50, 255)
        written = range(14, 42, 4)
        for i, y in enumerate(written):
            for x in range(x0 + 4, mid - 3):
                px[x, y] = (150, 120, 100, 255)
            if name == "journal_full" or i < 3:
                for x in range(mid + 5, x1 - 3):
                    px[x, y] = (150, 120, 100, 255)
        if name == "journal_full":
            for y in range(4, 22):
                for x in range(mid + 14, mid + 18):
                    px[x, y] = (122, 70, 160, 255)
            px[mid + 15, 22] = px[mid + 16, 22] = (0, 0, 0, 0)
        return img
    if name == "deed":
        img = Image.new("RGBA", (INNER, INNER), (0, 0, 0, 0))
        px = img.load()
        for y in range(8, 46):
            for x in range(10, 44):
                edge = x in (10, 43) or y in (8, 45)
                px[x, y] = INK + (255,) if edge else PARCH + (255,)
        for y in range(15, 36, 4):
            for x in range(15, 39 if y < 35 else 28):
                px[x, y] = (150, 120, 100, 255)
        for y in range(36, 46):
            for x in range(32, 42):
                if (x - 37) ** 2 + (y - 41) ** 2 <= 16:
                    px[x, y] = (166, 36, 33, 255)
        return img
    if name == "hearth":
        room = Image.open(ROOT / "game" / "assets" / "backgrounds" / "interior" / "painted.png").convert("RGBA")
        for layer in ("fire", "lamps", "amphorae", "plants", "scrolls", "panel", "water"):
            room.alpha_composite(Image.open(ROOT / "game" / "assets" / "backgrounds" / "interior" / f"{layer}.png").convert("RGBA"),
                                 tuple(json.loads((ROOT / "game" / "assets" / "backgrounds" / "interior" / "furnishings.json").read_text())[layer][:2]))
        return fit(room.crop((24, 14, 112, 92)))
    raise ValueError(name)


def tile(night):
    img = Image.new("RGBA", (SIZE, SIZE), INK + (255,))
    px = img.load()
    for y in range(1, SIZE - 1):
        for x in range(1, SIZE - 1):
            ring = min(x, y, SIZE - 1 - x, SIZE - 1 - y)
            if ring == 1:
                px[x, y] = GOLD_LIGHT + (255,) if x < SIZE - 3 and y < SIZE - 3 and (x == 1 or y == 1) else GOLD + (255,)
            elif ring == 2:
                px[x, y] = GOLD_DARK + (255,) if (x == SIZE - 3 or y == SIZE - 3) else GOLD + (255,)
            elif ring == 3:
                px[x, y] = INK + (255,)
            else:
                t = (y - 4) / (SIZE - 8)
                low, high = (NIGHT, NIGHT_LOW) if night else (CREAM, PARCH)
                px[x, y] = tuple(int(low[i] + (high[i] - low[i]) * t) for i in range(3)) + (255,)
    return img


def icon(achievement_id):
    art = ART[achievement_id]
    pic = drawing(art[5:]) if art.startswith("draw:") else fit(sprite(art), SIZE - 8 if achievement_id in ROOMY else INNER)
    img = tile(achievement_id in NIGHT_TILES)
    img.alpha_composite(pic, ((SIZE - pic.width) // 2, (SIZE - pic.height) // 2))
    return img.convert("RGB")


def locked(img):
    grey = ImageEnhance.Color(img).enhance(0.0)
    return ImageEnhance.Brightness(ImageEnhance.Contrast(grey).enhance(0.8)).enhance(0.55)


def main():
    balance = json.loads((ROOT / "game" / "data" / "balance.json").read_text(encoding="utf-8"))
    ids = [a["id"] for a in balance["achievements"]]
    missing = [i for i in ids if i not in ART]
    if missing:
        raise SystemExit(f"no picture chosen for {missing}; add them to ART")
    OUT.mkdir(parents=True, exist_ok=True)
    cell = SIZE * 2 + 12
    sheet = Image.new("RGB", (4 * cell, ((len(ids) + 3) // 4) * (SIZE + 8)), (40, 30, 26))
    for n, i in enumerate(ids):
        img = icon(i)
        img.save(OUT / f"{i}.jpg", quality=95)
        dim = locked(img)
        dim.save(OUT / f"{i}_locked.jpg", quality=95)
        col, row = n % 4, n // 4
        sheet.paste(img, (col * cell, row * (SIZE + 8)))
        sheet.paste(dim, (col * cell + SIZE + 4, row * (SIZE + 8)))
    sheet.save(OUT / "sheet.png")
    print(f"wrote {len(ids) * 2} icons to {OUT}")


if __name__ == "__main__":
    main()
