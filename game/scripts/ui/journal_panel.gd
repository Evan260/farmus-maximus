extends "res://scripts/ui/window_panel.gd"
## The farmer's journal: every crop, good, building, helper, animal, find, sighting and festival, plus the achievements.

var section := "Crops"


func _init() -> void:
	super("Farmer's journal")


func signature() -> String:
	return "%s%d%d" % [section, Game.journal.entries.size(), Game.journal.achievements.size()]


func build() -> void:
	UiKit.label(body, tr("Pages filled: %d%%") % int(round(Game.journal.share() * 100.0)))
	var tabs := HFlowContainer.new()
	tabs.custom_minimum_size = Vector2(280, 0)
	body.add_child(tabs)
	var sections := []
	for e in Game.journal.catalogue():
		if not e["section"] in sections:
			sections.append(e["section"])
	sections.append("Achievements")
	for s in sections:
		var b := UiKit.button(tabs, tr(s), func(): section = s; refresh())
		b.toggle_mode = true
		b.button_pressed = s == section
	var list := UiKit.scroll(body, Vector2(280, 120))
	if section == "Achievements":
		for a in Balance.get_value("achievements", []):
			var got: bool = Game.journal.achievements.has(a["id"])
			var l := UiKit.para(list, "%s  %s: %s" % ["*" if got else "-", tr(String(a["name"])), tr(String(a["desc"]))], 260)
			if not got:
				l.add_theme_color_override("font_color", UiKit.FADED)
		return
	var found := 0
	var total := 0
	for e in Game.journal.catalogue():
		if e["section"] != section:
			continue
		total += 1
		var got: bool = Game.journal.has(e["id"])
		if got:
			found += 1
		var r := UiKit.row(list)
		var item_id := String(e["id"]).get_slice(":", 1) if String(e["id"]).begins_with("item:") or String(e["id"]).begins_with("quality:") else ""
		if item_id != "" and got:
			UiKit.icon(r, item_id)
		var l := UiKit.label(r, tr(String(e["name"])) if got else "? ? ?")
		if not got:
			l.add_theme_color_override("font_color", UiKit.FADED)
	UiKit.label(body, tr("%d of %d found") % [found, total])
