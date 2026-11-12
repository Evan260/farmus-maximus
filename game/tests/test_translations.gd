extends "res://tests/test_case.gd"
## The strings sheet against the code, the data and the fonts: every shown string is in it, every language has every
## string with the English placeholders, and every letter has a font to draw it.

const SHEET := "res://translations/strings.csv"
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
## Fields of data/balance.json that the player reads, as tools/extract_strings.py collects them.
const DATA_FIELDS := ["name", "plural", "praise", "role", "does", "about", "text", "desc", "line", "unlocks", "quote", "child"]


## The strings sheet as {english: {locale: text}}, or empty in an exported game, which keeps only the translations.
func _sheet() -> Dictionary:
	if not FileAccess.file_exists(SHEET):
		return {}
	var f := FileAccess.open(SHEET, FileAccess.READ)
	var header := f.get_csv_line()
	var rows := {}
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() < header.size():
			continue
		var row := {}
		for i in range(1, header.size()):
			row[header[i]] = line[i]
		rows[line[0]] = row
	return rows


## The format codes in a string, sorted: %s, %d, %.1f and %% as Godot reads them, and {name} parts.
func _placeholders(s: String) -> Array:
	var out := []
	var i := 0
	while i < s.length():
		var c := s[i]
		if c == "%":
			var j := i + 1
			while j < s.length() and s[j] in "-0123456789.":
				j += 1
			if j < s.length() and s[j] in "sdifxXcv%":
				out.append(s.substr(i, j - i + 1))
				i = j + 1
				continue
		elif c == "{":
			var close := s.find("}", i)
			if close > i and s.substr(i + 1, close - i - 1).is_valid_ascii_identifier():
				out.append(s.substr(i, close - i + 1))
				i = close + 1
				continue
		i += 1
	out.sort()
	return out


## Every string literal passed to tr() or TranslationServer.translate() in the game's scripts.
func _keys_in_scripts() -> Dictionary:
	var found := {}
	var dirs := ["res://scripts"]
	while not dirs.is_empty():
		var dir: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			dirs.append(dir.path_join(sub))
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd") or file == "dev.gd":
				continue
			var text := FileAccess.get_file_as_string(dir.path_join(file))
			for call in ["tr(\"", "translate(\""]:
				var at := text.find(call)
				while at >= 0:
					if call != "tr(\"" or at == 0 or not (text[at - 1].is_valid_identifier() or text[at - 1] == "."):
						found[_literal(text, at + call.length())] = "%s/%s" % [dir, file]
					at = text.find(call, at + 1)
	return found


## The string literal that starts at `from`, just after its opening quote, with its escapes undone.
func _literal(text: String, from: int) -> String:
	var out := ""
	var i := from
	while i < text.length() and text[i] != "\"":
		if text[i] == "\\" and i + 1 < text.length():
			i += 1
			out += {"n": "\n", "t": "\t"}.get(text[i], text[i])
		else:
			out += text[i]
		i += 1
	return out


## Every shown field of the game's data.
func _data_strings(node: Variant, key := "", out: Array = []) -> Array:
	if node is Dictionary:
		for k in node:
			_data_strings(node[k], str(k), out)
	elif node is Array:
		for v in node:
			_data_strings(v, key, out)
	elif node is String and key in DATA_FIELDS and node != "":
		out.append(node)
	return out


## Whether a font or one of its fallbacks draws a letter.
func _draws(font: Font, c: int) -> bool:
	if font.has_char(c):
		return true
	for f in font.fallbacks:
		if _draws(f, c):
			return true
	return false


func test_every_string_in_the_code_is_in_the_sheet() -> void:
	var sheet := _sheet()
	if sheet.is_empty():
		return
	var missing := []
	var keys := _keys_in_scripts()
	for key in keys:
		if not sheet.has(key):
			missing.append("%s (%s)" % [key, keys[key]])
	var farm_names: Array = root.get_node("Data").get_value("farm_names", [])
	for s in _data_strings(root.get_node("Data").data):
		if not sheet.has(s) and not s in farm_names:
			missing.append(s)
	check(missing.is_empty(), "every string the game shows is in the strings sheet (missing %s)" % ", ".join(missing.slice(0, 8)))


func test_every_language_has_every_string() -> void:
	var sheet := _sheet()
	if sheet.is_empty():
		return
	var gaps := {}
	for key in sheet:
		for loc in sheet[key]:
			if str(sheet[key][loc]).strip_edges() == "":
				gaps[loc] = int(gaps.get(loc, 0)) + 1
	check(gaps.is_empty(), "every language has every string (missing %s)" % str(gaps))
	check((sheet.values()[0] as Dictionary).size() == 14, "the sheet has all 14 languages")


func test_translations_keep_their_placeholders() -> void:
	var sheet := _sheet()
	var wrong := []
	for key in sheet:
		var want := _placeholders(key)
		for loc in sheet[key]:
			if _placeholders(str(sheet[key][loc])) != want:
				wrong.append("%s in %s" % [key, loc])
	check(wrong.is_empty(), "every translation keeps the English placeholders (%d wrong: %s)" % [wrong.size(), ", ".join(wrong.slice(0, 6))])


func test_fonts_have_every_letter() -> void:
	var sheet := _sheet()
	var missing := {}
	for key in sheet:
		for loc in sheet[key]:
			var font := UiTheme.ui_font(loc)
			for c in str(sheet[key][loc]):
				if c != "\n" and c != " " and not _draws(font, c.unicode_at(0)) and not str(missing.get(loc, "")).contains(c):
					missing[loc] = str(missing.get(loc, "")) + c
	for loc in SettingsPanel.NATIVE_NAMES:
		for c in str(SettingsPanel.NATIVE_NAMES[loc]):
			if c != " " and not _draws(UiTheme.ui_font(loc), c.unicode_at(0)) and not str(missing.get(loc, "")).contains(c):
				missing[loc] = str(missing.get(loc, "")) + c
	check(missing.is_empty(), "every language's font draws all its letters (missing %s)" % str(missing))


func test_composed_sentences_are_whole_in_every_language() -> void:
	var data: Node = root.get_node("Data")
	var panel := load("res://scripts/ui/building_panel.gd")
	var market := load("res://scripts/ui/market_view.gd")
	var locale := TranslationServer.get_locale()
	var levels := []
	for id in data.get_value("buildings", {}):
		levels.append_array(data.get_value("buildings.%s.levels" % id, []))
	var english := {}
	for level in levels:
		english[panel.upgrade_text(level)] = true
	var rewards_now := func() -> Array: return [[false, false], [true, false], [false, true], [true, true]].map(func(c): return market._reward_text(40, c[0], c[1], 2))
	var rewards: Array = rewards_now.call()
	for lang in ["fr", "ja", "zh_CN"]:
		TranslationServer.set_locale(lang)
		var untranslated := levels.filter(func(level): return english.has(panel.upgrade_text(level)))
		check(untranslated.is_empty(), "every workshop upgrade reads as one translated sentence in %s" % lang)
		var translated: Array = rewards_now.call()
		for k in rewards.size():
			var text: String = translated[k]
			check(text != rewards[k] and "40" in text and "2" in text, "a market request's reward reads as one translated sentence in %s (%s)" % [lang, text])
	TranslationServer.set_locale(locale)
