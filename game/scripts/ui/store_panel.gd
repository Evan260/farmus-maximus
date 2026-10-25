extends "res://scripts/ui/window_panel.gd"
## The storehouse: every good held, by quality, with what it fetches by cart today.

var _capacity: Label
var _grow: Button


func _init() -> void:
	super("Storehouse")


func signature() -> String:
	return JSON.stringify(Game.storage) + str(Game.use_manure) + str(Game.reserved_items()) + str(Game.levels.get("storage", 0))


func build() -> void:
	_grow = null
	_capacity = UiKit.label(body)
	var keep := Game.reserved_items()
	var list := UiKit.scroll(body, Vector2(250, 140))
	var keys := Game.storage.keys()
	keys.sort_custom(func(a, b): return Game.item_name(a) < Game.item_name(b))
	for key in keys:
		var r := UiKit.row(list)
		UiKit.icon(r, key)
		var name := UiKit.label(r, "%s  x%d" % [tr(Game.item_name(key)), int(Game.storage[key])])
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kind := String(Balance.get_value("items.%s.kind" % Game.item_base(key), "good"))
		var note := tr("kept for workshops") if Game.item_base(key) in keep else (tr("cart %d each") % Game.market.cart_price(key) if kind == "good" else tr("in the yard") if kind == "material" else tr("for the fields"))
		UiKit.label(r, note).add_theme_color_override("font_color", UiKit.FADED)
	if keys.is_empty():
		UiKit.label(list, tr("Empty"))
	var cost := Game.upgrade_cost("storage")
	if cost >= 0:
		var values: Array = Game.upgrade_info("storage").get("values", [])
		var bigger := int(values[mini(int(Game.levels.get("storage", 0)) + 1, values.size() - 1)])
		UiKit.section(body, tr("Make room"))
		_grow = UiKit.button(body, tr("Enlarge the storehouse to hold %d: %s") % [bigger, UiKit.cost_text({"coins": cost})], func(): Game.buy_upgrade("storage"))
	var manure := UiKit.button(body, tr("Spread manure when planting: on") if Game.use_manure else tr("Spread manure when planting: off"), func(): Game.use_manure = not Game.use_manure)
	manure.visible = Game.journal.has("item:manure")


func tick() -> void:
	_capacity.text = tr("Holds %d of %d") % [Game.stored_total(), Game.storage_capacity()]
	if _grow:
		_grow.disabled = Game.coins < Game.upgrade_cost("storage")
