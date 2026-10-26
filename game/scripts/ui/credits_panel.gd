extends "res://scripts/ui/window_panel.gd"
## Who made the game and whose work it uses: the people, the font, every recorded sound with its licence, and the
## Godot engine's own licence and the libraries inside it. The names live in data/credits.json.

const CREDITS := "res://data/credits.json"


func _init() -> void:
	super("Credits")
	fixed_size = Vector2(250, 180)


func signature() -> String:
	return "credits"


func build() -> void:
	var title := UiKit.label(body, tr("Farmus Maximus").to_upper())
	title.add_theme_color_override("font_color", UiKit.HEADING)
	var credits: Dictionary = {}
	if FileAccess.file_exists(CREDITS):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CREDITS))
		credits = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	for part in [["made_by", tr("Made by")], ["music", tr("Music")], ["sounds", tr("Sounds")], ["font", tr("Font")]]:
		var lines: Array = credits.get(part[0], [])
		if lines.is_empty():
			continue
		UiKit.section(body, part[1])
		for line in lines:
			UiKit.para(body, String(line), 230)
	UiKit.section(body, tr("Made with the Godot Engine"))
	_small(Engine.get_license_text())
	# Godot is built from other open source libraries, whose licences ask to be named alongside the game.
	for item in Engine.get_copyright_info():
		var parts: Array = item.get("parts", [])
		var licences := ", ".join(parts.map(func(p): return String(p.get("license", ""))))
		_small("%s: %s" % [item.get("name", ""), licences])


func _small(text: String) -> void:
	UiKit.para(body, text, 230).add_theme_color_override("font_color", UiKit.FADED)
