"""Collect every player-facing string into game/translations/strings.csv for translators.

The interface wraps its text in tr("..."), and names and descriptions come from game/data/balance.json.
Existing translations in the CSV are kept; new strings are added with the English text filled in.
Usage: python tools/extract_strings.py
"""
import codecs
import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "game"
OUT = ROOT / "translations" / "strings.csv"
DATA_FIELDS = {"name", "role", "does", "about", "text", "desc", "line", "unlocks", "quote"}


def from_scripts():
    found = []
    pattern = re.compile(r'\btr\(\s*"((?:[^"\\]|\\.)*)"')
    for f in sorted((ROOT / "scripts").rglob("*.gd")):
        for m in pattern.finditer(f.read_text(encoding="utf-8")):
            found.append(codecs.decode(m.group(1), "unicode_escape"))
    return found


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
    return found


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
    for s in from_scripts() + from_data():
        if s and s not in rows:
            rows[s] = [s] + [""] * (len(languages) - 1)
    OUT.parent.mkdir(exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["keys"] + languages)
        for key in sorted(rows):
            w.writerow([key] + rows[key])
    print(f"{len(rows)} strings in {OUT.relative_to(ROOT.parent)} for {', '.join(languages)}")


if __name__ == "__main__":
    main()
