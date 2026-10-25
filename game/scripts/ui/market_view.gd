extends CanvasLayer
## The market town: a screen of its own over the estate. The painting itself is the menu: the stalls, the shop, the
## notice board, the price slate, the temple's land registry and the craftsman each open their own window when clicked.

signal left_town

const Walker := preload("res://scripts/world/walker.gd")
const BG := "res://assets/backgrounds/market/painting.png"
## The places in the painting that can be clicked, in the painting's pixels.
const SPOTS := [
	{"id": "Stalls", "name": "Market stalls", "hint": "Sell your goods at full price", "rect": Rect2(105, 135, 110, 82)},
	{"id": "Shop", "name": "The shop", "hint": "Cuttings, materials and animals", "rect": Rect2(398, 118, 82, 145)},
	{"id": "Decorations", "name": "The craftsman", "hint": "Statues, lanterns and other decorations", "rect": Rect2(326, 140, 52, 62)},
	{"id": "Land", "name": "The temple", "hint": "Land deeds are kept here", "rect": Rect2(226, 55, 94, 115)},
	{"id": "Notice board", "name": "Notice board", "hint": "Requests from the townsfolk", "rect": Rect2(84, 164, 26, 46)},
	{"id": "Prices", "name": "Price slate", "hint": "Today's prices and what is wanted", "rect": Rect2(380, 186, 18, 26)},
]

var tab := ""
var _scene: Node2D
var _props: Node2D
var _list: VBoxContainer
var _title: Label
var _purse: Label
var _hover_label: Label
var _hovered := ""
var _panel: PanelContainer
var _pad_bar: HBoxContainer
var _signature := ""
var _timer := 0.0
var _fountain: CPUParticles2D
var _bunting: Node2D
## The town's windows are drawn on their own layer at the interface's scale, over the town picture at the estate's.
var _ui_layer: CanvasLayer
var _ui_root: Control


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
	_props = Node2D.new()
	_props.draw.connect(_draw_props)
	_scene.add_child(_props)
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
	_fountain.position = Vector2(268, 170)
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

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 9
	_ui_layer.visible = false
	add_child(_ui_layer)
	_ui_root = Control.new()
	_ui_root.theme = UiKit.make_theme()
	# The whole screen listens for clicks on the painting; the windows on top take their own clicks first.
	_ui_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.gui_input.connect(_on_picture_input)
	_ui_layer.add_child(_ui_root)
	var top := UiKit.row(_ui_root)
	top.position = Vector2(4, 4)
	UiKit.button(top, tr("Back to the estate"), leave)
	var purse_box := PanelContainer.new()
	top.add_child(purse_box)
	_purse = UiKit.label(purse_box)
	_hover_label = UiKit.label(_ui_root, "", true)
	_hover_label.visible = false
	_panel = PanelContainer.new()
	_panel.visible = false
	_ui_root.add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var col := UiKit.column(_panel)
	col.custom_minimum_size = Vector2(310, 0)
	var head := UiKit.row(col)
	_title = UiKit.label(head)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.close_button(head, _close_panel)
	_list = UiKit.scroll(col, Vector2(300, 160))
	# A gamepad cannot point at the painting, so it gets a row of the same places along the bottom.
	_pad_bar = UiKit.row(_ui_root)
	for spot in SPOTS:
		UiKit.button(_pad_bar, tr(String(spot["name"])), func(): _open(String(spot["id"])))
	Windowing.view_changed.connect(_fit)
	_fit()


## The town picture is scaled up by a whole number until it covers the window, and the windows follow the interface scale.
func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var cover := ceili(maxf(view.x / 480.0, view.y / 272.0))
	_scene.scale = Vector2(cover, cover)
	_scene.position = ((view - Vector2(480, 272) * cover) / 2.0).round()
	_ui_layer.scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_ui_root.size = (view / Windowing.ui_scale).floor()
	_pad_bar.position = Vector2(4, _ui_root.size.y - 18)


func enter() -> void:
	visible = true
	_ui_layer.visible = true
	tab = ""
	_panel.visible = false
	_bunting.queue_redraw()
	_props.queue_redraw()
	Game.add_stat("market_visits", 1)
	Sfx.play("market_bell")
	_fountain.emitting = not Settings.reduced_motion
	_signature = ""
	_refresh()


func leave() -> void:
	visible = false
	_ui_layer.visible = false
	left_town.emit()


func _open(id: String) -> void:
	tab = id
	_panel.visible = true
	_signature = ""
	Sfx.play("click", -8.0)
	_refresh()


func _close_panel() -> void:
	tab = ""
	_panel.visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_pad_bar.visible = not Input.get_connected_joypads().is_empty()
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.3
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("close_panel"):
		# Escape closes an open window first, then leaves the town.
		if _panel.visible:
			_close_panel()
		else:
			leave()
		get_viewport().set_input_as_handled()


## Turns a point on the interface into the painting's pixels, to find which place in the town is under it.
func _spot_at(ui_point: Vector2) -> String:
	var picture := (ui_point * Windowing.ui_scale - _scene.position) / _scene.scale.x
	for spot in SPOTS:
		if Rect2(spot["rect"]).has_point(picture):
			return String(spot["id"])
	return ""


func _on_picture_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var spot := _spot_at(event.position)
		if spot != _hovered:
			_hovered = spot
			_props.queue_redraw()
		_hover_label.visible = spot != ""
		if spot != "":
			for s in SPOTS:
				if s["id"] == spot:
					_hover_label.text = "%s: %s" % [tr(String(s["name"])), tr(String(s["hint"]))]
			_hover_label.position = (event.position + Vector2(8, 10)).min(_ui_root.size - _hover_label.get_minimum_size() - Vector2(2, 2))
		_ui_root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if spot != "" else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var spot := _spot_at(event.position)
		if spot != "":
			_open(spot)
		elif _panel.visible:
			_close_panel()


## The notice board and the price slate stand in the square, and the place under the pointer is outlined.
func _draw_props() -> void:
	var wood := Color(0.45, 0.3, 0.19)
	var light := Color(0.6, 0.42, 0.27)
	# Notice board: a plank board on two posts, with a paper for each request waiting.
	_props.draw_rect(Rect2(86, 186, 2, 24), wood)
	_props.draw_rect(Rect2(106, 186, 2, 24), wood)
	_props.draw_rect(Rect2(84, 166, 26, 22), wood)
	_props.draw_rect(Rect2(85, 167, 24, 20), light)
	for i in Game.market.orders.size():
		var at := Vector2(87 + (i % 3) * 7, 169 + (i / 3) * 9)
		_props.draw_rect(Rect2(at, Vector2(6, 7)), Color(0.95, 0.91, 0.8))
		_props.draw_rect(Rect2(at + Vector2(2, 0), Vector2(2, 1)), Color(0.75, 0.2, 0.18))
		_props.draw_rect(Rect2(at + Vector2(1, 3), Vector2(4, 1)), Color(0.55, 0.45, 0.4))
	# Price slate: a dark board on a little easel, with chalk lines.
	_props.draw_rect(Rect2(382, 190, 1, 22), wood)
	_props.draw_rect(Rect2(395, 190, 1, 22), wood)
	_props.draw_rect(Rect2(380, 186, 18, 16), wood)
	_props.draw_rect(Rect2(381, 187, 16, 14), Color(0.2, 0.22, 0.2))
	for row in 4:
		_props.draw_rect(Rect2(383, 189 + row * 3, 7 + (row * 3) % 5, 1), Color(0.85, 0.85, 0.8))
	for spot in SPOTS:
		if spot["id"] == _hovered:
			_props.draw_rect(Rect2(spot["rect"]).grow(1), Color(1, 0.95, 0.75, 0.9), false, 1.0)


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


func _refresh() -> void:
	var festival: Dictionary = Game.calendar.festival()
	var day := tr("%s, day %d") % [tr(Game.calendar.season_name()), Game.calendar.day_of_season() + 1]
	if not festival.is_empty():
		day += "  -  " + tr(String(festival["name"]))
	_purse.text = "%s   %s" % [day, tr("Sestertii %d   Aurei %d") % [Game.coins, Game.aureus]]
	if tab == "":
		return
	var sig := "%s|%s|%s|%d|%d|%s|%s|%s|%s" % [tab, JSON.stringify(Game.storage), JSON.stringify(Game.market.orders), Game.coins, Game.aureus,
		JSON.stringify(Game.zones_owned), JSON.stringify(Game.decorations), JSON.stringify(Game.market.sold_today), Game.villa_stage]
	if sig == _signature:
		return
	_signature = sig
	_props.queue_redraw()
	for spot in SPOTS:
		if spot["id"] == tab:
			_title.text = tr(String(spot["name"]))
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
	UiKit.pad_focus.call_deferred(_panel)


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
