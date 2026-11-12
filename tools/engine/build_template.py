"""Build the trimmed Windows export template described in farmus_profile.py.

The stock Godot template carries the whole engine, about 105 MB, mostly 3D, physics and the Vulkan and Direct3D 12
drivers this 2D game never uses. This builds one without them from the Godot source of the exact version the editor
is, and the Windows export presets point at the result.

Needs: the Godot source checked out at the editor's version (by default in C:/Users/<you>/godot-src, made with
`git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot.git godot-src`), SCons
(`pip install scons`) and Visual Studio with its C++ tools. A build takes a long while, mostly the final linking.
Rebuild whenever Godot is updated, with the source checked out at the new version.

Usage: python tools/engine/build_template.py [path to the godot source]
Writes tools/engine/bin/farmus.windows.template_release.x86_64.exe, kept in Git LFS; commit it after a rebuild.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home() / "godot-src"
OUT = HERE / "bin" / "farmus.windows.template_release.x86_64.exe"


def main():
    if not (SOURCE / "SConstruct").exists():
        sys.exit(f"No Godot source at {SOURCE}; see the notes at the top of this script")
    # The Windows checks for the Vulkan and Direct3D 12 drivers only read the command line, so those are repeated there.
    subprocess.run([sys.executable, "-m", "SCons", "platform=windows", f"profile={HERE / 'farmus_profile.py'}",
                    "vulkan=no", "d3d12=no", f"-j{max(1, (os.cpu_count() or 2) - 1)}"], cwd=SOURCE, check=True)
    built = SOURCE / "bin" / "godot.windows.template_release.x86_64.exe"
    OUT.parent.mkdir(exist_ok=True)
    shutil.copy2(built, OUT)
    print(f"template ready: {OUT} ({OUT.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
