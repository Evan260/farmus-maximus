extends "res://scripts/ui/window_panel.gd"
## The farmer's journal: every crop, good, building, helper, animal, find, sighting and festival, plus the achievements.
## Sections are listed down the left side; the chosen one's pages fill the right.

var section := "Crops"


func _init() -> void:
	super("Farmer's journal")


func signature() -> String:
	return "%s%d%d" % [section, Game.journal.entries.size(), Game.journal.achievements.size()]


func build() -> void:
	set_title(tr("Farmer's journal") + "   " + tr("%d%% filled") % int(round(Game.journal.share() * 100.0)))
	var split := UiKit.row(body)
	split.add_theme_constant_override("separation", 6)
	var menu := UiKit.column(split)
	var sections := []
	for e in Game.journal.catalogue():
		if not e["section"] in sections:
			sections.append(e["section"])
	sections.append("Achievements")
	for s in sections:
		var b := UiKit.button(menu, tr(s), func(): section = s; refresh())
		b.toggle_mode = true
		b.button_pressed = s == section
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_FILL
	var page := UiKit.column(split)
	var count := UiKit.label(page)
	count.add_theme_color_override("font_color", UiKit.HEADING)
	var list := UiKit.scroll(page, Vector2(210, 170))
	if section == "Achievements":
		var got := 0
		for a in Balance.get_value("achievements", []):
			var has: bool = Game.journal.achievements.has(a["id"])
			got += int(has)
			var l := UiKit.para(list, "%s: %s" % [tr(String(a["name"])), tr(String(a["desc"]))], 196)
			if not has:
				l.add_theme_color_override("font_color", UiKit.FADED)
		count.text = tr("%d of %d achievements") % [got, Balance.get_value("achievements", []).size()]
		return
	var found := 0
	var total := 0
	for e in Game.journal.catalogue():
		if e["section"] != section:
			continue
		total += 1
		var has: bool = Game.journal.has(e["id"])
		found += int(has)
		var r := UiKit.row(list)
		var item_id := String(e["id"]).get_slice(":", 1) if String(e["id"]).begins_with("item:") or String(e["id"]).begins_with("quality:") else ""
		if item_id != "" and has:
			UiKit.icon(r, item_id)
		var l := UiKit.label(r, tr(String(e["name"])) if has else "? ? ?")
		if not has:
			l.add_theme_color_override("font_color", UiKit.FADED)
	count.text = tr("%d of %d found") % [found, total]
