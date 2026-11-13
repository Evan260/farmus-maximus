extends "res://scripts/ui/window_panel.gd"
## The storehouse: every good held, by quality, with what it fetches by cart today.

var _capacity: Label
var _grow: Button
var _grow_label: Label


func _init() -> void:
	super("Storehouse")


func signature() -> String:
	return JSON.stringify(Game.storage) + str(Game.use_manure) + JSON.stringify(Game.sellable_goods()) + str(Game.levels.get("storage", 0)) + JSON.stringify(Game.keep_goods)


func build() -> void:
	_grow = null
	_capacity = Ui.label(body)
	Ui.para(body, tr("The trader sells only the extras, leaving at home what the villa, the shrine, market orders and workshops need. Mark a good Keep to keep all of it."), 250).add_theme_color_override("font_color", UiTheme.MUTED)
	var selling_now := Game.sellable_goods()
	var list := Ui.scroll(body, Vector2(250, 140))
	var keys := Game.storage.keys()
	keys.sort_custom(func(a, b): return Game.item_name(a) < Game.item_name(b))
	for key in keys:
		var r := Ui.row(list)
		Ui.icon(r, key)
		var name := Ui.label(r, "%s  x%d" % [tr(Game.item_name(key)), int(Game.storage[key])])
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kind := String(Data.get_value("items.%s.kind" % Game.item_base(key), "good"))
		if kind == "good":
			# The trader only takes goods marked for sale; a click keeps a good at home instead.
			var selling := Game.for_sale(key)
			var kept := int(Game.storage[key]) - int(selling_now.get(key, 0))
			if selling and kept > 0:
				Ui.label(r, tr("%d kept") % kept).add_theme_color_override("font_color", UiTheme.MUTED)
			var mark := Ui.button(r, tr("For sale") if selling else tr("Keep"), func(): Game.set_for_sale(key, not selling); refresh())
			mark.custom_minimum_size = Vector2(56, 0)
			continue
		var note := tr("for building, takes no room") if kind == "material" else tr("for the fields")
		# A long name and note in some languages share the line, the note wrapping onto a second line.
		var noted := Ui.label(r, note)
		noted.add_theme_color_override("font_color", UiTheme.MUTED)
		noted.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		noted.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		noted.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if keys.is_empty():
		Ui.label(list, tr("Empty"))
	var cost := Game.upgrade_cost("storage")
	if cost >= 0:
		var values: Array = Game.upgrade_info("storage").get("values", [])
		var bigger := int(values[mini(int(Game.levels.get("storage", 0)) + 1, values.size() - 1)])
		Ui.section(body, tr("Make room"))
		_grow = Ui.setting(body, tr("Enlarge it to hold %d") % bigger, Ui.cost_text({"coins": cost}), func(): Game.buy_upgrade("storage"))
		_grow_label = _grow.get_parent().get_child(0)
	var manure := Ui.setting(body, tr("Spread manure when planting"), tr("On") if Game.use_manure else tr("Off"), func(): Game.use_manure = not Game.use_manure)
	manure.get_parent().visible = Game.journal.has("item:manure")


func tick() -> void:
	_capacity.text = tr("Holds %d of %d") % [Game.in_storehouse(), Game.storage_capacity()]
	if not Game.cart["away"]:
		_capacity.text += "\n" + tr("On the cart: %d of %d") % [Game.on_cart(), Game.cart_capacity()]
	if _grow:
		_grow.disabled = Game.coins < Game.upgrade_cost("storage") or Game.projects.has("storage")
		if Game.projects.has("storage"):
			_grow.text = tr("Building")
			_grow_label.text = tr("Builders are enlarging it: %s left") % Ui.duration(float(Game.projects["storage"]) / Game.build_speed)
