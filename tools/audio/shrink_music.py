"""Re-encode the game's music at a sensible size.

Music packs often ship at very high bitrates (the harp tracks came at about 345 kbps). Calm acoustic music sounds the
same at Vorbis quality 2 (nominally 96 kbps, about 80 kbps on these sparse tracks), at about a quarter of the size, which
matters because the music is most of the game's download. Encode from the pack's original files, never from an already
shrunk track. Only tracks above the threshold are touched, so running it again does nothing to tracks already shrunk.

Usage: python tools/audio/shrink_music.py
Then reimport the project in Godot so the game uses the new files.
"""
import os
from pathlib import Path

import soundfile as sf

MUSIC = Path(__file__).resolve().parents[2] / "game" / "assets" / "audio" / "music"
# libsndfile's Vorbis setting is one minus the quality, so 0.8 is quality 2, nominally 96 kbps for stereo music.
COMPRESSION = 0.8
SHRINK_ABOVE_KBPS = 110


def main():
    for path in sorted(MUSIC.glob("*.ogg")):
        info = sf.info(path)
        kbps = os.path.getsize(path) * 8 / info.duration / 1000
        if kbps <= SHRINK_ABOVE_KBPS:
            print(f"{path.name}: {kbps:.0f} kbps, left as it is")
            continue
        data, rate = sf.read(path)
        tmp = path.with_suffix(".tmp.ogg")
        # The Vorbis encoder overflows its stack when handed a long recording in one go, so it is fed in short blocks.
        with sf.SoundFile(tmp, "w", rate, info.channels, format="OGG", subtype="VORBIS", compression_level=COMPRESSION) as f:
            for k in range(0, len(data), rate // 4):
                f.write(data[k:k + rate // 4])
        before = os.path.getsize(path)
        os.replace(tmp, path)
        print(f"{path.name}: {before / 1e6:.1f} MB -> {os.path.getsize(path) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
