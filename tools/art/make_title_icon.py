"""Draw the 16-pixel house on the top button that goes back to the title, in the palette of the other top buttons.

Usage: python tools/art/make_title_icon.py
"""
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "game" / "assets" / "sprites" / "icons" / "ui" / "title.png"
COLOURS = {
    "o": (112, 57, 33), "R": (212, 98, 35), "r": (165, 73, 31), "L": (231, 174, 104), "W": (251, 225, 155),
    "w": (243, 193, 120), "s": (201, 143, 85), "d": (126, 61, 32), "D": (160, 103, 60), "g": (176, 156, 77),
}
ROWS = [
    "................",
    ".......oo.......",
    "......oRRo......",
    ".....oRrRRo.....",
    "....oRRRRrRo....",
    "...orRRrRRRro...",
    "..orrrrrrrrrro..",
    ".oooooooooooooo.",
    "..oWWWWWWWWWwo..",
    "..oWWWWddWWwwo..",
    "..oLWWdDDdWWwo..",
    "..oWWWdDDdWLwo..",
    "..oLWWdDDdWWso..",
    "..oLLWdDDdwsso..",
    ".goooooooooooog.",
    "................",
]


def main():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y, row in enumerate(ROWS):
        for x, c in enumerate(row):
            if c in COLOURS:
                img.putpixel((x, y), COLOURS[c] + (255,))
    img.save(OUT)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
