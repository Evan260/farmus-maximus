extends CanvasLayer
## The market town: a screen of its own over the estate. The painting itself is the menu: the stalls, the shop, the
## notice board, the price slate, the temple's land registry and the craftsman each open their own window when clicked.

signal left_town

const Walker := preload("res://scripts/world/walker.gd")
const DeedCard := preload("res://scripts/ui/deed_card.gd")
const BG := "res://assets/backgrounds/market/painting.png"
## The painting split into its sky, its clouds and the town in front, so the clouds can drift behind the rooftops.
const SKY_DIR := "res://assets/backgrounds/market/sky/"
const GRADIENT := preload("res://assets/shaders/sky_gradient.gdshader")
const CLOUD_TINT := preload("res://assets/shaders/cloud_tint.gdshader")
## The row where the town's sky meets the far hills behind the temple.
const TOWN_HORIZON := 95.0
## The places in the painting that can be clicked, in the painting's pixels.
const INK := Color8(42, 29, 41)
const WOOD_DARK := Color8(66, 40, 45)
const WOOD := Color8(104, 60, 46)
const WOOD_MID := Color8(125, 72, 47)
const WOOD_LIGHT := Color8(142, 83, 48)
const ROOF := Color8(170, 100, 53)
const ROOF_LIGHT := Color8(205, 118, 57)
const ROOF_DARK := Color8(125, 72, 47)
const SHADOW := Color(0.29, 0.16, 0.12, 0.35)
const PAPER := Color8(240, 222, 182)
const PAPER_SHADE := Color8(205, 178, 134)
const PAPER_INK := Color8(150, 118, 92)
const PIN := Color8(176, 52, 42)
const SLATE := Color8(47, 52, 52)
const SLATE_LIGHT := Color8(58, 64, 62)
const CHALK := Color8(222, 220, 206)
const CHALK_GOLD := Color8(230, 200, 112)
const CORD := Color8(96, 65, 62)
const FALL := Color(0.66, 0.78, 0.88, 0.85)
const FALL_SOFT := Color(0.66, 0.78, 0.88, 0.35)
const FOAM := Color8(232, 242, 248)
const GLINT := Color8(214, 230, 240)
const SPOTS := [
	{"id": "Stalls", "name": "Market stalls", "hint": "Sell your goods at full price", "rect": Rect2(105, 135, 110, 82)},
	{"id": "Shop", "name": "The shop", "hint": "Cuttings, materials and animals", "rect": Rect2(398, 118, 82, 145)},
	{"id": "Decorations", "name": "The craftsman", "hint": "Statues, lanterns and other decorations", "rect": Rect2(326, 140, 52, 62)},
	{"id": "Land", "name": "The temple", "hint": "Land deeds are kept here", "rect": Rect2(226, 55, 94, 115)},
	{"id": "Notice board", "name": "Notice board", "hint": "Requests from the townsfolk", "rect": Rect2(82, 163, 30, 54)},
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
var _clouds: Array[Sprite2D] = []
var _sky_layer: CanvasLayer
var _sky: Node2D
var _gradient: Sprite2D
var _sun: Sprite2D
var _cloud_look: ShaderMaterial
var _light: CanvasModulate
var _sky_time := 0.0
var _water: Node2D
var _water_time := 0.0
## The pixels of the painting that show water in the fountain.
var _water_mask := {}
var _bunting: Node2D
## The town's windows are drawn on their own layer at the interface's scale, over the town picture at the estate's.
var _ui_layer: CanvasLayer
var _ui_root: Control


func _ready() -> void:
	layer = 8
	visible = false
	_scene = Node2D.new()
	add_child(_scene)
	_build_sky()
	# The town is lit by the hour like the estate; the sky has its own layer underneath, so it is not dimmed twice.
	_light = CanvasModulate.new()
	add_child(_light)
	var front := Sprite2D.new()
	front.centered = false
	front.texture = load(SKY_DIR + "front.png")
	_scene.add_child(front)
	_water = Node2D.new()
	_water.draw.connect(_draw_water)
	_scene.add_child(_water)
	if ResourceLoader.exists(BG):
		var img := (load(BG) as Texture2D).get_image()
		for y in range(150, 210):
			for x in range(225, 320):
				var c := img.get_pixel(x, y)
				if c.b > c.r + 0.15 and c.b > 0.6:
					_water_mask[Vector2i(x, y)] = true
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
## The town's sky follows the estate's clock: the same banded colours, sun and stars, with the painting's own clouds
## drifting across it, lit for the hour.
func _build_sky() -> void:
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = 7
	_sky_layer.visible = false
	add_child(_sky_layer)
	_sky = Node2D.new()
	_sky_layer.add_child(_sky)
	_gradient = Sprite2D.new()
	var white := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	_gradient.texture = ImageTexture.create_from_image(white)
	_gradient.centered = false
	_gradient.scale = Vector2(480, TOWN_HORIZON + 40)
	var paint := ShaderMaterial.new()
	paint.shader = GRADIENT
	paint.set_shader_parameter("area", _gradient.scale)
	paint.set_shader_parameter("origin", Vector2.ZERO)
	paint.set_shader_parameter("top", -20.0)
	paint.set_shader_parameter("horizon", TOWN_HORIZON)
	paint.set_shader_parameter("bands", 7.0)
	_gradient.material = paint
	_sky.add_child(_gradient)
	_sun = Sprite2D.new()
	_sun.texture = Lighting.ellipse_texture(15, 15, Color.WHITE)
	_sky.add_child(_sun)
	_cloud_look = ShaderMaterial.new()
	_cloud_look.shader = CLOUD_TINT
	var list: Array = JSON.parse_string(FileAccess.get_file_as_string(SKY_DIR + "clouds.json"))
	for c in list:
		var cloud := Sprite2D.new()
		cloud.centered = false
		cloud.texture = load(SKY_DIR + String(c["file"]))
		cloud.position = Vector2(float(c["x"]), float(c["y"]))
		cloud.material = _cloud_look
		cloud.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# High clouds drift a little faster than low ones, and pieces of one cloud share a band so they keep together.
		cloud.set_meta("speed", 1.6 if float(c["y"]) < 40.0 else 1.0)
		_sky.add_child(cloud)
		_clouds.append(cloud)


func _light_town(delta: float) -> void:
	var hour := Game.day_time
	var overcast: bool = Game.calendar.weather in ["cloudy", "rain"]
	var look := SkyPalette.at(hour, overcast)
	var paint := _gradient.material as ShaderMaterial
	for key in ["zenith", "middle", "low", "glow"]:
		paint.set_shader_parameter(key, look[key])
	var sun := SkyPalette.sun_position(hour, 480.0, TOWN_HORIZON, 75.0)
	_sun.visible = not is_nan(sun.x)
	if _sun.visible:
		_sun.position = sun.round()
		var height := clampf((TOWN_HORIZON - sun.y) / 75.0, 0.0, 1.0)
		_sun.modulate = Color(1.0, 0.72, 0.45).lerp(Color(1.0, 0.98, 0.9), height)
		paint.set_shader_parameter("sun", sun)
		paint.set_shader_parameter("glow_radius", lerpf(140.0, 80.0, height))
	paint.set_shader_parameter("stars", Lighting.night_amount(hour))
	_sky_time += delta
	paint.set_shader_parameter("time", _sky_time)
	_cloud_look.set_shader_parameter("light", look["light"])
	_cloud_look.set_shader_parameter("shade", look["shade"])
	var light := Lighting.color_at(hour)
	_light.color = light.darkened(0.12) if overcast else light


func _drift_clouds(delta: float) -> void:
	if Settings.reduced_motion:
		return
	for cloud in _clouds:
		cloud.position.x += float(cloud.get_meta("speed")) * delta
		if cloud.position.x > 480.0:
			cloud.position.x = -cloud.texture.get_width()


func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var cover := ceili(maxf(view.x / 480.0, view.y / 272.0))
	_scene.scale = Vector2(cover, cover)
	_scene.position = ((view - Vector2(480, 272) * cover) / 2.0).round()
	_sky.scale = _scene.scale
	_sky.position = _scene.position
	_ui_layer.scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_ui_root.size = (view / Windowing.ui_scale).floor()
	_pad_bar.position = Vector2(4, _ui_root.size.y - 18)


func enter() -> void:
	visible = true
	_ui_layer.visible = true
	_sky_layer.visible = true
	tab = ""
	_panel.visible = false
	_bunting.queue_redraw()
	_props.queue_redraw()
	Game.add_stat("market_visits", 1)
	Sfx.play("market_bell")
	_signature = ""
	_refresh()


func leave() -> void:
	visible = false
	_ui_layer.visible = false
	_sky_layer.visible = false
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
	_water_time += delta
	_water.queue_redraw()
	_drift_clouds(delta)
	_light_town(delta)
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
	_draw_notice_board()
	_draw_slate()
	for spot in SPOTS:
		if spot["id"] == _hovered:
			UiKit.outline(_props, Rect2(spot["rect"]), Color(1, 0.95, 0.75, 0.9))


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	_props.draw_rect(Rect2(x, y, w, h), c)


## A plank board on two posts under a little tiled roof, with a paper pinned up for each request waiting.
func _draw_notice_board() -> void:
	# The posts stand on the step in front of the colonnade, a few rows below the board.
	_px(84, 216, 28, 1, SHADOW)
	_px(82, 217, 32, 1, SHADOW)
	for x in [87, 104]:
		_px(x, 186, 1, 31, WOOD_LIGHT)
		_px(x + 1, 186, 1, 31, WOOD)
		_px(x + 2, 186, 1, 31, WOOD_DARK)
		_px(x, 216, 3, 1, INK)
	_px(84, 166, 26, 21, INK)
	_px(85, 167, 24, 19, WOOD)
	for y in [167, 173, 179]:
		_px(85, y, 24, 1, WOOD_MID)
	for y in [172, 178]:
		_px(85, y, 24, 1, WOOD_DARK)
	for g in [[88, 169, 3], [97, 170, 2], [103, 175, 3], [90, 176, 2], [92, 182, 2], [100, 183, 3]]:
		_px(g[0], g[1], g[2], 1, WOOD_DARK)
	_px(82, 164, 30, 2, ROOF_DARK)
	_px(83, 163, 28, 1, ROOF_LIGHT)
	for x in range(84, 111, 3):
		_px(x, 164, 1, 1, ROOF)
	_px(82, 166, 30, 1, INK)
	for i in Game.market.orders.size():
		var at := Vector2(87 + (i % 3) * 7, 168 + (i / 3) * 9)
		_px(at.x, at.y, 6, 7, PAPER)
		_px(at.x + 5, at.y + 1, 1, 6, PAPER_SHADE)
		_px(at.x, at.y + 6, 5, 1, PAPER_SHADE)
		_px(at.x + 1, at.y + 2, 4, 1, PAPER_INK)
		_px(at.x + 1, at.y + 4, 3, 1, PAPER_INK)
		_px(at.x + 2, at.y, 2, 1, PIN)


## A framed slate on an easel, chalked with the day's prices.
func _draw_slate() -> void:
	_px(379, 211, 21, 1, SHADOW)
	for i in 21:
		_px(382 - i / 8, 191 + i, 2, 1, WOOD_LIGHT if i % 2 == 0 else WOOD_MID)
		_px(395 + i / 8, 191 + i, 2, 1, WOOD_MID if i % 2 == 0 else WOOD_DARK)
	_px(389, 200, 1, 11, WOOD_DARK)
	_px(380, 187, 18, 15, INK)
	_px(381, 188, 16, 13, WOOD_MID)
	_px(381, 188, 16, 1, WOOD_LIGHT)
	_px(382, 189, 14, 11, SLATE)
	for d in [[384, 192], [391, 195], [386, 198], [394, 190]]:
		_px(d[0], d[1], 1, 1, SLATE_LIGHT)
	for row in [[191, 4, 2], [194, 3, 4], [197, 5, 2]]:
		_px(383, row[0], row[1], 1, CHALK)
		_px(384 + row[1], row[0], row[2], 1, CHALK.darkened(0.15))
		_px(393, row[0], 2, 1, CHALK_GOLD)
	_px(380, 201, 18, 1, WOOD_DARK)


## During a festival flags are strung between the rooftops across the square.
func _draw_bunting() -> void:
	if Game.calendar.festival().is_empty():
		return
	var colours := [Color8(176, 58, 46), Color8(222, 178, 82), Color8(92, 128, 70), Color8(122, 82, 140)]
	var strings := [[Vector2(106, 103), Vector2(410, 101), 9.0], [Vector2(150, 119), Vector2(378, 121), 12.0]]
	for line in strings.size():
		var from: Vector2 = strings[line][0]
		var to: Vector2 = strings[line][1]
		for x in range(int(from.x), int(to.x) + 1):
			var k := (x - from.x) / (to.x - from.x)
			var y := roundf(lerpf(from.y, to.y, k) + sin(k * PI) * float(strings[line][2]))
			_bunting.draw_rect(Rect2(x, y, 1, 1), CORD)
			var flag := x - int(from.x)
			if flag % 8 != 3 or x + 5 > int(to.x):
				continue
			var c: Color = colours[(flag / 8 + line) % colours.size()]
			for r in 6:
				var w := 5 - int(r * 0.85)
				var left := x + (5 - w) / 2
				_bunting.draw_rect(Rect2(left, y + 1 + r, w, 1), c)
				_bunting.draw_rect(Rect2(left, y + 1 + r, 1, 1), c.lightened(0.22))
				if w > 2:
					_bunting.draw_rect(Rect2(left + w - 1, y + 1 + r, 1, 1), c.darkened(0.28))


## The fountain's water: a little jet on top falling into the bowl, streams spilling from the bowl's lip into the basin,
## splashes and spreading ripples where they land, and glints drifting across both pools.
func _draw_water() -> void:
	var t := 0.0 if Settings.reduced_motion else floorf(_water_time * 10.0)
	for k in 4:
		var s := fposmod(k * 0.25 + t * 0.07, 1.0)
		for side in [-1.0, 1.0]:
			var at := Vector2(roundf(272 + side * 8.0 * s), roundf(159 - 4.0 * s + 15.0 * s * s))
			_water.draw_rect(Rect2(at, Vector2.ONE), FOAM if k % 2 == 0 else FALL)
	_water.draw_rect(Rect2(271, 158 - int(t) % 2, 2, 1), FOAM)
	for side in [-1, 1]:
		var top_x: int = 252 if side < 0 else 291
		var land := 0
		# Water leaving the lip moves outwards fastest at first, then falls nearly straight down.
		for y in range(174, 200):
			var x: int = top_x + side * int(roundf(0.8 * sqrt(y - 174)))
			land = x
			_water.draw_rect(Rect2(x, y, 1, 1), FOAM if posmod(y - int(t), 5) == 0 else FALL)
			_water.draw_rect(Rect2(x - side, y, 1, 1), FALL_SOFT)
		_water.draw_rect(Rect2(land - 1 + 2 * (int(t) % 2), 199, 1, 1), FOAM)
		_water.draw_rect(Rect2(land, 198 - int(t) % 2, 1, 1), FALL)
		for ring in 2:
			var r: int = posmod(int(t / 2.0) + ring * 4, 8) + 1
			var fade := 1.0 - r / 9.0
			for dx in [-r, r]:
				_water_pixel(land + dx, 200 + ring, Color(FOAM, 0.75 * fade))
	for k in 3:
		_water_pixel(258 + posmod(int(t * 0.3) + k * 10, 29), 171, GLINT)
	for k in 5:
		_water_pixel(238 + posmod(int(t * 0.4) + k * 14, 70), 199 + k % 2 * 2, GLINT)


## Draws on the water only, so ripples and glints never spill onto the stone around it.
func _water_pixel(x: int, y: int, c: Color) -> void:
	if _water_mask.has(Vector2i(x, y)):
		_water.draw_rect(Rect2(x, y, 1, 1), c)


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
	sig += JSON.stringify(Game.buildings["barn"]["animals"]) if Game.buildings.has("barn") else ""
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
		var owned := _owned_text(entry)
		if owned != "":
			var have := UiKit.label(r, owned)
			have.custom_minimum_size = Vector2(62, 0)
			have.add_theme_color_override("font_color", UiKit.FADED)
		if block != "":
			UiKit.label(r, tr(block)).add_theme_color_override("font_color", UiKit.FADED)
			continue
		var buy := UiKit.button(r, tr("Buy"), func(): if Game.market.buy(String(entry["id"])): Sfx.play("coins"))
		buy.disabled = Game.missing(price) != ""
		if entry.has("item"):
			var five := UiKit.button(r, tr("Buy 5"), func(): if Game.market.buy(String(entry["id"]), 5): Sfx.play("coins"))
			five.disabled = Game.missing({"coins": int(entry["price"]) * 5}) != ""


## How much of a shop entry the farm already has, so the player knows before buying more.
func _owned_text(entry: Dictionary) -> String:
	if entry.has("item"):
		return tr("You have %d") % Game.count_item(String(entry["item"]))
	if entry.has("animal") and Game.buildings.has("barn"):
		var kind := String(entry["animal"])
		return tr("You have %d / %d") % [int(Game.buildings["barn"]["animals"].get(kind, 0)), Game.animal_capacity(kind)]
	if entry.has("gives_coins"):
		return tr("You have %d") % Game.aureus
	return ""


## The temple's land registry: a deed for every part of the estate, sealed for the land that is already the family's.
func _build_land() -> void:
	var owned := Game.zones().filter(func(z): return Game.zone_owned(String(z["id"]))).size()
	UiKit.label(_list, tr("Your land: %d of %d") % [owned, Game.zones().size()])
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_list.add_child(grid)
	for z in Game.zones():
		var id := String(z["id"])
		var col := UiKit.column(grid)
		var deed := DeedCard.new()
		deed.title = tr(String(z["name"]))
		deed.price = int(z.get("deed", 0))
		deed.state = "owned" if Game.zone_owned(id) else ("sale" if Game.zone_block(id) == "" else "later")
		col.add_child(deed)
		if deed.state == "sale":
			var b := UiKit.button(col, tr("Buy"), func(): Game.buy_zone(id))
			b.disabled = Game.coins < deed.price


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
