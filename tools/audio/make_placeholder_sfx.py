"""Synthesize simple placeholder sound effects until real ones are licensed.

Usage: python tools/audio/make_placeholder_sfx.py game/assets/audio/sfx
"""
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 44100
rng = np.random.default_rng(1)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def env(n, attack=0.005, decay=6.0):
    x = np.arange(n) / RATE
    a = np.clip(x / attack, 0, 1)
    return a * np.exp(-x * decay)


def lowpass(x, k):
    return np.convolve(x, np.ones(k) / k, mode="same")


def tone(freq, seconds, decay=6.0, harmonics=(1.0,)):
    x = t(seconds)
    s = sum(h * np.sin(2 * np.pi * freq * (i + 1) * x) for i, h in enumerate(harmonics))
    return s * env(len(x), decay=decay)


def place(base, sound, at):
    i = int(at * RATE)
    end = min(len(base), i + len(sound))
    base[i:end] += sound[: end - i]


def silence(seconds):
    return np.zeros(int(RATE * seconds))


def plant():
    n = lowpass(rng.standard_normal(int(RATE * 0.18)), 40) * env(int(RATE * 0.18), decay=22)
    return n * 1.4 + tone(95, 0.18, decay=18) * 0.6


def harvest():
    x = t(0.3)
    sweep = lowpass(rng.standard_normal(len(x)), 6) * np.sin(np.pi * x / 0.3) ** 2 * 0.5
    out = sweep
    place(out, tone(1175, 0.25, decay=14, harmonics=(1, 0.3)) * 0.35, 0.08)
    return out


def coins():
    out = silence(0.45)
    for i, f in enumerate([2093, 2637, 2349]):
        place(out, tone(f, 0.25, decay=16, harmonics=(1, 0.5, 0.25)) * 0.3, i * 0.07)
    return out


def cart():
    x = t(0.8)
    rumble = lowpass(rng.standard_normal(len(x)), 120) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * x))
    return rumble * np.sin(np.pi * x / 0.8) * 2.5


def knock():
    return lowpass(rng.standard_normal(int(RATE * 0.06)), 10) * env(int(RATE * 0.06), decay=60) + tone(220, 0.06, decay=50) * 0.5


def unlock():
    out = silence(0.25)
    place(out, knock(), 0)
    place(out, knock(), 0.11)
    return out


def pet():
    x = t(0.18)
    f = 420 + 380 * (x / 0.18)
    return np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(len(x), attack=0.01, decay=10) * 0.5


def hammer():
    out = knock() * 1.2
    return np.concatenate([out, silence(0.05)])


def villa_complete():
    out = silence(1.6)
    for i, f in enumerate([523, 659, 784, 1047]):
        place(out, tone(f, 1.0, decay=3.5, harmonics=(1, 0.4, 0.15)) * 0.3, i * 0.12)
    return out


def click():
    return tone(1800, 0.03, decay=120) * 0.25


def nope():
    out = silence(0.3)
    place(out, tone(330, 0.12, decay=20) * 0.3, 0)
    place(out, tone(262, 0.15, decay=18) * 0.3, 0.1)
    return out


def write(path, samples):
    peak = np.max(np.abs(samples)) or 1.0
    data = (samples / peak * 0.8 * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for name, fn in [("plant", plant), ("harvest", harvest), ("coins", coins), ("cart", cart), ("unlock", unlock),
                     ("pet", pet), ("hammer", hammer), ("villa_complete", villa_complete), ("click", click), ("nope", nope)]:
        write(out / f"{name}.wav", fn())
        print("wrote", name)


if __name__ == "__main__":
    main()
