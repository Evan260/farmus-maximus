extends "res://scripts/ui/window_panel.gd"
## The household: each helper, what they take care of, and hiring them.

const PEOPLE := "res://assets/sprites/people/"

var _buttons := {}


func _init() -> void:
	super("Helpers")


func signature() -> String:
	var parts := []
	for id in Data.get_value("helpers", {}):
		parts.append("%s%d%s" % [id, int(Game.helpers.get(id, 0)), Game.helper_block(id)])
	return ",".join(parts) + JSON.stringify(Game.pets)


func build() -> void:
	_buttons = {}
	var list := Ui.scroll(body, Vector2(270, 170))
	for id in Data.get_value("helpers", {}):
		var info := Game.helper_info(id)
		var r := Ui.row(Ui.card(list))
		var face := TextureRect.new()
		var path: String = PEOPLE + id + "/east.png"
		face.texture = _portrait(path)
		face.custom_minimum_size = Vector2(24, 24)
		face.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(face)
		var col := Ui.column(r)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var level := int(Game.helpers.get(id, 0))
		var levels: Array = info.get("costs", [0])
		var title := tr("%s the %s") % [info.get("name", id), Ui.mid(tr(String(info.get("role", ""))))]
		if level > 0 and levels.size() > 1:
			title += "  " + tr("(level %d)") % level
		Ui.label(col, title).add_theme_color_override("font_color", UiTheme.HEADING)
		Ui.para(col, tr(String(info.get("does", ""))), 190)
		if level > 0:
			Ui.para(col, "\"%s\"" % tr(String(info.get("quote", ""))), 190).add_theme_color_override("font_color", UiTheme.MUTED)
		var block := Game.helper_block(id)
		var cost := Game.helper_cost(id)
		if level > 0 and cost < 0:
			Ui.label(col, tr("At work")).add_theme_color_override("font_color", UiTheme.MUTED)
		elif block != "":
			Ui.label(col, tr(block)).add_theme_color_override("font_color", UiTheme.MUTED)
		else:
			var verb := tr("Train") if level > 0 else tr("Hire")
			_buttons[id] = Ui.button(col, tr("%s: %s") % [verb, Ui.cost_text({"coins": cost})], func(): Game.hire_helper(id))
	var pets := Ui.column(list)
	Ui.section(pets, tr("The animals of the house"))
	Ui.para(pets, tr("%s the dog and %s the cat keep the farm company.") % [Game.pet_name("dog"), Game.pet_name("cat")], 240)
	Ui.button(pets, tr("Change their names and coats"), func(): get_tree().call_group("hud", "open_window", "companions"))


func tick() -> void:
	for id in _buttons:
		_buttons[id].disabled = Game.coins < Game.helper_cost(id)


## The top half of a helper's sprite, so their face fills the little frame.
func _portrait(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var used := Hit.used_rect(tex)
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(used.position.x + used.size.x / 2.0 - 12, used.position.y, 24, 24)
	return a
