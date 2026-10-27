extends CanvasLayer
## Inside the farmhouse: a room of its own over the estate, like the market town. While the house is a ruin it is an
## empty shell open to the sky; once restored it is a bare room that the player furnishes piece by piece, each bought
## furnishing painted into place. The fire flickers, the lamps glow at night, the pool shimmers, the view through the
## doorway darkens with the hour, and the player's own dog and cat nap on the rug and the couch.

signal left_house

const DIR := "res://assets/backgrounds/interior/"
## Where the outdoors shows through, in the room's pixels: the doorway, and in the ruin the hole in the roof too.
const OUTSIDE := [Rect2(367, 20, 64, 108)]
const RUIN_OUTSIDE := [Rect2(400, 70, 55, 128), Rect2(272, 0, 64, 22)]
const FIRE_GLOW := Vector2(101, 140)
const LAMP_FLAMES := [Vector2(70, 49), Vector2(132, 53), Vector2(20, 119), Vector2(305, 102)]
## The pool's surface, as a shape the shimmer stays inside.
const POOL := [Vector2(196, 196), Vector2(228, 182), Vector2(320, 182), Vector2(344, 200), Vector2(300, 228), Vector2(210, 228)]
const NIGHT_SKY := Color8(14, 18, 44)
const MARK := Color(1, 0.95, 0.75)

var _scene: Node2D
var _base: Sprite2D
var _light: CanvasModulate
var _glow_layer: CanvasLayer
var _glow: Node2D
var _sprites := {}
var _marks: Node2D
var _dog: AnimatedSprite2D
var _dog_shadow: Sprite2D
var _cat_shadow: Sprite2D
var _cat: AnimatedSprite2D
var _ui_layer: CanvasLayer
var _ui_root: Control
var _purse: Label
var _comfort: Label
var _hover_label: Label
var _panel: PanelContainer
var _title: Label
var _list: VBoxContainer
var _scroll: Node
var _hovered := ""
var _selected := ""
var _signature := ""
var _t := 0.0
var _spots: Dictionary = {}


func _ready() -> void:
	layer = 8
	visible = false
	_spots = JSON.parse_string(FileAccess.get_file_as_string(DIR + "furnishings.json")) if FileAccess.file_exists(DIR + "furnishings.json") else {}
	_scene = Node2D.new()
	add_child(_scene)
	_light = CanvasModulate.new()
	add_child(_light)
	_base = Sprite2D.new()
	_base.centered = false
	_scene.add_child(_base)
	for id in Balance.get_value("interior.furnishings", {}):
		if not _spots.has(id) or not ResourceLoader.exists(DIR + id + ".png"):
			continue
		var s := Sprite2D.new()
		s.centered = false
		s.texture = load(DIR + id + ".png")
		s.position = Vector2(_spots[id][0], _spots[id][1])
		s.visible = false
		_scene.add_child(s)
		_sprites[id] = s
	# A soft shadow and a thin dark outline keep each pet from melting into the rug or the cushions it lies on.
	var outline := ShaderMaterial.new()
	outline.shader = preload("res://assets/shaders/outline.gdshader")
	_dog_shadow = _shadow(Vector2(104, 239), 42, 9)
	_dog = AnimatedSprite2D.new()
	_dog.centered = false
	_dog.material = outline
	_scene.add_child(_dog)
	_cat_shadow = _shadow(Vector2(282, 115), 22, 6)
	_cat = AnimatedSprite2D.new()
	_cat.centered = false
	_cat.material = outline
	_scene.add_child(_cat)
	_marks = Node2D.new()
	_marks.draw.connect(_draw_marks)
	_scene.add_child(_marks)
	# Fire, lamplight and stars are added on their own layer, so the room's dimming at night does not dim them too.
	_glow_layer = CanvasLayer.new()
	_glow_layer.layer = 9
	_glow_layer.visible = false
	add_child(_glow_layer)
	_glow = Node2D.new()
	_glow.draw.connect(_draw_glow)
	_glow_layer.add_child(_glow)
	_build_ui()
	Windowing.view_changed.connect(_fit)
	_fit()


func _shadow(at: Vector2, w: int, h: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Lighting.ellipse_texture(w, h, Color(0.12, 0.06, 0.05, 0.45))
	s.position = at
	_scene.add_child(s)
	return s


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	_ui_layer.visible = false
	add_child(_ui_layer)
	_ui_root = Control.new()
	_ui_root.theme = UiKit.make_theme()
	_ui_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.gui_input.connect(_on_picture_input)
	_ui_layer.add_child(_ui_root)
	var top := UiKit.row(_ui_root)
	top.position = Vector2(4, 4)
	UiKit.button(top, tr("Back outside"), leave)
	UiKit.button(top, tr("Furnish"), func(): _open(""))
	var purse_box := PanelContainer.new()
	top.add_child(purse_box)
	var info := UiKit.column(purse_box)
	_purse = UiKit.label(info)
	_comfort = UiKit.label(info)
	_comfort.add_theme_color_override("font_color", UiKit.FADED)
	_hover_label = UiKit.label(_ui_root, "", true)
	_hover_label.visible = false
	_panel = PanelContainer.new()
	_panel.visible = false
	_ui_root.add_child(_panel)
	var col := UiKit.column(_panel)
	col.custom_minimum_size = Vector2(230, 0)
	var head := UiKit.row(col)
	_title = UiKit.label(head)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.close_button(head, _close_panel)
	_list = UiKit.scroll(col, Vector2(220, 170))
	_scroll = _list
	while _scroll and not _scroll is ScrollContainer:
		_scroll = _scroll.get_parent()


## The room is scaled up by a whole number until it covers the window, like the market town.
func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var cover := ceili(maxf(view.x / 480.0, view.y / 270.0))
	for node in [_scene, _glow]:
		node.scale = Vector2(cover, cover)
		node.position = ((view - Vector2(480, 270) * cover) / 2.0).round()
	_ui_layer.scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_ui_root.size = (view / Windowing.ui_scale).floor()
	_panel.position = Vector2(_ui_root.size.x - 240, 30)


func enter() -> void:
	visible = true
	_ui_layer.visible = true
	_glow_layer.visible = true
	_panel.visible = false
	_selected = ""
	_dress_room()
	_signature = ""
	_refresh()


func leave() -> void:
	Dissolve.play(self, func() -> void:
		visible = false
		_ui_layer.visible = false
		_glow_layer.visible = false
		left_house.emit())


func ruined() -> bool:
	return Game.villa_stage < 2


## Shows the ruin or the restored room, the furnishings bought so far, and the pets napping in their places.
func _dress_room() -> void:
	_base.texture = load(DIR + ("ruin.png" if ruined() else "empty.png"))
	for id in _sprites:
		_sprites[id].visible = not ruined() and Game.furnishings.has(id)
	for pet in [_dog, _cat, _dog_shadow, _cat_shadow]:
		pet.visible = not ruined()
	if ruined():
		return
	var dog: Dictionary = Game.pets.get("dog", {})
	var dog_dir := Coats.breed_dir("dog", String(dog.get("breed", "")))
	var dog_look := func(tex: Texture2D) -> Texture2D: return Coats.recolour(tex, "dog", String(dog.get("coat", "")))
	var f := SpriteFrames.new()
	f.remove_animation("default")
	# The sleeping loop starts after the dog has lain down, from the fifth picture on.
	Frames.add_folder(f, "sleep", dog_dir + "sleep_east/", 3.0, true, dog_look, 4)
	_dog.sprite_frames = f
	_dog.play("sleep")
	if f.has_animation("sleep"):
		_dog.offset = Frames.anchor(f.get_frame_texture("sleep", 0))
	_dog.position = Vector2(104, 240)
	var cat: Dictionary = Game.pets.get("cat", {})
	var cat_dir := Coats.breed_dir("cat", String(cat.get("breed", "")))
	var cf := SpriteFrames.new()
	cf.remove_animation("default")
	var cat_look := func(tex: Texture2D) -> Texture2D: return Coats.recolour(tex, "cat", String(cat.get("coat", ""))) if String(cat.get("coat", "")) != "" else tex
	var count := Frames.add_folder(cf, "sleep", cat_dir + "sleep_east/", 1.0, false, cat_look)
	_cat.sprite_frames = cf
	if count > 0:
		# The cat is already curled up, so it shows the last picture of lying down.
		_cat.animation = "sleep"
		_cat.frame = count - 1
		_cat.offset = Frames.anchor(cf.get_frame_texture("sleep", count - 1))
	_cat.position = Vector2(282, 116)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var night := Lighting.night_amount(Game.day_time)
	var day: Color = Lighting.color_at(Game.day_time)
	var warmth := 0.0
	if not ruined():
		# Indoors the room is never as dark as the night outside, and the fire and lamps warm it further.
		warmth = 0.08 + (0.14 if Game.furnishings.has("fire") else 0.0) + (0.1 if Game.furnishings.has("lamps") else 0.0)
	_light.color = day.lerp(Color(1.0, 0.86, 0.68), warmth * night).lerp(Color(1.0, 0.97, 0.92), 0.4 * (1.0 - night))
	if _sprites.has("fire") and _sprites["fire"].visible:
		var flicker := 1.0 + 0.12 * sin(_t * 9.0) * sin(_t * 3.7 + 1.0)
		_sprites["fire"].modulate = Color(flicker, flicker, flicker)
	_glow.queue_redraw()
	_marks.queue_redraw()
	_refresh()


func _draw_glow() -> void:
	var night := Lighting.night_amount(Game.day_time)
	# The view outside darkens with the evening and fills with stars.
	for r in (RUIN_OUTSIDE if ruined() else OUTSIDE):
		_glow.draw_rect(r, Color(NIGHT_SKY, 0.78 * night))
		if night > 0.3:
			for k in 9:
				var at := Vector2(r.position.x + fposmod(k * 23.7, r.size.x), r.position.y + fposmod(k * 11.3, r.size.y * 0.45)).floor()
				var twinkle := 0.5 + 0.5 * sin(_t * (1.0 + k * 0.4) + k)
				_glow.draw_rect(Rect2(at, Vector2.ONE), Color(0.92, 0.92, 1.0, (night - 0.3) * twinkle))
	if ruined():
		return
	if Game.furnishings.has("fire"):
		var f := 0.8 + 0.2 * sin(_t * 7.0) * sin(_t * 2.3)
		_glow.draw_circle(FIRE_GLOW, 42.0, Color(1.0, 0.55, 0.2, 0.05 * f * (0.5 + night)))
		_glow.draw_circle(FIRE_GLOW, 24.0, Color(1.0, 0.6, 0.25, 0.08 * f * (0.5 + night)))
	if Game.furnishings.has("lamps") and night > 0.05:
		for p in LAMP_FLAMES:
			var f := 0.85 + 0.15 * sin(_t * 6.0 + p.x)
			_glow.draw_circle(p, 12.0, Color(1.0, 0.7, 0.35, 0.09 * night * f))
			_glow.draw_circle(p, 5.0, Color(1.0, 0.8, 0.45, 0.15 * night * f))
	if Game.furnishings.has("water"):
		# Glints come and go across the water, a few at a time.
		for k in 7:
			var phase := fposmod(_t * 0.5 + k * 0.37, 1.0)
			var seed := floorf(_t * 0.5 + k * 0.37) * 13.0 + k * 7.0
			var at := Vector2(206 + fposmod(seed * 37.0, 130.0), 186 + fposmod(seed * 19.0, 38.0)).floor()
			if Geometry2D.is_point_in_polygon(at, PackedVector2Array(POOL)):
				_glow.draw_rect(Rect2(at, Vector2(2, 1)), Color(1.0, 0.95, 0.8, 0.5 * sin(phase * PI)))


## Spots that can still be furnished twinkle softly, and the one under the pointer is outlined.
func _draw_marks() -> void:
	if ruined():
		return
	for id in Balance.get_value("interior.furnishings", {}):
		var rects: Array = Game.furnishing_info(id).get("rects", [])
		if id == _hovered:
			for r in rects:
				UiKit.outline(_marks, Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1]), MARK)
		elif not Game.furnishings.has(id) and Game.furnishing_block(id) == "" and not rects.is_empty():
			var r: Array = rects[0]
			var c := Vector2(roundf((r[0] + r[2]) / 2.0), roundf((r[1] + r[3]) / 2.0))
			var a := 0.35 + 0.35 * sin(_t * 2.5 + c.x * 0.1)
			for d in [Vector2(0, -2), Vector2(0, 2), Vector2(-2, 0), Vector2(2, 0), Vector2.ZERO]:
				_marks.draw_rect(Rect2(c + d, Vector2.ONE), Color(MARK, a))


func _picture_point(ui_point: Vector2) -> Vector2:
	return (ui_point * Windowing.ui_scale - _scene.position) / _scene.scale.x


func _spot_at(point: Vector2) -> String:
	if ruined():
		return ""
	for id in Balance.get_value("interior.furnishings", {}):
		for r in Game.furnishing_info(id).get("rects", []):
			if Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1]).has_point(point):
				return String(id)
	return ""


func _on_picture_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	var spot := _spot_at(_picture_point(event.position))
	if event is InputEventMouseMotion:
		_hovered = spot
		_hover_label.visible = spot != ""
		if spot != "":
			var name := tr(String(Game.furnishing_info(spot).get("name", "")))
			_hover_label.text = name if Game.furnishings.has(spot) else tr("%s: click to furnish") % name
			_hover_label.position = (event.position + Vector2(8, 10)).min(_ui_root.size - _hover_label.get_minimum_size() - Vector2(2, 2))
		_ui_root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if spot != "" else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if spot != "":
			_open(spot)
		elif _panel.visible:
			_close_panel()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("close_panel"):
		# Escape closes the furnishing window first, then goes back outside.
		if _panel.visible:
			_close_panel()
		else:
			leave()
		get_viewport().set_input_as_handled()


## Opens the furnishing window on one furnishing, or on the whole list when id is empty.
func _open(id: String) -> void:
	_selected = id
	if not _panel.visible:
		UiKit.fade_in(_panel)
	_panel.visible = true
	_signature = ""
	Sfx.play("click", -8.0)
	_refresh()


func _close_panel() -> void:
	_panel.visible = false


func _refresh() -> void:
	_purse.text = tr("Sestertii %d") % Game.coins
	var bonus := roundi((Game.comfort_factor() - 1.0) * 100.0)
	_comfort.text = tr("Comfort %d: helpers work %d%% faster") % [Game.furnishings.size(), bonus] if bonus > 0 else tr("An empty house: nothing to make it a home yet")
	if not _panel.visible:
		return
	var sig := "%s|%d|%s|%d" % [_selected, Game.coins, JSON.stringify(Game.furnishings), Game.villa_stage]
	if sig == _signature:
		return
	_signature = sig
	UiKit.clear(_list)
	if ruined():
		_title.text = tr("A ruin")
		UiKit.para(_list, tr("Wind and rain come in through the roof. Restore the farmhouse to make it a home, then furnish it room by room."), 210)
		return
	_title.text = tr(String(Game.furnishing_info(_selected).get("name", ""))) if _selected != "" else tr("Furnish the house")
	var ids: Array = [_selected] if _selected != "" else Balance.get_value("interior.furnishings", {}).keys()
	# One furnishing needs only a short window; the whole list scrolls in a taller one.
	_scroll.custom_minimum_size.y = 74 if _selected != "" else 170
	for id in ids:
		_furnishing_card(String(id), _selected == "")
	if _selected != "":
		UiKit.button(_list, tr("See everything"), func(): _open(""))


func _furnishing_card(id: String, named: bool) -> void:
	var f := Game.furnishing_info(id)
	var card := UiKit.card(_list)
	if named:
		UiKit.label(card, tr(String(f.get("name", "")))).add_theme_color_override("font_color", UiKit.HEADING)
	UiKit.para(card, tr(String(f.get("desc", ""))), 200)
	if Game.furnishings.has(id):
		UiKit.label(card, tr("In place")).add_theme_color_override("font_color", UiKit.FADED)
		return
	var block := Game.furnishing_block(id)
	if block != "":
		UiKit.para(card, tr(block), 200).add_theme_color_override("font_color", UiKit.SHORT)
		return
	var r := UiKit.row(card)
	var buy := UiKit.button(r, tr("Buy for %d sestertii") % int(f.get("price", 0)), func():
		if Game.buy_furnishing(id):
			Sfx.play("coins")
			Sfx.play("unlock", -4.0)
			_sprites[id].visible = true
			UiKit.fade_in(_sprites[id], 0.6)
			_signature = "")
	buy.disabled = Game.coins < int(f.get("price", 0))
