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
    # A soft purr: short bursts of breathy mid-range noise about 24 times a second, with the deep rumble filtered out
    # so it sounds like a small cat rather than an engine.
    out = silence(1.0)
    for at, seconds, level in [(0.0, 0.42, 1.0), (0.48, 0.45, 0.75)]:
        x = t(seconds)
        n = rng.standard_normal(len(x))
        breath = lowpass(n, 6) - lowpass(n, 40)
        pulse = np.abs(np.sin(np.pi * 24 * x)) ** 4
        place(out, breath * (0.15 + pulse) * np.sin(np.pi * x / seconds) * level, at)
    return out


def tab():
    # Turning to a tab or bookmark: a quick paper flick, two soft brushes of bright noise.
    out = silence(0.12)
    for at, level in [(0.0, 1.0), (0.035, 0.55)]:
        n = rng.standard_normal(int(RATE * 0.05))
        brush = lowpass(n, 3) - lowpass(n, 18)
        place(out, brush * env(len(n), 0.004, 55) * level, at)
    return out


def glide(f0, f1, seconds, harmonics=(1.0, 0.5, 0.3, 0.2)):
    x = t(seconds)
    f = f0 + (f1 - f0) * (x / seconds)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    return sum(h * np.sin(phase * (i + 1)) for i, h in enumerate(harmonics))


def cluck():
    # A hen: three quick, nasal "buk"s and a rising "bawk".
    out = silence(0.75)
    for i, at in enumerate([0.0, 0.11, 0.2]):
        b = glide(620 - i * 30, 480, 0.06, (1, 0.8, 0.5, 0.4, 0.3)) * env(int(RATE * 0.06), 0.004, 45)
        place(out, b * 0.6, at)
    a = glide(560, 880, 0.24, (1, 0.7, 0.5, 0.35, 0.25)) * env(int(RATE * 0.24), 0.01, 9)
    place(out, a * 0.7, 0.34)
    return lowpass(out, 3)


def bleat():
    # A goat: a quavering "meh-eh-eh", the voice wobbling quickly in loudness and a little in pitch.
    x = t(0.8)
    f = 360 + 18 * np.sin(2 * np.pi * 6.5 * x)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    voice = sum(h * np.sin(phase * (i + 1)) for i, h in enumerate((1, 0.9, 0.7, 0.5, 0.35, 0.2)))
    tremolo = 0.45 + 0.55 * np.abs(np.sin(2 * np.pi * 7.0 * x))
    shape = np.clip(x / 0.05, 0, 1) * np.exp(-x * 2.2)
    return lowpass(voice * tremolo * shape, 4) * 0.6


def stork():
    # A stork on its nest clattering its bill: a run of hollow wooden clicks that speeds up and then slows.
    out = silence(1.1)
    at = 0.0
    gap = 0.085
    while at < 1.0:
        n = rng.standard_normal(int(RATE * 0.012))
        click = (lowpass(n, 2) - lowpass(n, 12)) * env(len(n), 0.0005, 300)
        place(out, click + tone(1100, 0.012, decay=280) * 0.4, at)
        at += gap
        gap = max(0.05, gap * 0.94) if at < 0.6 else gap * 1.08
    return out


def donkey():
    # A donkey's bray: a squealing "hee" breathing in and a rough low "haw" breathing out, twice over.
    out = silence(1.6)
    for k in range(2):
        hee = glide(820, 980, 0.22, (1, 0.6, 0.4)) + 0.3 * lowpass(rng.standard_normal(int(RATE * 0.22)), 6)
        place(out, hee * env(int(RATE * 0.22), 0.02, 4) * 0.5, k * 0.7)
        x = t(0.4)
        haw = glide(300, 230, 0.4, (1, 0.9, 0.8, 0.6, 0.5, 0.4)) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 40 * x)))
        place(out, lowpass(haw, 5) * env(len(x), 0.02, 3) * 0.55, k * 0.7 + 0.24)
    return out


def mrrp():
    # A cat answering a stroke: a short rolled "mrrp" that rises and falls.
    x = t(0.32)
    f = 520 + 160 * np.sin(np.pi * x / 0.32)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    voice = np.sin(phase) + 0.45 * np.sin(2 * phase) + 0.2 * np.sin(3 * phase)
    trill = 0.55 + 0.45 * np.sin(2 * np.pi * 28 * x)
    return lowpass(voice * trill * np.sin(np.pi * x / 0.32), 4) * 0.5


def _hoof(sharp):
    n = rng.standard_normal(int(RATE * 0.04))
    body = lowpass(n, 3 if sharp else 14) - (lowpass(n, 30) if sharp else 0)
    return body * env(len(n), 0.001, 90 if sharp else 60) + tone(260 if sharp else 140, 0.04, decay=70) * 0.5


def cart_ride(stone):
    # Setting off down the road: the donkey's hooves, the wheels crunching over gravel or knocking over paving joints,
    # and now and then the cart's wood creaking.
    seconds = 2.4
    out = silence(seconds)
    at = 0.05
    k = 0
    while at < seconds - 0.1:
        place(out, _hoof(stone) * (0.55 if k % 2 else 0.45), at)
        at += 0.19 if k % 2 == 0 else 0.23
        k += 1
    if stone:
        at = 0.1
        while at < seconds - 0.05:
            place(out, _hoof(True) * 0.25, at)
            at += rng.uniform(0.09, 0.16)
        rumble = lowpass(rng.standard_normal(int(RATE * seconds)), 40) * 0.4
    else:
        crunch = rng.standard_normal(int(RATE * seconds))
        crunch = (lowpass(crunch, 2) - lowpass(crunch, 8)) * (rng.random(len(crunch)) < 0.25)
        rumble = lowpass(crunch, 2) * 0.5 + lowpass(rng.standard_normal(int(RATE * seconds)), 60) * 0.3
    place(out, rumble, 0)
    for at in rng.uniform(0.3, seconds - 0.4, 2):
        creak = glide(rng.uniform(280, 420), rng.uniform(380, 520), 0.18, (1, 0.6, 0.4, 0.3)) * (0.6 + 0.4 * rng.random(int(RATE * 0.18)))
        place(out, creak * env(int(RATE * 0.18), 0.03, 8) * 0.12, at)
    fade = np.ones(len(out))
    fade[: int(RATE * 0.25)] = np.linspace(0, 1, int(RATE * 0.25))
    return out * fade


def hammer():
    out = knock() * 1.2
    return np.concatenate([out, silence(0.05)])


def thump():
    """A rabbit's alarm: a hind foot stamped once on the earth, a dull low thud with a little soil in it."""
    x = t(0.35)
    body = np.sin(2 * np.pi * (70 + 60 * np.exp(-x * 40)) * x) * np.exp(-x * 22)
    grit = lowpass(rng.normal(0, 1, len(x)), 6) * np.exp(-x * 60) * 0.25
    return lowpass(body + grit, 4)


def triumph():
    """A short brass fanfare: two rising calls and a held chord, for the Triumph achievement."""
    out = silence(3.2)
    brass = (1.0, 0.7, 0.55, 0.4, 0.28, 0.18, 0.1)
    notes = [(392, 0.0, 0.18), (392, 0.2, 0.18), (523, 0.4, 0.5), (523, 1.0, 0.18), (659, 1.2, 0.18), (784, 1.4, 1.6)]
    for f, at, length in notes:
        x = t(length + 0.3)
        wobble = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * x)
        s = sum(h * np.sin(2 * np.pi * f * (i + 1) * x * wobble) for i, h in enumerate(brass))
        shape = np.clip(x / 0.03, 0, 1) * np.where(x < length, 1.0, np.exp(-(x - length) * 12))
        place(out, s * shape * 0.25, at)
    for f in (523, 659):
        x = t(1.8)
        s = sum(h * np.sin(2 * np.pi * f * (i + 1) * x) for i, h in enumerate(brass[:4]))
        place(out, s * np.clip(x / 0.05, 0, 1) * np.exp(-x * 1.4) * 0.14, 1.4)
    return lowpass(out, 3)


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
                     ("pet", pet), ("hammer", hammer), ("click", click), ("nope", nope), ("purr", purr), ("tab", tab)]:
        write(out / f"{name}.wav", fn())
        print("wrote", name)


if __name__ == "__main__" and len(sys.argv) == 2:
    main()

# Named sounds only, so placeholders can be added without overwriting real recordings already in the folder.
if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[2] != "--ambience":
    for name in sys.argv[2:]:
        write(Path(sys.argv[1]) / f"{name}.wav", globals()[name]())
        print("wrote", name)


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
