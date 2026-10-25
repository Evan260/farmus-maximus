extends "res://scripts/ui/window_panel.gd"
## Farm upgrades: a bigger cart, a faster donkey and the aqueduct channels. The storehouse grows from its own window.

const IDS := ["cart_capacity", "cart_speed", "channels"]

var _buttons := {}


func _init() -> void:
	super("Upgrades")


func signature() -> String:
	return JSON.stringify(Game.levels)


func build() -> void:
	_buttons = {}
	for id in IDS:
		_buttons[id] = UiKit.button(body, "", func(): Game.buy_upgrade(id))


func tick() -> void:
	for id in _buttons:
		var info := Game.upgrade_info(id)
		var cost := Game.upgrade_cost(id)
		var b: Button = _buttons[id]
		var name := tr(String(info.get("name", id)))
		if cost < 0:
			b.text = tr("%s: done") % name
			b.disabled = true
			continue
		if id == "channels":
			b.text = "%s: %s  (%s)" % [name, UiKit.cost_text({"coins": cost}), tr("waters the home farm, so it grows faster")]
		else:
			var values: Array = info.get("values", [])
			var next_value := float(values[mini(int(Game.levels.get(id, 0)) + 1, values.size() - 1)])
			var shown := str(int(next_value)) if next_value == floor(next_value) else str(next_value)
			b.text = "%s  %s %s  -  %s" % [name, tr(String(info.get("label", ""))), shown, UiKit.cost_text({"coins": cost})]
		b.disabled = Game.coins < cost
