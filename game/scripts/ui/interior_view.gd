extends CanvasLayer
## Inside the farmhouse: a room of its own over the estate, like the market town. While the house is a ruin it is an
## empty shell open to the sky; once restored it is a bare room that the player furnishes piece by piece, each bought
## furnishing painted into place. The fire and lamps flicker, the loom weaves when clicked, the estate's own sky shows
## through the doorway, and the player's own dog and cat nap on the rug and the couch and answer a stroke.

signal left_house

const DIR := "res://assets/backgrounds/interior/"
const SkyView := preload("res://scripts/world/sky_view.gd")
const FLAME := preload("res://assets/shaders/flame.gdshader")
const WATER := preload("res://assets/shaders/water.gdshader")
## The square of sky over the pool: an atrium's roof opens above its rain pool, out of sight above the picture, so
## daylight falls on the water in a soft shaft and rain falls straight into it.
const SHAFT := [Vector2(196, 0), Vector2(344, 0), Vector2(344, 200), Vector2(320, 182), Vector2(228, 182), Vector2(196, 196)]
## The painted land seen through the doorway, which darkens at night like the estate.
const LAND := Rect2(367, 57, 64, 72)
## The ruin is the same room fallen apart, so its doorway is the same one.
const RUIN_LAND := LAND
## Which part of the estate's sky shows through the doorway: the room's pixel at the doorway's horizon, and the sky's.
const SKY_AT := {"room": [Vector2(399, 57), Vector2(230, 170)], "ruin": [Vector2(399, 57), Vector2(230, 170)]}
## The loom, and the line its shuttle runs along between the warp threads.
const LOOM := Rect2(155, 84, 85, 80)
const SHED := [178.0, 226.0, 111.0]
## Inside, the pets are drawn at the room painting's own detail, asleep, one picture for each breed.
const ROOM_PETS := "res://assets/sprites/room_pets/"
const FIRE_GLOW := Vector2(101, 140)
const LAMP_FLAMES := [Vector2(70, 49), Vector2(132, 53), Vector2(20, 119), Vector2(305, 102)]
## The pool's surface, as a shape the shimmer stays inside.
const POOL := [Vector2(196, 196), Vector2(228, 182), Vector2(320, 182), Vector2(344, 200), Vector2(300, 228), Vector2(210, 228)]
const NIGHT_SKY := Color8(14, 18, 44)
const MARK := Color(1, 0.95, 0.75)

var _scene: Node2D
var _sky_layer: CanvasLayer
var _sky: Node2D
var _loom: Node2D
var _weaving := 0.0
var _hearts: Array = []
var _base: Sprite2D
var _light: CanvasModulate
var _glow_layer: CanvasLayer
var _glow: Node2D
var _sprites := {}
var _marks: Node2D
var _dog: AnimatedSprite2D
var _dog_shadow: Sprite2D
## Set while a stroked pet is stirring, so a second stroke waits for the first to finish.
var _stirring := {}
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
	# The estate's own sky, with its clouds, stars, moon and northern lights, shows through the doorway behind the room.
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = 7
	_sky_layer.visible = false
	add_child(_sky_layer)
	_sky = SkyView.new()
	_sky.sky_visible = func() -> bool: return visible
	_sky_layer.add_child(_sky)
	_spots = JSON.parse_string(FileAccess.get_file_as_string(DIR + "furnishings.json")) if FileAccess.file_exists(DIR + "furnishings.json") else {}
	_scene = Node2D.new()
	add_child(_scene)
	_light = CanvasModulate.new()
	add_child(_light)
	_base = Sprite2D.new()
	_base.centered = false
	# Past the painting's edges its walls and floor carry on, mirrored.
	_base.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	_scene.add_child(_base)
	for id in Balance.get_value("interior.furnishings", {}):
		if not _spots.has(id) or not ResourceLoader.exists(DIR + id + ".png"):
			continue
		var s := Sprite2D.new()
		s.centered = false
		s.texture = load(DIR + id + ".png")
		s.position = Vector2(_spots[id][0], _spots[id][1])
		s.visible = false
		if id == "water":
			var ripple := ShaderMaterial.new()
			ripple.shader = WATER
			s.material = ripple
		if id in ["fire", "lamps"]:
			var flame := ShaderMaterial.new()
			flame.shader = FLAME
			flame.set_shader_parameter("reach", 2.0 if id == "fire" else 1.0)
			s.material = flame
		_scene.add_child(s)
		_sprites[id] = s
	_loom = Node2D.new()
	_loom.draw.connect(_draw_loom)
	_scene.add_child(_loom)
	# A soft shadow keeps each pet from melting into the rug or the cushions it lies on.
	_dog_shadow = _shadow(Vector2(102, 244), 80, 14)
	_dog = AnimatedSprite2D.new()
	_dog.centered = false
	_scene.add_child(_dog)
	_cat_shadow = _shadow(Vector2(280, 115), 40, 9)
	_cat = AnimatedSprite2D.new()
	_cat.centered = false
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


## The room is drawn at the estate's own pixel scale, so its pixels are the same size as everywhere else in the game;
## a window of another shape shows more of the room's walls and floor, the painting carried on past its edges.
func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var cover := Windowing.scale
	var spare := ((view / cover - Vector2(480, 270)) / 2.0).ceil().max(Vector2.ZERO)
	for node in [_scene, _glow]:
		node.scale = Vector2(cover, cover)
		node.position = ((view - Vector2(480, 270) * cover) / 2.0).round()
	_base.region_enabled = true
	_base.region_rect = Rect2(-spare, Vector2(480, 270) + spare * 2.0)
	_base.position = -spare
	var at: Array = SKY_AT["ruin" if ruined() else "room"]
	_sky.scale = Vector2(cover, cover)
	_sky.position = _scene.position + (at[0] - at[1]) * cover
	_ui_layer.scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_ui_root.size = (view / Windowing.ui_scale).floor()
	_panel.position = Vector2(_ui_root.size.x - 240, 30)


func enter() -> void:
	visible = true
	_ui_layer.visible = true
	_glow_layer.visible = true
	_sky_layer.visible = true
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
		_sky_layer.visible = false
		left_house.emit())


func ruined() -> bool:
	return Game.villa_stage < 2


## Shows the ruin or the restored room, the furnishings bought so far, and the pets napping in their places.
func _dress_room() -> void:
	# From the villa rustica on, the walls are freshly painted rather than worn.
	var room := "ruin.png" if ruined() else ("painted.png" if Game.villa_stage >= 3 else "empty.png")
	_base.texture = load(DIR + room)
	for id in _sprites:
		_sprites[id].visible = not ruined() and Game.furnishings.has(id)
	for pet in [_dog, _cat, _dog_shadow, _cat_shadow]:
		pet.visible = not ruined()
	if ruined():
		return
	_dog.sprite_frames = _room_pet("dog", "hound")
	_dog.position = Vector2(102, 248)
	_cat.sprite_frames = _room_pet("cat", "tabby")
	_cat.position = Vector2(280, 120)
	for pet in [_dog, _cat]:
		pet.play("sleep")
		pet.offset = Frames.anchor(pet.sprite_frames.get_frame_texture("sleep", 0))
	_fit()


## The pet's room picture for its breed, in the coat the player chose.
func _room_pet(kind: String, fallback: String) -> SpriteFrames:
	var pet: Dictionary = Game.pets.get(kind, {})
	var breed := String(pet.get("breed", fallback))
	var path := ROOM_PETS + breed + ".png"
	if not ResourceLoader.exists(path):
		path = ROOM_PETS + fallback + ".png"
	var f := SpriteFrames.new()
	f.remove_animation("default")
	f.add_animation("sleep")
	f.add_frame("sleep", Coats.recolour(load(path), kind, String(pet.get("coat", ""))))
	return f


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
	_weaving = maxf(0.0, _weaving - delta)
	# Sleeping pets breathe: a slow rise and fall of a pixel.
	for pet in [_dog, _cat]:
		if not _stirring.has(pet):
			pet.scale = Vector2(1.0, 1.0 + 0.025 * sin(_t * (1.6 if pet == _dog else 2.1)))
	_loom.queue_redraw()
	for h in _hearts:
		h["age"] += delta
	_hearts = _hearts.filter(func(h): return h["age"] < 1.4)
	_glow.queue_redraw()
	_marks.queue_redraw()
	_refresh()


func _draw_glow() -> void:
	var night := Lighting.night_amount(Game.day_time)
	# The painted land outside darkens with the evening, under the sky's own stars.
	_glow.draw_rect(RUIN_LAND if ruined() else LAND, Color(NIGHT_SKY, 0.7 * night))
	for h in _hearts:
		var a: float = 1.0 - h["age"] / 1.4
		var p: Vector2 = (h["at"] + Vector2(sin(h["age"] * 5.0) * 2.0, -h["age"] * 16.0)).floor()
		for d in [Vector2(0, 0), Vector2(2, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(1, 3)]:
			_glow.draw_rect(Rect2(p + d, Vector2.ONE), Color(0.92, 0.3, 0.36, a))
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
	_draw_atrium_sky(night)
	if Game.furnishings.has("water"):
		# Glints come and go across the water, a few at a time.
		for k in 7:
			var phase := fposmod(_t * 0.5 + k * 0.37, 1.0)
			var seed := floorf(_t * 0.5 + k * 0.37) * 13.0 + k * 7.0
			var at := Vector2(206 + fposmod(seed * 37.0, 130.0), 186 + fposmod(seed * 19.0, 38.0)).floor()
			if Geometry2D.is_point_in_polygon(at, PackedVector2Array(POOL)):
				_glow.draw_rect(Rect2(at, Vector2(2, 1)), Color(1.0, 0.95, 0.8, 0.5 * sin(phase * PI)))


## The light and the rain that come down through the roof opening onto the pool.
func _draw_atrium_sky(night: float) -> void:
	var raining: bool = Game.calendar.raining()
	var shaft := PackedVector2Array(SHAFT)
	var pool := PackedVector2Array(POOL)
	# Sunlight by day, a faint cool moonlight by night, both dimmed under rain clouds.
	var light := Color(1.0, 0.95, 0.8).lerp(Color(0.6, 0.7, 1.0), night)
	var strength := (0.12 - 0.08 * night) * (0.5 if raining else 1.0)
	_glow.draw_colored_polygon(shaft, Color(light, strength))
	# The water itself catches the light rather than a shape laid over the stone around it.
	if _sprites.has("water"):
		var lift := 1.0 + strength * 2.5
		_sprites["water"].modulate = Color(lift, lift, lift * 0.98)
	if not raining:
		return
	var water := Game.furnishings.has("water")
	# Rain falls straight down the shaft; each streak is a short line of pale pixels.
	for k in 26:
		var x := 198.0 + fposmod(k * 53.7, 144.0)
		var y := fposmod(_t * 190.0 + k * 41.3, 236.0) - 8.0
		if Geometry2D.is_point_in_polygon(Vector2(x, y + 5), shaft):
			_glow.draw_rect(Rect2(Vector2(x, y).floor(), Vector2(1, 5)), Color(0.82, 0.88, 0.97, 0.55))
	# Where the drops land, rings spread on the water, or small splashes jump off the dry stone.
	for k in 9:
		var life := fposmod(_t * 1.3 + k * 0.29, 1.0)
		var round_no := floorf(_t * 1.3 + k * 0.29)
		var at := Vector2(206 + fposmod((round_no + k) * 47.0, 132.0), 188 + fposmod((round_no * 3.0 + k) * 13.0, 36.0)).floor()
		if not Geometry2D.is_point_in_polygon(at, pool):
			continue
		var fade := 1.0 - life
		if water:
			var r := 1.0 + life * 6.0
			for a in 16:
				var angle := a * TAU / 16.0
				_glow.draw_rect(Rect2((at + Vector2(cos(angle) * r, sin(angle) * r * 0.4)).floor(), Vector2.ONE), Color(0.85, 0.92, 1.0, 0.5 * fade))
		elif life < 0.3:
			for d in [Vector2(-1, -1), Vector2(1, -1), Vector2(0, -2)]:
				_glow.draw_rect(Rect2(at + d * (1.0 + life * 4.0), Vector2.ONE), Color(0.85, 0.9, 0.95, 0.6 * fade))


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


## While weaving, the shuttle runs back and forth between the warp threads, and the heddle bar lifts and drops
## alternate threads at each pass.
func _draw_loom() -> void:
	if _weaving <= 0.0 or ruined():
		return
	var pass_time := 0.55
	var k := int(floorf(_weaving / pass_time))
	var along := fposmod(_weaving, pass_time) / pass_time
	var x := lerpf(SHED[0], SHED[1], along if k % 2 == 0 else 1.0 - along)
	_loom.draw_rect(Rect2(roundf(x) - 3, SHED[2], 7, 2), Color8(92, 56, 34))
	_loom.draw_rect(Rect2(roundf(x) - 2, SHED[2], 5, 1), Color8(196, 150, 96))
	var lift := 1.0 if k % 2 == 0 else -1.0
	_loom.draw_rect(Rect2(176, 103 + lift, 54, 1), Color8(214, 176, 120))
	_loom.draw_rect(Rect2(176, 104 + lift, 54, 1), Color8(120, 78, 44))


func _pet_at(point: Vector2) -> AnimatedSprite2D:
	if ruined():
		return null
	for pet in [_cat, _dog]:
		if pet.sprite_frames == null or not pet.sprite_frames.has_animation(pet.animation):
			continue
		var tex: Texture2D = pet.sprite_frames.get_frame_texture(pet.animation, pet.frame)
		var used := Rect2(tex.get_image().get_used_rect())
		var box := Rect2(pet.position + pet.offset + used.position, used.size)
		if box.grow(2).has_point(point):
			return pet
	return null


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
	var point := _picture_point(event.position)
	# The pets lie in front of the furnishings, so they take the pointer first, then the loom, then a furnishing.
	var pet := _pet_at(point)
	var loom := pet == null and not ruined() and LOOM.has_point(point) and _spot_at(point) == ""
	var spot := "" if pet != null or loom else _spot_at(point)
	if event is InputEventMouseMotion:
		_hovered = spot
		var text := ""
		if pet != null:
			var kind := "dog" if pet == _dog else "cat"
			var name := String(Game.pets.get(kind, {}).get("name", ""))
			text = (name if name != "" else tr("The dog" if kind == "dog" else "The cat")) + ": " + tr("asleep")
		elif loom:
			text = tr("The loom: click to weave")
		elif spot != "":
			var title := tr(String(Game.furnishing_info(spot).get("name", "")))
			text = title if Game.furnishings.has(spot) else tr("%s: click to furnish") % title
		_hover_label.visible = text != ""
		_hover_label.text = text
		_hover_label.position = (event.position + Vector2(8, 10)).min(_ui_root.size - _hover_label.get_minimum_size() - Vector2(2, 2))
		_ui_root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if text != "" else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if pet != null:
			_stroke(pet)
		elif loom:
			_weave()
		elif spot != "":
			_open(spot)
		elif _panel.visible:
			_close_panel()


## A sleeping pet stirs at a stroke: it gives a happy sound and a heart floats up from it.
func _stroke(pet: AnimatedSprite2D) -> void:
	var dog := pet == _dog
	# The dog thumps its tail as it stirs, gets up to wag, then settles back to sleep; the cat purrs in its sleep.
	if dog:
		Sfx.tail_thumps()
	else:
		Sfx.play("cat", -4.0)
	Game.add_stat("pets", 1)
	_hearts.append({"at": pet.position + Vector2(6 if dog else 0, -26 if dog else -30), "age": 0.0})
	_stir(pet)


## A stroked pet stirs without waking: a happy wriggle and a stretch, a little lean into the hand, then it settles.
func _stir(pet: AnimatedSprite2D) -> void:
	if _stirring.has(pet):
		return
	_stirring[pet] = true
	var tween := create_tween()
	for k in 3:
		tween.tween_property(pet, "scale", Vector2(1.04, 0.96), 0.1)
		tween.tween_property(pet, "scale", Vector2(0.98, 1.03), 0.1)
	tween.tween_property(pet, "rotation", -0.04, 0.25)
	tween.tween_property(pet, "rotation", 0.0, 0.4)
	tween.tween_property(pet, "scale", Vector2.ONE, 0.2)
	tween.tween_callback(func(): _stirring.erase(pet))


## A few passes of the shuttle, each beaten home with a soft knock.
func _weave() -> void:
	if _weaving > 0.0:
		return
	_weaving = 0.55 * 4
	for k in 4:
		get_tree().create_timer(0.55 * (k + 1)).timeout.connect(func(): Sfx.play("made", -16.0, 0.1))


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
	for id in ids:
		_furnishing_card(String(id), _selected == "")
	if _selected != "":
		UiKit.button(_list, tr("See everything"), func(): _open(""))
	_size_panel.call_deferred()


## One furnishing gets a window just tall enough for it; the whole list scrolls in a taller one. The text wraps only
## once laid out, so this runs a frame after the window is filled.
func _size_panel() -> void:
	await get_tree().process_frame
	var need := _list.get_combined_minimum_size().y + 2
	_scroll.custom_minimum_size.y = minf(need, 170.0) if _selected != "" else 170.0
	_panel.reset_size()


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
			Sfx.play("coins", -6.0)
			# Each furnishing arrives with its own sound: water poured in, a fire lit, pots set down.
			for sound in f.get("sounds", []):
				Sfx.play(String(sound), -2.0)
			_sprites[id].visible = true
			UiKit.fade_in(_sprites[id], 0.6)
			_signature = "")
	buy.disabled = Game.coins < int(f.get("price", 0))
