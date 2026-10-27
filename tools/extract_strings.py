"""Collect every player-facing string into game/translations/strings.csv for translators.

The interface wraps most of its text in tr("..."). Other text sits in the scripts' own tables, such as the weather
names or the market's buildings, and Godot translates it where a label or button shows it, so every string literal
that reads like words is collected too; a row nobody sees costs nothing. Names and descriptions come from
game/data/balance.json. Existing translations are kept, new strings are added with the English filled in, and rows
for text the game no longer has are dropped.
Usage: python tools/extract_strings.py
"""
import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "game"
OUT = ROOT / "translations" / "strings.csv"
DATA_FIELDS = {"name", "role", "does", "about", "text", "desc", "line", "unlocks", "quote"}


LITERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')
# Lines that pass strings to the engine rather than to the player.
ENGINE_LINE = re.compile(r"Sfx\.|get_node|res://|user://|push_|print|has_method|connect\(|add_theme|set_stylebox|set_color|"
                         r"set_constant|set_icon|find_children|Engine\.|AudioServer|\.bus\b|path_join|InputMap|is_action|load\(|BUSES")
# Names that stay as they are in every language: the default pet and farm names, and the store.
KEEP = {"Fidus", "Mica", "Villa Aurelia", "Steam"}


def unescape(s):
    """The string as GDScript reads it: escapes such as \\n and \\" undone, and letters such as ñ left alone."""
    return s.encode("latin-1", "backslashreplace").decode("unicode_escape")


def from_scripts():
    found = []
    pattern = re.compile(r'\btr\(\s*"((?:[^"\\]|\\.)*)"')
    for f in sorted((ROOT / "scripts").rglob("*.gd")):
        text = f.read_text(encoding="utf-8")
        for m in pattern.finditer(text):
            found.append(unescape(m.group(1)))
        if f.name == "debug_tools.gd":
            continue
        for line in text.splitlines():
            if line.lstrip().startswith("#") or ENGINE_LINE.search(line):
                continue
            for m in LITERAL.finditer(line.split(" # ")[0]):
                s = unescape(m.group(1))
                if reads_like_words(s):
                    found.append(s)
    return found


def reads_like_words(s):
    """True for a string that starts with a capital and has a lowercase word in it, and is not an engine class name
    such as VBoxContainer or a pixel pattern such as YKYKY."""
    if not re.match(r"[A-Z]", s) or not re.search(r"[a-z]{2,}", s) or s in KEEP:
        return False
    return " " in s or not re.search(r"[A-Z]", s[1:])


def native_names():
    """The language picker shows each language in its own words, so those names are never translated."""
    text = (ROOT / "scripts" / "ui" / "settings_panel.gd").read_text(encoding="utf-8")
    block = re.search(r"const NATIVE_NAMES := \{(.*?)\}", text, re.S).group(1)
    return set(re.findall(r':\s*"([^"]+)"', block))


def from_data():
    found = []

    def walk(node, key=""):
        if isinstance(node, dict):
            for k, v in node.items():
                walk(v, k)
        elif isinstance(node, list):
            for v in node:
                walk(v, key)
        elif isinstance(node, str) and key in DATA_FIELDS:
            found.append(node)

    data = json.loads((ROOT / "data" / "balance.json").read_text(encoding="utf-8"))
    walk(data)
    found += data["quality"]["names"]
    for section in data["journal"].values():
        found += list(section.values())
    for lines in data.get("sayings", {}).values():
        found += lines
    found.append(data.get("tutorial_farewell", ""))
    return [f for f in found if f and f not in data.get("farm_names", [])]


def main():
    rows = {}
    languages = ["en"]
    if OUT.exists():
        with OUT.open(encoding="utf-8", newline="") as f:
            reader = csv.reader(f)
            header = next(reader)
            languages = header[1:]
            for r in reader:
                rows[r[0]] = r[1:]
    wanted = set(from_scripts() + from_data()) - native_names()
    rows = {k: v for k, v in rows.items() if k in wanted}
    for s in wanted:
        if s not in rows:
            rows[s] = [s] + [""] * (len(languages) - 1)
    OUT.parent.mkdir(exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["keys"] + languages)
        for key in sorted(rows):
            w.writerow([key] + rows[key])
    print(f"{len(rows)} strings in {OUT.relative_to(ROOT.parent)} for {', '.join(languages)}")


if __name__ == "__main__":
    main()
