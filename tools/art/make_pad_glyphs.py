"""Draw the small gamepad button pictures shown beside key hints while a gamepad is in use, in Xbox's layout and
colours: B, X and Y as round buttons, the shoulder buttons and the right stick, the buttons the game names. Each is
drawn pixel by pixel with the interface's dark outline and a lit top edge, at one pixel per interface pixel.

Usage: python tools/art/make_pad_glyphs.py
Writes game/assets/sprites/pad/<name>.png.
"""
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites" / "pad"
OUTLINE = (58, 34, 26)
INK = (252, 242, 219)
FACE = {"b": (190, 64, 52), "x": (60, 110, 178), "y": (222, 170, 48)}
GREY = (110, 98, 90)
# A 3 by 5 pixel alphabet for the letters on the buttons.
LETTERS = {
    "B": ["110", "101", "110", "101", "110"],
    "X": ["101", "101", "010", "101", "101"], "Y": ["101", "101", "010", "010", "010"],
    "L": ["100", "100", "100", "100", "111"], "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "010", "001", "110"],
}


def shade(colour, amount):
    return tuple(max(0, min(255, int(c * amount))) for c in colour)


def blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def body(img, inside, colour):
    """Fills the shape inside(x, y) with colour, lit along its top, darker along its bottom, and outlined."""
    w, h = img.size
    filled = {(x, y) for y in range(h) for x in range(w) if inside(x, y)}
    for x, y in filled:
        edge = any((x + dx, y + dy) not in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            img.putpixel((x, y), OUTLINE + (255,))
        elif (x, y - 1) not in filled or (x, y - 2) not in filled:
            img.putpixel((x, y), shade(colour, 1.22) + (255,))
        elif (x, y + 2) not in filled:
            img.putpixel((x, y), shade(colour, 0.78) + (255,))
        else:
            img.putpixel((x, y), colour + (255,))


def write(img, text, left, top):
    for k, ch in enumerate(text):
        for row, bits in enumerate(LETTERS[ch]):
            for col, bit in enumerate(bits):
                if bit == "1":
                    img.putpixel((left + k * 4 + col, top + row), INK + (255,))


def round_button(letter, colour):
    img = blank(11, 11)
    body(img, lambda x, y: (x - 5) ** 2 + (y - 5) ** 2 <= 30, colour)
    write(img, letter, 4, 3)
    return img


def shoulder(letter):
    img = blank(15, 9)
    body(img, lambda x, y: 0 <= x < 15 and 0 <= y < 9 and not ((x in (0, 14)) and y in (0, 8)), GREY)
    write(img, letter + "B", 4, 2)
    return img


def stick(letter):
    img = blank(13, 13)
    body(img, lambda x, y: (x - 6) ** 2 + (y - 6) ** 2 <= 38, GREY)
    write(img, letter + "S", 3, 4)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pictures = {name: round_button(name.upper(), colour) for name, colour in FACE.items()}
    pictures.update({"lb": shoulder("L"), "rb": shoulder("R"), "rs": stick("R")})
    for name, img in pictures.items():
        img.save(OUT / f"{name}.png")
    print(f"wrote {len(pictures)} pictures to {OUT}")


if __name__ == "__main__":
    main()
