"""Make the Steam trailer: record each scripted shot in movie mode, then cut them together with the caption cards,
the end card and the music, all in Godot, into recordings/trailer/trailer.avi.

Usage:
  python tools/trailer/make_trailer.py              records any shot not yet recorded, then renders the trailer
  python tools/trailer/make_trailer.py shots hook   records just those shots again
  python tools/trailer/make_trailer.py render       renders the trailer from the shots already recorded

The shots are scripted in game/tools/trailer/shots.gd and the edit, with its cards and music, in
game/tools/trailer/edit.gd. Every shot plays a demo farm, so the real save is never touched.
"""
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from record_clip import GODOT, OVERRIDE  # noqa: E402

FPS = 30
OUT = ROOT / "recordings" / "trailer"
HUD_OFF = ["--no-hud"]
# name: (seconds to record, game flags). The edit takes its part of each from edit.gd; a shot starts a moment early
# so pets and helpers have walked into place before the part that is used.
SHOTS = {
    "hook": (10, ["--maxed", "--zone=home", "--hour=18.2", *HUD_OFF]),
    "ruin": (7, ["--villa=1", "--zone=home", "--hour=8.5", *HUD_OFF]),
    "plant": (7, ["--villa=2", "--zone=home", "--hour=9.5", "--coins=240"]),
    "cart": (6, ["--villa=3", "--zone=home", "--hour=10", "--coins=1840"]),
    "coins": (19, ["--villa=3", "--zone=home", "--hour=10", "--coins=1840"]),
    "helper": (6, ["--maxed", "--zone=home", "--hour=9", *HUD_OFF]),
    "bakery": (6, ["--estate", "--zone=yard", "--hour=19.3", *HUD_OFF]),
    "villa": (7, ["--villa=3", "--zone=home", "--hour=11", *HUD_OFF]),
    "pasture": (6, ["--maxed", "--zone=pasture", "--hour=10", *HUD_OFF]),
    "vineyard": (6, ["--maxed", "--zone=vineyard", "--hour=16.5", *HUD_OFF]),
    "grove": (6, ["--maxed", "--zone=grove", "--hour=14", "--weather=rain", *HUD_OFF]),
    "pet": (6, ["--maxed", "--zone=home", "--hour=11", *HUD_OFF]),
    "hoopoe": (7, ["--maxed", "--zone=home", "--hour=10", *HUD_OFF]),
    "inside": (6, ["--maxed", "--furnish=all", "--inside=pet", "--hour=21"]),
    "town": (6, ["--maxed", "--town", "--hour=11", *HUD_OFF]),
    "timelapse": (8, ["--maxed", "--zone=home", "--hour=1.2", *HUD_OFF]),
    "night": (9, ["--maxed", "--zone=home", "--hour=22", "--galaxy", *HUD_OFF]),
    "endcard": (9, ["--maxed", "--zone=vineyard", "--hour=19.6", *HUD_OFF]),
}


def godot(args):
    """Runs Godot at 1920x1080, which movie mode takes from the project's window setting when the game starts."""
    override = ROOT / "game" / "override.cfg"
    if override.exists():
        sys.exit(f"{override} already exists; move it aside first")
    override.write_text(OVERRIDE)
    try:
        subprocess.run([str(GODOT), "--path", str(ROOT / "game"), *args], check=True)
    finally:
        override.unlink()


def record(name):
    seconds, flags = SHOTS[name]
    folder = OUT / "shots" / name
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    # A .png movie is written as numbered frames with the sound beside them in a .wav of the same name.
    godot(["--write-movie", str(folder / "f.png"), "--fixed-fps", str(FPS), "--quit-after", str(seconds * FPS),
           "--", "--demo", "--no-music", "--window=1920x1080", f"--trailer-shot={name}", *flags, "--quiet-start"])


def render():
    godot(["--write-movie", str(OUT / "trailer.avi"), "--fixed-fps", str(FPS), "res://tools/trailer/edit.tscn",
           "--", "--readonly", "--window=1920x1080", f"--shots={OUT / 'shots'}"])
    print(f"trailer ready: {OUT / 'trailer.avi'}")


def main():
    args = sys.argv[1:]
    if args[:1] == ["shots"]:
        for name in args[1:] or SHOTS:
            record(name)
        return
    if args[:1] != ["render"]:
        for name in SHOTS:
            if not (OUT / "shots" / name / "f.wav").exists():
                record(name)
    render()


if __name__ == "__main__":
    main()
