"""Make the logo the title screen draws: the trailer's pixel logo, laurel and all, enlarged three times with whole
pixels so it stays crisp. The title cuts it from this picture and draws it on whole screen pixels. The picture Godot
shows while the game starts is the separate loading screen, game/assets/splash/loading_screen.png.

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
