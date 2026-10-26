extends "res://scripts/ui/window_panel.gd"
## Farm upgrades: a bigger cart, a paved road and the aqueduct channels. The storehouse grows from its own window.

const IDS := ["cart_capacity", "cart_speed", "channels"]

var _buttons := {}


func _init() -> void:
	super("Upgrades")


func signature() -> String:
	return JSON.stringify(Game.levels)


func build() -> void:
	_buttons = {}
	for id in IDS:
		if id == "cart_capacity":
			UiKit.para(body, tr("The cart and donkey carry the trader's loads to market."), 230).add_theme_color_override("font_color", UiKit.FADED)
		_buttons[id] = UiKit.button(body, "", func(): Game.buy_upgrade(id))


func tick() -> void:
	for id in _buttons:
		var info := Game.upgrade_info(id)
		var cost := Game.upgrade_cost(id)
		var b: Button = _buttons[id]
		var name := tr(String(info.get("name", id)))
		if Game.projects.has(id):
			b.text = tr("%s: builders at work, %s left") % [name, UiKit.duration(float(Game.projects[id]) / Game.build_speed)]
			b.disabled = true
			continue
		if cost < 0:
			b.text = tr("%s: done") % name
			b.disabled = true
			continue
		if id == "cart_speed":
			var trips: Array = info.get("values", [])
			var next_trip := int(trips[mini(int(Game.levels.get(id, 0)) + 1, trips.size() - 1)])
			b.text = "%s: %s  (%s)" % [name, UiKit.cost_text({"coins": cost}), tr("pave the next stretch; the trader's trips take %d s") % next_trip]
			b.disabled = Game.coins < cost
			continue
		if id == "channels":
			b.text = "%s: %s  (%s)" % [name, UiKit.cost_text({"coins": cost}), tr("waters the home farm, so it grows faster")]
		else:
			var values: Array = info.get("values", [])
			var next_value := float(values[mini(int(Game.levels.get(id, 0)) + 1, values.size() - 1)])
			var shown := str(int(next_value)) if next_value == floor(next_value) else str(next_value)
			b.text = "%s  %s %s  -  %s" % [name, tr(String(info.get("label", ""))), shown, UiKit.cost_text({"coins": cost})]
		b.disabled = Game.coins < cost
