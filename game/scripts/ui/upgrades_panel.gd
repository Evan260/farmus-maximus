extends "res://scripts/ui/window_panel.gd"
## Farm upgrades: a bigger cart, a paved road and the aqueduct channels. The storehouse grows from its own window.

const IDS := ["cart_capacity", "cart_speed", "channels"]
const WIDTH := 250

var _rows := {}


func _init() -> void:
	super("Upgrades")


func signature() -> String:
	return JSON.stringify(Game.levels)


func build() -> void:
	_rows = {}
	UiKit.para(body, tr("The cart and donkey carry the trader's loads to market."), WIDTH).add_theme_color_override("font_color", UiKit.MUTED)
	for id in IDS:
		var card := UiKit.card(body)
		var b := UiKit.setting(card, tr(String(Game.upgrade_info(id).get("name", id))), "", func(): Game.buy_upgrade(id), WIDTH - 10)
		b.get_parent().get_child(0).add_theme_color_override("font_color", UiKit.HEADING)
		var about := UiKit.para(card, "", WIDTH - 10)
		about.add_theme_color_override("font_color", UiKit.MUTED)
		_rows[id] = {"button": b, "about": about}


func tick() -> void:
	for id in _rows:
		var info := Game.upgrade_info(id)
		var cost := Game.upgrade_cost(id)
		var b: Button = _rows[id]["button"]
		var about: Label = _rows[id]["about"]
		var level := int(Game.levels.get(id, 0))
		var values: Array = info.get("values", [0])
		var now := int(values[mini(level, values.size() - 1)])
		var next := int(values[mini(level + 1, values.size() - 1)])
		var build_time := UiKit.duration(Game.upgrade_seconds(id) / Game.build_speed)
		if Game.projects.has(id):
			b.text = tr("Building")
			b.disabled = true
			about.text = tr("Builders at work: %s left") % UiKit.duration(float(Game.projects[id]) / Game.build_speed)
			continue
		if cost < 0:
			b.text = tr("Done")
			b.disabled = true
			match id:
				"cart_capacity":
					about.text = tr("The cart carries %d goods.") % now
				"cart_speed":
					about.text = tr("The whole road is paved. The trader's trips take %d s.") % now
				"channels":
					about.text = tr("Water runs to the home farm, so it grows faster.")
			continue
		b.text = UiKit.cost_text({"coins": cost})
		b.disabled = Game.coins < cost
		match id:
			"cart_capacity":
				about.text = tr("Carries %d goods instead of %d.") % [next, now]
			"cart_speed":
				var where: String = [tr("Paves the estate's road in %s."), tr("Lays kerbstones and milestones along the road in %s."), tr("Lays a gravel footpath beside the road in %s.")][mini(level, 2)]
				about.text = (where % build_time) + " " + tr("The trader's trips take %d s instead of %d s.") % [next, now]
			"channels":
				about.text = tr("Built in %s. Waters the home farm, so it grows faster.") % build_time
