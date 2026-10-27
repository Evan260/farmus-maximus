"""Cut single animal calls out of longer field recordings, level them and save them as game sounds.

Usage: python tools/audio/cut_recordings.py RECORDINGS_DIR game/assets/audio/sfx [NAME ...]
With names, only those sounds are cut, such as "cork made", so a new batch needs only its own recordings.
The recordings are Freesound previews named by sound id, or files kept under their own name such as Kenney's
"click_002.ogg" (see design/Sound-list.md for each source and licence).
Several cuts of one sound are saved as name_1, name_2 and so on; the game picks one at random each time.
"""
import sys
from pathlib import Path

import numpy as np
import soundfile as sf

# name: (recording, start seconds, end seconds or None for the whole file), and optionally how long its ending fades away
CUTS = [
    ("cluck_1", "456803_9159316", 1.25, 2.45),
    ("cluck_2", "456803_9159316", 4.55, 5.6),
    ("cluck_3", "456803_9159316", 6.1, 7.2),
    ("goat_1", "722658_3200333", 0.6, 2.2),
    ("goat_2", "722658_3200333", 3.3, 4.4),
    ("goat_3", "722658_3200333", 17.6, 19.4),
    ("donkey_1", "170483_1661766", 27.2, 29.8),
    ("stork_1", "525217_8043", 4.6, 7.0),
    ("cat_1", "260881", 5.0, 7.2),
    ("cat_2", "260881", 20.0, 22.2),
    ("cat_3", "451250", 0.25, 0.9),
    ("rooster_1", "346961_2367065", 32.9, 34.9),
    ("rooster_2", "346961_2367065", 21.5, 23.6),
    ("dog_1", "277058", 0.0, 0.39),
    ("rustle_1", "481075", 6.0, 7.0),
    ("rustle_2", "481075", 12.7, 13.7),
    ("rustle_3", "481075", 21.9, 22.9),
    ("made", "386228_1655965", 0.0, 0.45),
    ("oven", "209460_27766", 0.4, 2.3),
    ("cork", "206152_2568776", 0.04, 0.24, 0.05),
    ("rain_start", "486557_5953161", 0.0, 4.9, 0.5),
    ("market_bell", "378799_7025952", 0.08, 3.05, 0.4),
    ("page_turn", "484968_6150892", 0.06, 0.48, 0.08),
    ("shrine_bell", "452379_1844073", 0.0, 1.0, 0.3),
    ("triumph", "413201_2559515", 0.58, 4.3, 0.4),
    ("click_1", "click_002.ogg", 0.0, None),
    ("click_2", "click_003.ogg", 0.0, None),
    ("click_3", "click_005.ogg", 0.0, None),
    ("tab_1", "bookFlip3.ogg", 0.0, None),
    ("tab_2", "bookFlip2.ogg", 0.0, None),
    ("nope", "bong_001.ogg", 0.0, None),
    ("coins_1", "handleCoins.ogg", 0.0, None),
    ("coins_2", "handleCoins2.ogg", 0.0, None),
    ("plant", "696531_7678208", 13.0, 13.7),
    ("harvest", "699491_5872390", 0.0, 0.9),
    ("unlock", "353907_5984825", 4.75, 5.7),
    ("cart", "518790_8913961", 8.55, 10.6, 0.4),
    ("cart_dirt", "137843_977564", 9.0, 11.8, 0.6),
    ("cart_stone", "549882_8234803", 51.0, 53.8, 0.6),
    ("hammer", "707864_14714586", 0.55, 1.85),
    ("thump_1", "386007_4521595", 0.6, 0.85),
    ("thump_2", "386007_4521595", 3.84, 4.1),
    ("water_fill", "802711_13973196", 7.5, 9.8, 0.3),
    ("fire_light", "149831_25009", 0.0, 2.45, 0.5),
    ("clay", "770042_13973196", 1.75, 2.65, 0.1),
    ("day", "578431_13048145", 9.0, 69.0),
    ("night", "203598_548893", 57.5, 115.5),
    ("rain", "688896_2454586", 26.0, 86.0),
]


# Ambience loops: their last LOOP_BLEND seconds are blended into their start, so the loop never jumps when it repeats.
LOOPS = {"day", "night", "rain"}
LOOP_BLEND = 2.0


def save_ogg(path, clip, rate):
    # The Vorbis encoder overflows its stack when handed a long recording in one go, so it is fed in short blocks.
    with sf.SoundFile(path, "w", rate, 1, format="OGG", subtype="VORBIS") as f:
        for k in range(0, len(clip), rate // 4):
            f.write(clip[k:k + rate // 4])


def blend_loop(clip, rate):
    x = min(int(LOOP_BLEND * rate), len(clip) // 4)
    body, tail = clip[:-x].copy(), clip[-x:]
    ramp = np.linspace(0, 1, x)
    body[:x] = body[:x] * ramp + tail * (1 - ramp)
    return body


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    only = set(sys.argv[3:])
    for name, rec, a, b, *fade in CUTS:
        if only and name not in only:
            continue
        data, rate = sf.read(src / (rec if "." in rec else f"{rec}.mp3"))
        if data.ndim > 1:
            data = data.mean(axis=1)
        clip = data[int(a * rate):int(b * rate) if b is not None else len(data)].copy()
        clip -= clip.mean()
        if name in LOOPS:
            clip = blend_loop(clip, rate)
            clip *= 0.7 / (np.abs(clip).max() or 1.0)
            # Loops play as ambience, which has a folder of its own beside the effects.
            save_ogg(out.parent / "ambience" / f"{name}.ogg", clip, rate)
            print("wrote loop", name, round(len(clip) / rate, 2), "s")
            continue
        # A purr swells in and dies away; everything else starts on its first sound.
        soft = name.startswith("cat") and b - a > 1.0
        fade_in, fade_out = int((0.2 if soft else 0.01) * rate), int((fade[0] if fade else 0.5 if soft else 0.12) * rate)
        # A click lasting a hundredth of a second keeps most of itself rather than fading away entirely.
        fade_in, fade_out = min(fade_in, len(clip) // 6), min(fade_out, len(clip) // 3)
        clip[:fade_in] *= np.linspace(0, 1, fade_in)
        clip[-fade_out:] *= np.linspace(1, 0, fade_out)
        clip *= 0.7 / (np.abs(clip).max() or 1.0)
        save_ogg(out / f"{name}.ogg", clip, rate)
        print("wrote", name, round(len(clip) / rate, 2), "s")


if __name__ == "__main__":
    main()
