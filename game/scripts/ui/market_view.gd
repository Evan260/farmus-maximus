extends CanvasLayer
## The market town: a screen of its own over the estate, with stalls to sell at full price, the shop, deeds,
## decorations, the notice board of orders and the price board.

signal left_town

const Walker := preload("res://scripts/world/walker.gd")
const BG := "res://assets/backgrounds/market/painting.png"

var tab := "Stalls"
var _scene: Node2D
var _tabs: HBoxContainer
var _list: VBoxContainer
var _header: Label
var _signature := ""
var _timer := 0.0
var _fountain: CPUParticles2D
var _bunting: Node2D


func _ready() -> void:
	layer = 8
	visible = false
	_scene = Node2D.new()
	add_child(_scene)
	var bg := Sprite2D.new()
	bg.centered = false
	if ResourceLoader.exists(BG):
		bg.texture = load(BG)
	_scene.add_child(bg)
	for who in ["townsman", "townswoman", "traveller", "shepherd"]:
		var dir := "res://assets/sprites/people/%s/" % who
		if not ResourceLoader.exists(dir + "east.png"):
			continue
		var w := Walker.new()
		w.dir = dir
		w.min_x = 20
		w.max_x = 460
		w.position = Vector2(randf_range(40, 440), 262 + randi() % 6)
		_scene.add_child(w)
	_fountain = CPUParticles2D.new()
	_fountain.position = Vector2(240, 205)
	_fountain.amount = 24
	_fountain.lifetime = 0.9
	_fountain.direction = Vector2.UP
	_fountain.spread = 18.0
	_fountain.initial_velocity_min = 20.0
	_fountain.initial_velocity_max = 28.0
	_fountain.gravity = Vector2(0, 60)
	_fountain.color = Color(0.75, 0.88, 1.0, 0.8)
	_scene.add_child(_fountain)
	_bunting = Node2D.new()
	_bunting.draw.connect(_draw_bunting)
	_scene.add_child(_bunting)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.make_theme()
	add_child(root)
	var back := UiKit.button(root, tr("Back to the estate"), leave)
	back.position = Vector2(4, 4)
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_top = 22
	var col := UiKit.column(panel)
	_header = UiKit.label(col)
	_tabs = UiKit.row(col)
	_list = UiKit.scroll(col, Vector2(300, 150))


func enter() -> void:
	visible = true
	_bunting.queue_redraw()
	Game.add_stat("market_visits", 1)
	Sfx.play("market_bell")
	_fountain.emitting = not Settings.reduced_motion
	_signature = ""
	_refresh()


## During a festival the market is strung with flags across the square.
func _draw_bunting() -> void:
	if Game.calendar.festival().is_empty():
		return
	var colours := [Color(0.78, 0.25, 0.22), Color(0.95, 0.8, 0.35), Color(0.35, 0.55, 0.32), Color(0.55, 0.35, 0.65)]
	for line in 2:
		var y0 := 60.0 + line * 30.0
		for i in 40:
			var x := i * 12.0 + line * 6.0
			var sag := sin(x / 480.0 * PI) * 14.0
			_bunting.draw_line(Vector2(x, y0 + sag), Vector2(x + 12, y0 + sin((x + 12) / 480.0 * PI) * 14.0), Color(0.3, 0.22, 0.18), 1.0)
			_bunting.draw_colored_polygon(PackedVector2Array([Vector2(x + 2, y0 + sag), Vector2(x + 9, y0 + sag), Vector2(x + 5.5, y0 + sag + 7)]), colours[(i + line) % colours.size()])


func leave() -> void:
	visible = false
	left_town.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.3
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("close_panel"):
		leave()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	var festival: Dictionary = Game.calendar.festival()
	_header.text = tr("Market town  -  %s, day %d") % [tr(Game.calendar.season_name()), Game.calendar.day_of_season() + 1]
	if not festival.is_empty():
		_header.text += "  -  " + tr(String(festival["name"]))
	_header.text += "\n" + tr("Sestertii %d   Aurei %d") % [Game.coins, Game.aureus]
	var sig := "%s|%s|%s|%d|%d|%s|%s|%s|%s" % [tab, JSON.stringify(Game.storage), JSON.stringify(Game.market.orders), Game.coins, Game.aureus,
		JSON.stringify(Game.zones_owned), JSON.stringify(Game.decorations), JSON.stringify(Game.market.sold_today), Game.villa_stage]
	if sig == _signature:
		return
	_signature = sig
	UiKit.clear(_tabs)
	for t in ["Stalls", "Notice board", "Prices", "Shop", "Land", "Decorations"]:
		var b := UiKit.button(_tabs, tr(t), func(): tab = t; _signature = ""; _refresh())
		b.toggle_mode = true
		b.button_pressed = t == tab
	UiKit.clear(_list)
	match tab:
		"Stalls":
			_build_stalls()
		"Notice board":
			_build_orders()
		"Prices":
			_build_prices()
		"Shop":
			_build_shop()
		"Land":
			_build_land()
		"Decorations":
			_build_decorations()
	UiKit.pad_focus.call_deferred(_tabs.get_parent())


func _build_stalls() -> void:
	var keys := Game.storage.keys().filter(func(k): return Balance.get_value("items.%s.kind" % Game.item_base(k), "good") == "good")
	keys.sort_custom(func(a, b): return Game.market.price(a) > Game.market.price(b))
	if keys.is_empty():
		UiKit.para(_list, tr("Nothing to sell. Bring goods from the storehouse: they are sold here at full price, without the trader's cut."), 280)
	for key in keys:
		var r := UiKit.row(_list)
		UiKit.icon(r, key)
		var l := UiKit.label(r, "%s x%d  -  %d" % [tr(Game.item_name(key)), int(Game.storage[key]), Game.market.price(key)])
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.button(r, tr("Sell 1"), func(): _sell(key, 1))
		UiKit.button(r, tr("Sell all"), func(): _sell(key, int(Game.storage.get(key, 0))))


func _sell(key: String, n: int) -> void:
	var coins: int = Game.market.sell(key, n)
	if coins > 0:
		Sfx.play("coins")


func _build_orders() -> void:
	if Game.market.orders.is_empty():
		UiKit.para(_list, tr("No requests today. New ones are pinned up through the day."), 280)
	for i in Game.market.orders.size():
		var o: Dictionary = Game.market.orders[i]
		var box := UiKit.column(_list)
		UiKit.para(box, "%s (%s): \"%s\"" % [o["who"], tr(String(o["role"])).to_lower(), tr(String(o["text"]))], 280)
		var r := UiKit.row(box)
		UiKit.icon(r, String(o["item"]))
		var reward := tr("Pays %d sestertii") % int(o["coins"])
		if int(o["aureus"]) > 0:
			reward += " " + tr("and a gold aureus")
		if String(o.get("seed", "")) != "":
			reward += " " + tr("and a rare seed")
		UiKit.label(r, "%s  (%s: %d)" % [reward, tr("you have"), Game.count_item(String(o["item"]))])
		var b := UiKit.button(r, tr("Deliver"), func(): if Game.market.deliver(i): Sfx.play("coins"))
		b.disabled = not Game.market.can_deliver(i)


func _build_prices() -> void:
	var festival: Dictionary = Game.calendar.festival()
	if not festival.is_empty():
		UiKit.para(_list, "%s: %s" % [tr(String(festival["name"])), tr(String(festival.get("about", "")))], 280)
	var fav := []
	for item in Game.market.favourites:
		fav.append(tr(String(Balance.get_value("items.%s.name" % item, item))).to_lower())
	UiKit.para(_list, tr("Wanted today: %s") % ", ".join(fav), 280)
	UiKit.para(_list, tr("Selling many of one good lowers its price until tomorrow, so a mix pays best."), 280).add_theme_color_override("font_color", UiKit.FADED)
	for item in Balance.get_value("items", {}):
		if Balance.get_value("items.%s.kind" % item, "good") != "good" or not Game.journal.has("item:" + item):
			continue
		var r := UiKit.row(_list)
		UiKit.icon(r, item)
		UiKit.label(r, "%s: %d  (%s %d)" % [tr(String(Balance.get_value("items.%s.name" % item, item))), Game.market.price(item), tr("cart"), Game.market.cart_price(item)])


func _build_shop() -> void:
	for entry in Game.market.catalog():
		var block: String = Game.market.catalog_block(entry)
		if block == "Bought":
			continue
		var r := UiKit.row(_list)
		if entry.has("item"):
			UiKit.icon(r, String(entry["item"]))
		var price := {"coins": int(entry.get("price", 0)), "aureus": int(entry.get("aureus", 0))}
		var l := UiKit.para(r, "%s  -  %s" % [tr(String(entry["name"])), UiKit.cost_text(price)], 170)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if block != "":
			UiKit.label(r, tr(block)).add_theme_color_override("font_color", UiKit.FADED)
			continue
		var buy := UiKit.button(r, tr("Buy"), func(): if Game.market.buy(String(entry["id"])): Sfx.play("coins"))
		buy.disabled = Game.missing(price) != ""
		if entry.has("item"):
			var five := UiKit.button(r, tr("Buy 5"), func(): if Game.market.buy(String(entry["id"]), 5): Sfx.play("coins"))
			five.disabled = Game.missing({"coins": int(entry["price"]) * 5}) != ""


func _build_land() -> void:
	for z in Game.zones():
		if Game.zone_owned(String(z["id"])):
			continue
		var r := UiKit.row(_list)
		var l := UiKit.label(r, "%s  -  %s" % [tr(String(z["name"])), UiKit.cost_text({"coins": int(z.get("deed", 0))})])
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var block: String = Game.zone_block(String(z["id"]))
		if block != "":
			UiKit.para(r, tr(block), 120).add_theme_color_override("font_color", UiKit.FADED)
		else:
			var b := UiKit.button(r, tr("Buy the deed"), func(): Game.buy_zone(String(z["id"])))
			b.disabled = Game.coins < int(z.get("deed", 0))
	if _list.get_child_count() == 0:
		UiKit.label(_list, tr("The whole estate is yours."))


func _build_decorations() -> void:
	for id in Balance.get_value("decorations", {}):
		var d: Dictionary = Game.decoration_info(id)
		var r := UiKit.row(_list)
		var tex := "res://assets/sprites/decorations/%s.png" % id
		if ResourceLoader.exists(tex):
			var t := TextureRect.new()
			t.texture = load(tex)
			t.custom_minimum_size = Vector2(16, 16)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.add_child(t)
		var price := {"coins": int(d.get("price", 0)), "aureus": int(d.get("aureus", 0))}
		var l := UiKit.label(r, "%s  -  %s" % [tr(String(d["name"])), UiKit.cost_text(price)])
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var block: String = Game.decoration_block(id)
		if block != "":
			UiKit.label(r, tr(block)).add_theme_color_override("font_color", UiKit.FADED)
		else:
			var b := UiKit.button(r, tr("Buy"), func(): if Game.buy_decoration(id): Sfx.play("coins"))
			b.disabled = Game.missing(price) != ""
