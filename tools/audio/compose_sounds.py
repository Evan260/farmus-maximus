"""Make game sounds out of others already cut from recordings.

built: building work finished; the last three hammer blows, a beat's pause, then a mallet set down hard on the
timber, so it sounds like the builders knocking in the final peg and downing tools.

flourish: a deed bought or an achievement earned; one harp chord taken from the soundtrack itself (the opening of
The Unknown Awaits You), so the moment sounds like part of the music.

advice: Uncle Marcus has something new to say; a single soft harp note from Solitary Expedition, a quieter cousin of
the flourish, so his advice is noticed without sounding like a reward.

Usage: python tools/audio/compose_sounds.py
Reads and writes game/assets/audio/sfx/.
"""
from pathlib import Path

import numpy as np
import soundfile as sf

SFX = Path(__file__).resolve().parents[2] / "game" / "assets" / "audio" / "sfx"
MUSIC = SFX.parent / "music"


def read(name):
    data, rate = sf.read(SFX / f"{name}.ogg")
    return (data.mean(axis=1) if data.ndim > 1 else data), rate


def save(name, out, rate):
    with sf.SoundFile(SFX / f"{name}.ogg", "w", rate, 1, format="OGG", subtype="VORBIS") as f:
        for k in range(0, len(out), rate // 4):
            f.write(out[k:k + rate // 4])
    print("wrote", name, round(len(out) / rate, 2), "s")


def flourish():
    data, rate = sf.read(MUSIC / "the_unknown_awaits_you.ogg")
    data = data.mean(axis=1) if data.ndim > 1 else data
    out = data[int(1.82 * rate):int(3.2 * rate)].copy()
    out[: int(0.01 * rate)] *= np.linspace(0, 1, int(0.01 * rate))
    fade = int(0.6 * rate)
    out[-fade:] *= np.linspace(1, 0, fade) ** 2
    out *= 0.7 / (np.abs(out).max() or 1.0)
    save("flourish", out, rate)


def advice():
    data, rate = sf.read(MUSIC / "solitary_expedition.ogg")
    data = data.mean(axis=1) if data.ndim > 1 else data
    out = data[int(11.99 * rate):int(12.85 * rate)].copy()
    out[: int(0.005 * rate)] *= np.linspace(0, 1, int(0.005 * rate))
    fade = int(0.45 * rate)
    out[-fade:] *= np.linspace(1, 0, fade) ** 2
    out *= 0.6 / (np.abs(out).max() or 1.0)
    save("advice", out, rate)


def main():
    flourish()
    advice()
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
    save("built", out, rate)


if __name__ == "__main__":
    main()
