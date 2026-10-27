"""Make game sounds out of others already cut from recordings.

built: building work finished; the last three hammer blows, a beat's pause, then a mallet set down hard on the
timber, so it sounds like the builders knocking in the final peg and downing tools.

Usage: python tools/audio/compose_sounds.py
Reads and writes game/assets/audio/sfx/.
"""
from pathlib import Path

import numpy as np
import soundfile as sf

SFX = Path(__file__).resolve().parents[2] / "game" / "assets" / "audio" / "sfx"


def read(name):
    data, rate = sf.read(SFX / f"{name}.ogg")
    return (data.mean(axis=1) if data.ndim > 1 else data), rate


def main():
    hammer, rate = read("hammer")
    thud, thud_rate = read("made")
    if thud_rate != rate:
        # Resampled by stretching, which is close enough for a short knock.
        idx = np.linspace(0, len(thud) - 1, int(len(thud) * rate / thud_rate))
        thud = np.interp(idx, np.arange(len(thud)), thud)
    gap = np.zeros(int(0.16 * rate))
    out = np.concatenate([hammer * 0.75, gap, thud * 1.1])
    tail = int(0.08 * rate)
    out[-tail:] *= np.linspace(1, 0, tail)
    out *= 0.75 / (np.abs(out).max() or 1.0)
    with sf.SoundFile(SFX / "built.ogg", "w", rate, 1, format="OGG", subtype="VORBIS") as f:
        for k in range(0, len(out), rate // 4):
            f.write(out[k:k + rate // 4])
    print("wrote built", round(len(out) / rate, 2), "s")


if __name__ == "__main__":
    main()
