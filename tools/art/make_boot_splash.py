"""Make the picture Godot shows while the game starts: the trailer's pixel logo, laurel and all, enlarged three times
with whole pixels so it stays crisp. Godot draws it at its own size in the middle of the window, on the background
colour set in project.godot, and the game's first frame shows the same picture before fading into the title.

Usage: python tools/art/make_boot_splash.py (after tools/trailer/make_logo.py)
Writes game/assets/splash/boot_splash.png.
"""
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[2] / "game"
SCALE = 3


def main():
    logo = Image.open(GAME / "tools" / "trailer" / "logo.png").convert("RGBA")
    out = GAME / "assets" / "splash" / "boot_splash.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    logo.resize((logo.width * SCALE, logo.height * SCALE), Image.NEAREST).save(out)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
