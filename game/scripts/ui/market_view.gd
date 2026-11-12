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
const BANNER := Color8(160, 36, 32)
## Three-by-five letters for the banners.
const LETTERS := {"S": ["###", "#..", "###", "..#", "###"], "P": ["###", "#.#", "###", "#..", "#.."], "Q": ["###", "#.#", "#.#", "###", "..#"], "R": ["##.", "#.#", "##.", "#.#", "#.#"]}
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
## Set when the window crops a place out of the town picture.
var _places_cut_off := false
var _back: Button
## The place last opened, whose button in the pad bar takes the focus back when its window closes.
var _visited := ""
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
## The banners in the temple, redrawn as they stir.
var _banners: Node2D
## While a banner is drawn, the row its pole hangs from and where it hangs, so its cloth can sway; -1 otherwise.
var _cloth_top := -1
var _cloth_x := 0
## The young woman of the town, who in time is expecting a child and then carries her baby about the square.
var _woman: Node2D
## The townsfolk walking the square, who greet the player when clicked.
var _folk: Array = []
var _woman_look := ""
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
	# The cypresses stand apart from the town picture, so they can lean in the wind like the trees on the estate.
	if FileAccess.file_exists(SKY_DIR + "trees.json"):
		front.texture = load(SKY_DIR + "front_still.png")
		for t in JSON.parse_string(FileAccess.get_file_as_string(SKY_DIR + "trees.json")):
			var tree := Sprite2D.new()
			tree.centered = false
			tree.texture = load(SKY_DIR + String(t["file"]))
			tree.position = Vector2(float(t["x"]), float(t["y"]))
			var sway := ShaderMaterial.new()
			sway.shader = preload("res://assets/shaders/sway.gdshader")
			sway.set_shader_parameter("height", float(tree.texture.get_height()))
			sway.set_shader_parameter("strength", 0.0 if Settings.reduced_motion else 1.0)
			tree.material = sway
			_scene.add_child(tree)
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
	_banners = Node2D.new()
	_banners.draw.connect(_draw_banners)
	_scene.add_child(_banners)
	for who in ["townsman", "townswoman", "traveller", "shepherd"]:
		var dir := "res://assets/sprites/people/town/%s/" % who
		if not ResourceLoader.exists(dir + "east.png"):
			continue
		var w := Walker.new()
		w.dir = dir
		w.min_x = 20
		w.max_x = 460
		w.position = Vector2(randf_range(40, 440), 262 + randi() % 6)
		# Townsfolk go indoors for the night through one of the doorways on the square.
		w.rests_at_night = true
		w.home_x = [120.0, 360.0][randi() % 2]
		w.react_folder = "greet"
		w.display_name = tr({"townsman": "A townsman", "townswoman": "A townswoman", "traveller": "A traveller", "shepherd": "A shepherd"}[who])
		w.voice = "salve_woman" if who == "townswoman" else "salve_man"
		w.sayings = who
		_scene.add_child(w)
		_folk.append(w)
		if who == "townswoman":
			_woman = w
	_bunting = Node2D.new()
	_bunting.draw.connect(_draw_bunting)
	_scene.add_child(_bunting)

	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 9
	_ui_layer.visible = false
	add_child(_ui_layer)
	_ui_root = Control.new()
	_ui_root.theme = UiTheme.build()
	# The whole screen listens for clicks on the painting; the windows on top take their own clicks first.
	_ui_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.gui_input.connect(_on_picture_input)
	_ui_layer.add_child(_ui_root)
	var top := Ui.row(_ui_root)
	top.position = Vector2(4, 4)
	_back = Ui.button(top, tr("Back to the estate"), leave)
	var purse_box := PanelContainer.new()
	top.add_child(purse_box)
	_purse = Ui.label(purse_box)
	_hover_label = Ui.label(_ui_root, "", true)
	_hover_label.visible = false
	_panel = PanelContainer.new()
	_panel.visible = false
	_ui_root.add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var col := Ui.column(_panel)
	col.custom_minimum_size = Vector2(310, 0)
	var head := Ui.row(col)
	_title = Ui.label(head)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ui.close_button(head, _close_panel)
	_list = Ui.scroll(col, Vector2(300, 160))
	# A gamepad cannot point at the painting, so it gets a row of the same places along the bottom.
	_pad_bar = Ui.row(_ui_root)
	for spot in SPOTS:
		Ui.button(_pad_bar, tr(String(spot["name"])), func(): _open(String(spot["id"])))
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
	paint.set_shader_parameter("bands", 14.0)
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
		# High clouds drift faster than low ones, and pieces in the same stretch of sky move alike so one cloud keeps together.
		var high := float(c["y"]) < 40.0
		var group := RandomNumberGenerator.new()
		group.seed = int(c["x"]) / 150 * 2 + (1 if high else 0)
		cloud.set_meta("speed", (1.6 if high else 1.0) * group.randf_range(0.8, 1.25))
		cloud.set_meta("base_y", float(c["y"]))
		cloud.set_meta("phase", group.randf() * TAU)
		_sky.add_child(cloud)
		_clouds.append(cloud)


func _dress_woman() -> void:
	if _woman == null or _woman.sprite == null:
		return
	var story := Game.baby_story()
	var bump := int(roundf(float(story.get("share", 0.0)) * 4.0)) if story["stage"] == "expecting" else 0
	var look := "%s%d" % [story["stage"], bump]
	if look == _woman_look:
		return
	_woman_look = look
	_woman.walk_folder = "baby" if story["stage"] == "baby" else "walk"
	_woman.dress = (func(tex: Texture2D) -> Texture2D: return Belly.round_out(tex, roundi(bump * 4.0 / 3.0))) if bump > 0 else Callable()
	_woman.refresh_frames()


func _light_town(delta: float) -> void:
	var hour := Game.day_time
	var overcast: bool = Game.calendar.weather in ["cloudy", "rain"]
	_sky_time += delta
	SkyPalette.paint(_gradient.material as ShaderMaterial, _sun, _cloud_look, hour, overcast, 480.0, TOWN_HORIZON, 75.0, Vector2(140, 80), _sky_time)
	if _banners:
		_banners.queue_redraw()
	var light := Lighting.color_at(hour)
	_light.color = light.darkened(0.12) if overcast else light


func _drift_clouds(delta: float) -> void:
	if Settings.reduced_motion:
		return
	for cloud in _clouds:
		cloud.position.x += float(cloud.get_meta("speed")) * delta
		# Clouds rise and sink a few pixels over a couple of minutes while they drift.
		cloud.position.y = float(cloud.get_meta("base_y")) + 3.0 * sin(_sky_time * TAU / 140.0 + float(cloud.get_meta("phase")))
		if cloud.position.x > 480.0:
			cloud.position.x = -cloud.texture.get_width()


func _fit(view := Vector2.ZERO) -> void:
	if view == Vector2.ZERO:
		view = get_viewport().get_visible_rect().size
	var cover := ceili(maxf(view.x / 480.0, view.y / 272.0))
	_scene.scale = Vector2(cover, cover)
	_scene.position = ((view - Vector2(480, 272) * cover) / 2.0).round()
	_sky.scale = _scene.scale
	_sky.position = _scene.position
	_ui_layer.scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_ui_root.size = (view / Windowing.ui_scale).floor()
	_pad_bar.position = Vector2(4, _ui_root.size.y - 18)
	var shown := Rect2(-_scene.position / cover, view / cover)
	_places_cut_off = SPOTS.any(func(spot) -> bool: return not shown.encloses(Rect2(spot["rect"])))


func enter() -> void:
	visible = true
	_ui_layer.visible = true
	_sky_layer.visible = true
	tab = ""
	_visited = ""
	_panel.visible = false
	_bunting.queue_redraw()
	_props.queue_redraw()
	Game.add_stat("market_visits", 1)
	Game.market.pack_cart()
	Audio.play("market_bell")
	_signature = ""
	_refresh()


func leave() -> void:
	Game.market.unpack_cart()
	Dissolve.play(self, func() -> void:
		visible = false
		_ui_layer.visible = false
		_sky_layer.visible = false
		left_town.emit())


func _open(id: String) -> void:
	tab = id
	_visited = id
	if not _panel.visible:
		Ui.fade_in(_panel)
	_signature = ""
	Audio.play("click", -8.0)
	_refresh()


func _close_panel() -> void:
	tab = ""
	_panel.visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	var pad := KeyNav.active()
	# A window narrower than the town hides some places, so the row of them is offered to the mouse too.
	_pad_bar.visible = pad or _places_cut_off
	if pad:
		_keep_pad_focus()
	_water_time += delta
	_water.queue_redraw()
	_drift_clouds(delta)
	_light_town(delta)
	_dress_woman()
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.3
		_refresh()


## A gamepad always has a button to act on: the open window's, or else the place last visited in the bar below.
func _keep_pad_focus() -> void:
	_back.focus_mode = Control.FOCUS_ALL
	for b in _pad_bar.get_children():
		b.focus_mode = Control.FOCUS_ALL
	if get_viewport().gui_get_focus_owner() != null:
		return
	if _panel.visible:
		Ui.pad_focus(_panel)
		return
	var at := 0
	for i in SPOTS.size():
		if SPOTS[i]["id"] == _visited:
			at = i
	(_pad_bar.get_child(at) as Button).grab_focus()


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


## The townsperson under the pointer, if any.
func _folk_at(ui_point: Vector2) -> Node2D:
	var picture := (ui_point * Windowing.ui_scale - _scene.position) / _scene.scale.x
	return Hit.front_most(_folk.filter(func(w): return w.contains(picture)), picture)


func _on_picture_input(event: InputEvent) -> void:
	var person := _folk_at(event.position) if event is InputEventMouse else null
	if person and event is InputEventMouseMotion:
		_hovered = ""
		_props.queue_redraw()
		_hover_label.visible = true
		_hover_label.text = person.display_name
		_hover_label.position = (event.position + Vector2(8, 10)).min(_ui_root.size - _hover_label.get_minimum_size() - Vector2(2, 2))
		_ui_root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		return
	if person and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		person.greet()
		var head := func() -> Vector2:
			var at: Vector2 = person.position if is_instance_valid(person) else Vector2.INF
			return ((at + Vector2(0, -46)) * _scene.scale.x + _scene.position) / Windowing.ui_scale
		Ui.speech(_ui_root, head.call(), person.saying(), head)
		return
	if event is InputEventMouseMotion:
		var spot := _spot_at(event.position)
		if spot != _hovered:
			_hovered = spot
			_props.queue_redraw()
		_hover_label.visible = spot != ""
		if spot != "":
			for s in SPOTS:
				if s["id"] == spot:
					_hover_label.text = tr("%s: %s") % [tr(String(s["name"])), tr(String(s["hint"]))]
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
			Ui.outline(_props, Rect2(spot["rect"]), Color(1, 0.95, 0.75, 0.9))


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	if _cloth_top < 0:
		_props.draw_rect(Rect2(x, y, w, h), c)
		return
	# Cloth hanging from the pole sways more the further down it hangs, a pixel at most, row by row.
	for yy in range(int(y), int(y + h)):
		var down := float(yy - _cloth_top) / 22.0
		var dx := roundf(sin(_sky_time * 1.4 + yy * 0.25 + _cloth_x * 0.1) * down * 1.3) if not Settings.reduced_motion else 0.0
		_banners.draw_rect(Rect2(x + dx, yy, w, 1), c)


## The two banners on the temple, redrawn as they stir in the breeze.
func _draw_banners() -> void:
	for x in [244, 295]:
		_cloth_top = 92
		_cloth_x = x
		_draw_banner(x, 92)
	_cloth_top = -1


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


## A red banner of the Senate and People of Rome hung between the temple's columns, lettered in gold.
func _draw_banner(x: int, y: int) -> void:
	_px(x - 1, y, 11, 1, CHALK_GOLD.darkened(0.25))
	_px(x - 2, y, 1, 1, CHALK_GOLD)
	_px(x + 10, y, 1, 1, CHALK_GOLD)
	_px(x, y + 1, 9, 18, BANNER)
	_px(x + 8, y + 1, 1, 18, BANNER.darkened(0.25))
	_px(x, y + 1, 9, 1, BANNER.lightened(0.15))
	# The bottom is cut in a notch, so it hangs in two points.
	for i in 4:
		_px(x + i, y + 19 + i / 2, 1, 1, BANNER)
		_px(x + 8 - i, y + 19 + i / 2, 1, 1, BANNER.darkened(0.25))
	for row in [["SP", 4], ["QR", 10]]:
		for k in 2:
			_letter(String(row[0])[k], x + 1 + k * 4, y + int(row[1]))


func _letter(ch: String, x: int, y: int) -> void:
	var rows: Array = LETTERS[ch]
	for r in rows.size():
		for c in 3:
			if String(rows[r])[c] == "#":
				_px(x + c, y + r, 1, 1, CHALK_GOLD)


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
	var focus := Ui.focus_hint(_panel)
	Ui.clear(_list)
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
	# Through the market rather than Ui, so a call left over when the scene is rebuilt is simply skipped.
	(func(): Ui.pad_focus(_panel, focus)).call_deferred()


func _build_stalls() -> void:
	var keys: Array = Game.market.brought.keys().filter(func(k): return int(Game.market.brought[k]) > 0 and int(Game.storage.get(k, 0)) > 0)
	keys.sort_custom(func(a, b): return Game.market.price(a) > Game.market.price(b))
	Ui.para(_list, tr("The cart brought %d goods; it carries %d. It takes the goods marked for sale in the storehouse, the best paid first.") % [Game.market.brought_total(), Game.cart_capacity()], 280).add_theme_color_override("font_color", UiTheme.MUTED)
	if keys.is_empty():
		Ui.para(_list, tr("Nothing left to sell from the cart. Goods sold here fetch the full price, without the trader's cut."), 280)
	for key in keys:
		var r := Ui.row(_list)
		Ui.icon(r, key)
		var l := Ui.label(r, "%s x%d  -  %d" % [tr(Game.item_name(key)), mini(int(Game.market.brought[key]), int(Game.storage[key])), Game.market.price(key)])
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Ui.button(r, tr("Sell 1"), func(): _sell(key, 1))
		Ui.button(r, tr("Sell all"), func(): _sell(key, int(Game.market.brought.get(key, 0))))


func _sell(key: String, n: int) -> void:
	var coins: int = Game.market.sell(key, n)
	if coins > 0:
		Audio.play("coins")


func _build_orders() -> void:
	if Game.market.orders.is_empty():
		Ui.para(_list, tr("No requests today. New ones are pinned up through the day."), 280)
	for i in Game.market.orders.size():
		if i > 0:
			Ui.divider(_list)
		var o: Dictionary = Game.market.orders[i]
		var box := Ui.column(_list)
		Ui.para(box, tr("%s (%s): \"%s\"") % [tr(String(o["who"])), Ui.mid(tr(String(o["role"]))), tr(String(o["text"]))], 280)
		var r := Ui.row(box)
		Ui.icon(r, String(o["item"]))
		Ui.label(r, _reward_text(int(o["coins"]), int(o["aureus"]) > 0, String(o.get("seed", "")) != "", Game.count_item(String(o["item"]))))
		var b := Ui.button(r, tr("Deliver"), func(): _deliver(o))
		b.disabled = not Game.market.can_deliver(i)


## What a request pays and how many of the goods the farm has, as one whole sentence in every language.
static func _reward_text(coins: int, aureus: bool, seed: bool, have: int) -> String:
	if aureus and seed:
		return TranslationServer.translate("Pays %d sestertii, a gold aureus and a rare seed (you have %d)") % [coins, have]
	if aureus:
		return TranslationServer.translate("Pays %d sestertii and a gold aureus (you have %d)") % [coins, have]
	if seed:
		return TranslationServer.translate("Pays %d sestertii and a rare seed (you have %d)") % [coins, have]
	return TranslationServer.translate("Pays %d sestertii (you have %d)") % [coins, have]


## Delivers that very order: the ones after it move up the board as soon as one is delivered.
func _deliver(order: Dictionary) -> void:
	for i in Game.market.orders.size():
		if is_same(Game.market.orders[i], order):
			if Game.market.deliver(i):
				Audio.play("coins")
			return


func _build_prices() -> void:
	var festival: Dictionary = Game.calendar.festival()
	if not festival.is_empty():
		Ui.para(_list, tr("%s: %s") % [tr(String(festival["name"])), tr(String(festival.get("about", "")))], 280)
	var fav := []
	for item in Game.market.favourites:
		fav.append(Ui.mid(tr(String(Data.get_value("items.%s.name" % item, item)))))
	Ui.para(_list, tr("Wanted today: %s") % ", ".join(fav), 280)
	Ui.para(_list, tr("Selling many of one good lowers its price until tomorrow, so a mix pays best."), 280).add_theme_color_override("font_color", UiTheme.MUTED)
	for item in Data.get_value("items", {}):
		if Data.get_value("items.%s.kind" % item, "good") != "good" or not Game.journal.has("item:" + item):
			continue
		var r := Ui.row(_list)
		Ui.icon(r, item)
		Ui.label(r, "%s: %d  (%s %d)" % [tr(String(Data.get_value("items.%s.name" % item, item))), Game.market.price(item), tr("cart"), Game.market.cart_price(item)])


func _build_shop() -> void:
	for entry in Game.market.catalog():
		var block: String = Game.market.catalog_block(entry)
		if block == "Bought":
			continue
		var r := Ui.row(_list)
		if entry.has("item"):
			Ui.icon(r, String(entry["item"]))
		var price := {"coins": int(entry.get("price", 0)), "aureus": int(entry.get("aureus", 0))}
		var l := Ui.para(r, "%s  -  %s" % [tr(String(entry["name"])), Ui.cost_text(price)], 170)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var owned := _owned_text(entry)
		if owned != "":
			var have := Ui.label(r, owned)
			have.custom_minimum_size = Vector2(62, 0)
			have.add_theme_color_override("font_color", UiTheme.MUTED)
		if block != "":
			Ui.label(r, tr(block)).add_theme_color_override("font_color", UiTheme.MUTED)
			continue
		var buy := Ui.button(r, tr("Buy"), func(): if Game.market.buy(String(entry["id"])): Audio.play("coins"))
		buy.disabled = Game.missing(price) != ""
		if entry.has("item"):
			var five := Ui.button(r, tr("Buy 5"), func(): if Game.market.buy(String(entry["id"]), 5): Audio.play("coins"))
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
	Ui.label(_list, tr("Your land: %d of %d") % [owned, Game.zones().size()])
	# Three deeds to a row, with a shorter last row centred under the others.
	var grid := HFlowContainer.new()
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	grid.custom_minimum_size.x = DeedCard.SIZE.x * 3 + 12
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_list.add_child(grid)
	for z in Game.zones():
		var id := String(z["id"])
		var col := Ui.column(grid)
		var deed := DeedCard.new()
		deed.title = tr(String(z["name"]))
		deed.price = int(z.get("deed", 0))
		deed.state = _deed_state(id)
		col.add_child(deed)
		if deed.state == "sale":
			var b := Ui.button(col, tr("Buy"), func(): Game.buy_zone(id))
			b.disabled = Game.coins < deed.price


func _deed_state(id: String) -> String:
	if Game.zone_owned(id):
		return "owned"
	if Game.zone_in_full_game(id):
		return "full"
	return "sale" if Game.zone_block(id) == "" else "later"


func _build_decorations() -> void:
	for id in Data.get_value("decorations", {}):
		var d: Dictionary = Game.decoration_info(id)
		var r := Ui.row(_list)
		var tex := "res://assets/sprites/decorations/%s.png" % id
		if ResourceLoader.exists(tex):
			var t := TextureRect.new()
			t.texture = load(tex)
			t.custom_minimum_size = Vector2(16, 16)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.add_child(t)
		var price := {"coins": int(d.get("price", 0)), "aureus": int(d.get("aureus", 0))}
		var l := Ui.label(r, "%s  -  %s" % [tr(String(d["name"])), Ui.cost_text(price)])
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var block: String = Game.decoration_block(id)
		if block != "":
			Ui.label(r, tr(block)).add_theme_color_override("font_color", UiTheme.MUTED)
		else:
			var b := Ui.button(r, tr("Buy"), func(): if Game.buy_decoration(id): Audio.play("coins"))
			b.disabled = Game.missing(price) != ""
