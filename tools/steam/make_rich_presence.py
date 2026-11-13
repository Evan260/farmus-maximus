"""Write the Steamworks rich presence localization file, tools/steam/rich_presence.vdf.

The game sets steam_display to one of the status tokens below (awards.gd), with the keys "stage" (the villa's stage,
1 to 7) and "day" (the farm's day, as the top bar shows it). The villa's stage names come from the game's own
translations in game/translations/strings.csv, so the friends list names the villa as the game does.
Upload the file in Steamworks under Community, Rich Presence (docs/Steam-setup.md).

Usage: python tools/steam/make_rich_presence.py
"""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).with_name("rich_presence.vdf")
# Steam's API language names for each column of strings.csv; Latin American Spanish reads the same Spanish.
STEAM_LANGUAGES = {
    "en": ["english"], "fr": ["french"], "de": ["german"], "es": ["spanish", "latam"], "it": ["italian"],
    "pt_BR": ["brazilian"], "pl": ["polish"], "tr": ["turkish"], "ru": ["russian"], "uk": ["ukrainian"],
    "ja": ["japanese"], "ko": ["koreana"], "zh_CN": ["schinese"], "zh_TW": ["tchinese"],
}
STATUS = {
    "#Estate": {
        "en": "{#Villa_%stage%}, day %day%", "fr": "{#Villa_%stage%}, jour %day%", "de": "{#Villa_%stage%}, Tag %day%",
        "es": "{#Villa_%stage%}, día %day%", "it": "{#Villa_%stage%}, giorno %day%", "pt_BR": "{#Villa_%stage%}, dia %day%",
        "pl": "{#Villa_%stage%}, dzień %day%", "tr": "{#Villa_%stage%}, %day%. gün", "ru": "{#Villa_%stage%}, день %day%",
        "uk": "{#Villa_%stage%}, день %day%", "ja": "{#Villa_%stage%}、%day%日目", "ko": "{#Villa_%stage%}, %day%일차",
        "zh_CN": "{#Villa_%stage%}，第%day%天", "zh_TW": "{#Villa_%stage%}，第%day%天",
    },
    "#Town": {
        "en": "In the market town", "fr": "Dans la ville du marché", "de": "In der Marktstadt",
        "es": "En el mercado del pueblo", "it": "Nella città di mercato", "pt_BR": "Na cidade do mercado",
        "pl": "W miasteczku targowym", "tr": "Pazar kasabasında", "ru": "В рыночном городке",
        "uk": "У ринковому містечку", "ja": "市場の町にいます", "ko": "시장 마을에서", "zh_CN": "在集镇", "zh_TW": "在市集小鎮",
    },
    "#Inside": {
        "en": "Inside the farmhouse", "fr": "Dans la ferme", "de": "Im Bauernhaus", "es": "Dentro de la casa de campo",
        "it": "Nella casa colonica", "pt_BR": "Dentro da casa da fazenda", "pl": "W domu", "tr": "Çiftlik evinde",
        "ru": "В фермерском доме", "uk": "У фермерському будинку", "ja": "農家の中", "ko": "농가 안에서",
        "zh_CN": "在农舍里", "zh_TW": "在農舍裡",
    },
    "#Title": {
        "en": "In the menu", "fr": "Dans le menu", "de": "Im Hauptmenü", "es": "En el menú", "it": "Nel menu",
        "pt_BR": "No menu", "pl": "W menu", "tr": "Menüde", "ru": "В меню", "uk": "У меню", "ja": "メニュー画面",
        "ko": "메뉴 화면", "zh_CN": "在菜单中", "zh_TW": "在選單中",
    },
}


def quoted(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    with open(ROOT / "game/translations/strings.csv", encoding="utf-8", newline="") as f:
        sheet = {row["keys"]: row for row in csv.DictReader(f)}
    data = json.loads((ROOT / "game/data/balance.json").read_text(encoding="utf-8"))
    stages = [s["name"] for s in data["villa"]["stages"]]
    lines = ['"lang"', "{"]
    for column, names in STEAM_LANGUAGES.items():
        tokens = {token: texts[column] for token, texts in STATUS.items()}
        for n, name in enumerate(stages, 1):
            tokens[f"#Villa_{n}"] = sheet[name][column] or name
        for steam_name in names:
            lines += [f"\t{quoted(steam_name)}", "\t{", '\t\t"tokens"', "\t\t{"]
            lines += [f"\t\t\t{quoted(token)}\t{quoted(text)}" for token, text in tokens.items()]
            lines += ["\t\t}", "\t}"]
    lines.append("}")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
