"""Paint the dog and cat as they appear inside the farmhouse: asleep, at the room painting's own detail and in its
style, one picture for each breed. The estate's sprites are too coarse beside the room, so these are drawn afresh
with PixelLab, using a corner of the room painting as the style to match.

Usage: python tools/art/make_room_pets.py [NAME ...]
Writes game/assets/sprites/room_pets/<breed>.png; with names, only those are redone (such as "hound tabby").
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "assets" / "sprites" / "room_pets"
ROOM = ROOT / "tools" / "art" / "sources" / "interior" / "steps" / "room.png"
LIE = "lying down asleep on its belly with its head resting on its front paws, eyes closed, side view facing right"
CURL = "curled up asleep in a ball with its tail wrapped round, eyes closed, side view facing right"
DOGS = {
    "hound": "a short-haired golden tan farm hound with floppy ears, a white muzzle, white chest and white paws and a red collar",
    "molossian": "a big heavy dark brown mastiff with a broad wrinkled head, short coat and dark muzzle",
    "sighthound": "a slender fawn greyhound-like sighthound with a narrow head, white muzzle and a red collar",
    "lapdog": "a small fluffy cream-white lapdog with soft curly fur",
    "sheepdog": "a shaggy grey and white sheepdog with long thick fur and a white face",
}
CATS = {
    "tabby": "an orange ginger tabby cat with darker stripes",
    "longhair": "a fluffy long-haired grey and white cat",
    "spotted": "a grey cat with dark spots and stripes",
    "stocky": "a stocky black cat with a white chest and white paws",
}


def make(name, description, size, style_box):
    style = ROOT / "tools" / "art" / "sources" / "interior" / f"pet_style_{size}.png"
    w, h = map(int, size.split("x"))
    Image.open(ROOM).crop((style_box[0], style_box[1], style_box[0] + w, style_box[1] + h)).save(style)
    subprocess.run([sys.executable, str(ROOT / "tools" / "art" / "pixellab.py"), "proflash",
                    f"{description}, {LIE if name in DOGS else CURL}, cozy detailed pixel art", size,
                    "--out", str((OUT / f"{name}.png").relative_to(ROOT)), "--transparent",
                    "--style", str(style.relative_to(ROOT)), "--style-use", "match this art style, pixel size, palette and warm lamplight"],
                   check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[1:])
    for name, words in DOGS.items():
        if not only or name in only:
            make(name, words, "96x64", (40, 180))
    for name, words in CATS.items():
        if not only or name in only:
            make(name, words, "64x48", (248, 80))


if __name__ == "__main__":
    main()
