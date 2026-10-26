"""Synthesize simple placeholder sound effects until real ones are licensed.

Usage: python tools/audio/make_placeholder_sfx.py game/assets/audio/sfx
       python tools/audio/make_placeholder_sfx.py game/assets/audio/ambience --ambience
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


def snip():
    # A blade closing: a very short, bright click with the low end removed so it sounds crisp, not hissy.
    n = rng.standard_normal(int(RATE * 0.018))
    crisp = n - lowpass(n, 8)
    return crisp * env(len(n), 0.0005, 260) * 0.9


def harvest():
    out = silence(0.4)
    place(out, snip(), 0.0)
    place(out, snip() * 0.8, 0.07)
    place(out, tone(1568, 0.3, decay=11, harmonics=(1, 0.25)) * 0.22, 0.09)
    place(out, tone(2093, 0.25, decay=13) * 0.12, 0.13)
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


def purr():
    # A purr is a low rumble pulsing about 26 times a second, louder breathing out than breathing in.
    out = silence(1.3)
    for at, seconds, level in [(0.0, 0.55, 1.0), (0.62, 0.6, 0.7)]:
        x = t(seconds)
        rumble = lowpass(rng.standard_normal(len(x)), 60)
        pulse = 0.5 + 0.5 * np.sin(2 * np.pi * 26 * x) ** 2
        place(out, rumble * pulse * np.sin(np.pi * x / seconds) * level, at)
    return out


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


def write(path, samples, level=0.8):
    peak = np.max(np.abs(samples)) or 1.0
    data = (samples / peak * level * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for name, fn in [("plant", plant), ("harvest", harvest), ("coins", coins), ("cart", cart), ("unlock", unlock),
                     ("pet", pet), ("hammer", hammer), ("villa_complete", villa_complete), ("click", click), ("nope", nope), ("purr", purr)]:
        write(out / f"{name}.wav", fn())
        print("wrote", name)


if __name__ == "__main__" and len(sys.argv) == 2:
    main()


def ambience_day(seconds=24.0):
    # Occasional bird chirps over silence; broadband noise is left out because it reads as a fan, not a breeze.
    out = silence(seconds)
    for _ in range(14):
        at = rng.uniform(0.5, seconds - 1)
        f0 = rng.uniform(2600, 3800)
        for k in range(rng.integers(2, 5)):
            c = t(0.07)
            sweep = np.sin(2 * np.pi * np.cumsum(f0 + 900 * np.sin(np.pi * c / 0.07)) / RATE) * env(len(c), 0.005, 30) * 0.12
            place(out, sweep, at + k * 0.11)
    return seam(out)


def ambience_night(seconds=24.0):
    # Crickets chirp in short pulses of a high tone over a very soft breeze.
    out = silence(seconds)
    for cricket in range(3):
        f = rng.uniform(4200, 5200)
        period = rng.uniform(0.7, 1.1)
        at = rng.uniform(0, 0.5)
        while at < seconds - 0.3:
            for p in range(3):
                c = t(0.025)
                place(out, np.sin(2 * np.pi * f * c) * env(len(c), 0.002, 80) * 0.05, at + p * 0.04)
            at += period * rng.uniform(0.9, 1.1)
    return seam(out)


def seam(x):
    # Crossfading the end into the start makes the loop point inaudible.
    n = int(RATE * 1.0)
    head, tail = x[:n].copy(), x[-n:]
    fade = np.linspace(0, 1, n)
    x[:n] = head * fade + tail * (1 - fade)
    return x[:-n]


if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[2] == "--ambience":
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    # Ambience sits well under the effects, so it is written at a lower level.
    write(out / "day.wav", ambience_day(), 0.35)
    write(out / "night.wav", ambience_night(), 0.25)
    print("wrote ambience")
