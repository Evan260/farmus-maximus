extends CanvasLayer
## Inside the farmhouse: a room of its own over the estate, like the market town. While the house is a ruin it is an
## empty shell open to the sky; once restored it is a bare room that the player furnishes piece by piece, each bought
## furnishing painted into place. The fire and lamps flicker, the loom weaves when clicked, the estate's own sky shows
## through the doorway over the estate's own hills, and the player's own dog and cat nap on the rug and the couch and
## answer a stroke.

signal left_house

const DIR := "res://assets/backgrounds/interior/"
const SkyView := preload("res://scripts/world/sky_view.gd")
const FLAME := preload("res://assets/shaders/flame.gdshader")
## The doorway's opening in the painting, and the pixel of the estate's far scenery at its top left corner: the
## estate's own mountains, hills and sky show through it, a pixel of theirs to each of the room's.
const DOOR := Rect2(366, 20, 64, 112)
const VIEW_FROM := Vector2(400, 124)
const FAR := "res://assets/backgrounds/estate/"
## How far the room's pictures carry on past the painting on each side and above it, in the painting's pixels.
const SIDE := 84.0
const ABOVE := 90.0
## Past the room's pictures, on a window wider or taller still, the walls fade into this shadow over FADE pixels.
const DARK := Color(0.09, 0.05, 0.04)
const FADE := 24.0
## The loom, and where its working parts are on the room's half-detail grid: the warp threads run from WARP_LEFT to
## WARP_RIGHT, the shed opens between them at SHED_Y, the heddle bar sits at HEDDLE_Y and the woven edge at FELL_Y.
const LOOM := Rect2(155, 84, 85, 80)
const WARP_LEFT := 88
const WARP_RIGHT := 114
const SHED_Y := 56
const HEDDLE_Y := 51
const FELL_Y := 60
const PASS_SECONDS := 0.8
const PASSES := 5
const WOOD_DARK := Color8(66, 38, 24)
const WOOD := Color8(146, 88, 46)
const WOOD_LIGHT := Color8(206, 150, 90)
const THREAD := Color8(226, 206, 172)
const THREAD_SHADE := Color8(150, 128, 104)
const WEFT := Color8(176, 146, 204)
const WEFT_SHADE := Color8(116, 92, 156)
## The room is drawn with half as many pixels as its painting, the same coarseness as the farm's own art: everything
## is placed in the painting's 480 by 270 but drawn onto a canvas of half that, and each of its pixels shown at twice
## the estate's pixel size. The pets keep their farm pictures, one of their pixels to one of the room's.
const DETAIL := 2.0
const FIRE_GLOW := Vector2(101, 140)
const LAMP_FLAMES := [Vector2(70, 49), Vector2(132, 53), Vector2(20, 119), Vector2(305, 102)]
const MARK := Color(1, 0.95, 0.75)

var _scene: Node2D
var _viewport: SubViewport
var _display: Sprite2D
## Where the painting's top left corner sits on the half-detail canvas, in painting pixels, when the window is wider
## or taller than the painting.
var _origin := Vector2.ZERO
var _dog_offsets := {}
## Set while the dog is awake from a stroke: up, wagging, then lying back down, as timed by its tween.
var _dog_awake := false
var _dog_tween: Tween
var _sky_layer: CanvasLayer
var _sky: Node2D
var _loom: Node2D
var _weaving := 0.0
## How much the rows just woven still show, fading from 1 to 0 after the weaving stops.
var _woven := 0.0
var _hearts: Array = []
var _base: Sprite2D
## The shadow the room fades into past its pictures' edges.
var _edges: Node2D
var _light: CanvasModulate
var _glow_layer: CanvasLayer
var _glow: Node2D
## The estate's mountains and hills seen through the doorway.
var _far_mountains: Sprite2D
var _far_land: Sprite2D
## The light the fire throws on the room around it, and each oil lamp's.
var _fire_light: Lamp
var _lamp_lights: Array[Lamp] = []
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
var _outside: Button
var _furnish: Button
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
## The picture the room is dressed in, such as "ruin.png".
var _room := ""


func _ready() -> void:
	layer = 8
	visible = false
	_viewport = SubViewport.new()
	_viewport.disable_3d = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_viewport)
	_display = Sprite2D.new()
	_display.centered = false
	_display.texture = _viewport.get_texture()
	add_child(_display)
	# The estate's own sky, with its clouds, stars, moon and northern lights, shows through the doorway behind the room.
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = -1
	_viewport.add_child(_sky_layer)
	_sky = SkyView.new()
	_sky.sky_visible = func() -> bool: return visible
	_sky_layer.add_child(_sky)
	_far_mountains = _far(FAR + "layer_mountains.png")
	_far_land = _far(FAR + "layer_land.png")
	_spots = JSON.parse_string(FileAccess.get_file_as_string(DIR + "furnishings.json")) if FileAccess.file_exists(DIR + "furnishings.json") else {}
	_scene = Node2D.new()
	_viewport.add_child(_scene)
	_light = CanvasModulate.new()
	_viewport.add_child(_light)
	_base = Sprite2D.new()
	_base.centered = false
	_base.scale = Vector2(DETAIL, DETAIL)
	_base.position = -Vector2(SIDE, ABOVE)
	_scene.add_child(_base)
	for id in Balance.get_value("interior.furnishings", {}):
		if not _spots.has(id) or not ResourceLoader.exists(DIR + id + ".png"):
			continue
		var s := Sprite2D.new()
		s.centered = false
		s.texture = load(DIR + id + ".png")
		s.position = Vector2(_spots[id][0], _spots[id][1]) * DETAIL
		s.scale = Vector2(DETAIL, DETAIL)
		s.visible = false
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
	_dog.scale = Vector2(DETAIL, DETAIL)
	_scene.add_child(_dog)
	_cat_shadow = _shadow(Vector2(280, 115), 40, 9)
	_cat = AnimatedSprite2D.new()
	_cat.centered = false
	_cat.scale = Vector2(DETAIL, DETAIL)
	_scene.add_child(_cat)
	_edges = Node2D.new()
	_edges.draw.connect(_draw_edges)
	_scene.add_child(_edges)
	_marks = Node2D.new()
	_marks.draw.connect(_draw_marks)
	_scene.add_child(_marks)
	_fire_light = Lamp.new()
	_fire_light.position = FIRE_GLOW
	_fire_light.radius = 220.0
	_fire_light.colour = Color(1.0, 0.62, 0.3)
	_scene.add_child(_fire_light)
	for at in LAMP_FLAMES:
		var lamp := Lamp.new()
		lamp.position = at
		lamp.radius = 60.0
		lamp.power = 0.7
		_scene.add_child(lamp)
		_lamp_lights.append(lamp)
	# Fire, lamplight and stars are added on their own layer, so the room's dimming at night does not dim them too.
	_glow_layer = CanvasLayer.new()
	_glow_layer.layer = 1
	_viewport.add_child(_glow_layer)
	_glow = Node2D.new()
	_glow.draw.connect(_draw_glow)
	_glow_layer.add_child(_glow)
	_build_ui()
	Windowing.view_changed.connect(_fit)
	_fit()


## A piece of the estate's far scenery, cut to the doorway and drawn behind the room.
func _far(path: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.region_enabled = true
	s.region_rect = Rect2(VIEW_FROM, DOOR.size / DETAIL)
	s.position = DOOR.position
	s.scale = Vector2(DETAIL, DETAIL)
	_sky_layer.add_child(s)
	return s


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
	_ui_root.theme = UiTheme.build()
	_ui_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.gui_input.connect(_on_picture_input)
	_ui_layer.add_child(_ui_root)
	var top := Ui.row(_ui_root)
	top.position = Vector2(4, 4)
	_outside = Ui.button(top, tr("Back outside"), leave)
	_furnish = Ui.button(top, tr("Furnish"), func(): _open(""))
	for b in [_outside, _furnish]:
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var purse_box := PanelContainer.new()
	top.add_child(purse_box)
	var info := Ui.column(purse_box)
	_purse = Ui.label(info)
	_comfort = Ui.label(info)
	_comfort.add_theme_color_override("font_color", UiTheme.MUTED)
	_hover_label = Ui.label(_ui_root, "", true)
	_hover_label.visible = false
	_panel = PanelContainer.new()
	_panel.visible = false
	_ui_root.add_child(_panel)
	var col := Ui.column(_panel)
	col.custom_minimum_size = Vector2(230, 0)
	var head := Ui.row(col)
	_title = Ui.label(head)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ui.close_button(head, _close_panel)
	_list = Ui.scroll(col, Vector2(220, 170))
	_scroll = _list
	while _scroll and not _scroll is ScrollContainer:
		_scroll = _scroll.get_parent()


## Each pixel of the half-detail canvas is shown at twice the estate's pixel size; a window of another shape shows
## more of the room's walls, floor and ceiling, which its pictures carry on past the painting.
func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var shown := Windowing.scale * DETAIL
	var canvas := (view / shown).ceil()
	_viewport.size = Vector2i(canvas)
	# Spare width is shared between the sides; spare height all goes above, since the painting's bottom edge cuts
	# through the plants and the rug and must stay on the bottom of the screen.
	var extra := (canvas * DETAIL - Vector2(480, 270)).max(Vector2.ZERO)
	_origin = Vector2(floorf(extra.x / 2.0 / DETAIL) * DETAIL, extra.y)
	var place := Transform2D(0.0, Vector2.ONE / DETAIL, 0.0, _origin / DETAIL)
	_viewport.canvas_transform = place
	for l in [_sky_layer, _glow_layer]:
		l.transform = place
	_display.scale = Vector2(shown, shown)
	_display.position = ((view - canvas * shown) / 2.0).floor()
	_edges.queue_redraw()
	# The sky is drawn at the same coarseness, lined up with the far hills under it.
	_sky.scale = Vector2(DETAIL, DETAIL)
	_sky.position = DOOR.position - VIEW_FROM * DETAIL
	_ui_layer.scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_ui_root.size = (view / Windowing.ui_scale).floor()
	_panel.position = Vector2(_ui_root.size.x - 240, 30)


## Where the window shows more than the room's pictures hold, the walls fade a pixel at a time into shadow.
func _draw_edges() -> void:
	var shown := Rect2(-_origin, Vector2(480, 270) + Vector2(_origin.x * 2.0, _origin.y))
	var art := Rect2(-SIDE, -ABOVE, 480 + SIDE * 2.0, 270 + ABOVE)
	if art.encloses(shown):
		return
	var steps := int(FADE / DETAIL)
	for k in steps:
		var a := 1.0 - float(k + 1) / (steps + 1)
		var inset := k * DETAIL
		if shown.position.x < art.position.x:
			_edges.draw_rect(Rect2(art.position.x + inset, shown.position.y, DETAIL, shown.size.y), Color(DARK, a))
			_edges.draw_rect(Rect2(art.end.x - inset - DETAIL, shown.position.y, DETAIL, shown.size.y), Color(DARK, a))
		if shown.position.y < art.position.y:
			_edges.draw_rect(Rect2(shown.position.x, art.position.y + inset, shown.size.x, DETAIL), Color(DARK, a))
	_edges.draw_rect(Rect2(shown.position.x, shown.position.y, art.position.x - shown.position.x, shown.size.y), DARK)
	_edges.draw_rect(Rect2(art.end.x, shown.position.y, shown.end.x - art.end.x, shown.size.y), DARK)
	_edges.draw_rect(Rect2(shown.position.x, shown.position.y, shown.size.x, art.position.y - shown.position.y), DARK)


func enter() -> void:
	visible = true
	_ui_layer.visible = true
	_panel.visible = false
	_selected = ""
	_dress_room()
	_signature = ""
	_refresh()


func leave() -> void:
	Dissolve.play(self, func() -> void:
		visible = false
		_ui_layer.visible = false
		left_house.emit())


func ruined() -> bool:
	return Game.villa_stage < 2


## The room's picture for the farmhouse as it stands.
func _room_picture() -> String:
	# From the villa rustica on, the walls are freshly painted rather than worn.
	return "ruin.png" if ruined() else ("painted.png" if Game.villa_stage >= 3 else "empty.png")


## Shows the ruin or the restored room, the furnishings bought so far, and the pets napping in their places.
func _dress_room() -> void:
	_room = _room_picture()
	_base.texture = load(DIR + _room)
	for id in _sprites:
		_sprites[id].visible = not ruined() and Game.furnishings.has(id)
	for pet in [_dog, _cat, _dog_shadow, _cat_shadow]:
		pet.visible = not ruined()
		pet.modulate.a = 1.0 if Game.is_night() else 0.0
	if ruined():
		return
	var dog: Dictionary = Game.pets.get("dog", {})
	var dog_dir := Coats.breed_dir("dog", String(dog.get("breed", "")))
	var dog_look := func(tex: Texture2D) -> Texture2D: return Coats.recolour(tex, "dog", String(dog.get("coat", "")), String(dog.get("breed", "")))
	var f := SpriteFrames.new()
	f.remove_animation("default")
	# Lying down is the first four pictures of the sleep folder; the sleeping loop is the rest.
	Frames.add_folder(f, "sleep", dog_dir + "sleep_east/", 3.0, true, dog_look, 4)
	Frames.add_folder(f, "lie_down", dog_dir + "sleep_east/", 6.0, false, dog_look)
	while f.get_frame_count("lie_down") > 4:
		f.remove_frame("lie_down", 4)
	Frames.add_folder(f, "happy", dog_dir + "happy_east/", 12.0, true, dog_look, 1)
	# The dog is put back to sleep with its new pictures, so a stroke it was waking from is over.
	if _dog_tween:
		_dog_tween.kill()
	_dog_awake = false
	_dog_offsets = {}
	for anim in f.get_animation_names():
		_dog_offsets[anim] = Frames.anchor(f.get_frame_texture(anim, 0))
	_dog.sprite_frames = f
	_dog_play("sleep")
	_dog.position = Vector2(102, 246)
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
	_cat.position = Vector2(280, 118)
	_fit()


func _process(delta: float) -> void:
	if not visible:
		return
	# Builders can finish the farmhouse while the player is inside; a dog up from a stroke lies down first.
	if _room_picture() != _room and not _dog_awake:
		_dress_room()
	_t += delta
	var night := Lighting.night_amount(Game.day_time)
	var day: Color = Lighting.color_at(Game.day_time)
	var warmth := 0.0
	if not ruined():
		# Indoors the room is never as dark as the night outside, and the fire and lamps warm it further.
		warmth = 0.08 + (0.05 if Game.furnishings.has("fire") else 0.0) + (0.03 if Game.furnishings.has("lamps") else 0.0)
	_light.color = day.lerp(Color(1.0, 0.86, 0.68), warmth * night).lerp(Color(1.0, 0.97, 0.92), 0.4 * (1.0 - night))
	var fire := 0.8 + 0.2 * sin(_t * 7.0) * sin(_t * 2.3)
	_fire_light.shine((0.25 + 0.75 * night) * fire if Game.furnishings.has("fire") and not ruined() else 0.0)
	for lamp in _lamp_lights:
		var lit := Game.furnishings.has("lamps") and not ruined()
		lamp.shine(night * (0.85 + 0.15 * sin(_t * 6.0 + lamp.position.x)) if lit else 0.0)
	# The dog and cat sleep indoors only at night; by day they are out on the farm.
	for pet in [_dog, _cat, _dog_shadow, _cat_shadow]:
		pet.modulate.a = move_toward(pet.modulate.a, 1.0 if Game.is_night() else 0.0, delta)
	if _weaving > 0.0:
		_weaving = maxf(0.0, _weaving - delta)
		_woven = 1.0
	else:
		_woven = maxf(0.0, _woven - delta * 0.5)
	_loom.queue_redraw()
	for h in _hearts:
		h["age"] += delta
	_hearts = _hearts.filter(func(h): return h["age"] < 1.4)
	_glow.queue_redraw()
	# The far hills are outdoors, so they take the estate's own light rather than the room's.
	var outdoor: Color = Lighting.color_at(Game.day_time) * Estate.SEASON_TINT.get(Game.calendar.season_id(), Color.WHITE)
	_far_land.modulate = Color(outdoor, 1.0)
	_far_mountains.modulate = Color(outdoor * Color.WHITE.lerp(Color(0.62, 0.6, 0.7), night), 1.0)
	_marks.queue_redraw()
	_refresh()
	if not Input.get_connected_joypads().is_empty():
		_keep_pad_focus()


## A gamepad always has a button to act on: the furnishing window's while it is open, otherwise Furnish.
func _keep_pad_focus() -> void:
	_outside.focus_mode = Control.FOCUS_ALL
	_furnish.focus_mode = Control.FOCUS_ALL
	if get_viewport().gui_get_focus_owner() != null:
		return
	if _panel.visible:
		Ui.pad_focus(_panel)
	else:
		_furnish.grab_focus()


## A dot of light on the half-detail canvas: placed on its grid and a whole number of its pixels in size.
func _dot(item: CanvasItem, at: Vector2, size: Vector2, colour: Color) -> void:
	item.draw_rect(Rect2((at / DETAIL).floor() * DETAIL, size * DETAIL), colour)


func _draw_glow() -> void:
	var night := Lighting.night_amount(Game.day_time)
	for h in _hearts:
		var a: float = 1.0 - h["age"] / 1.4
		var p: Vector2 = h["at"] + Vector2(sin(h["age"] * 5.0) * 3.0, -h["age"] * 20.0)
		for d in [Vector2(0, 0), Vector2(2, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1), Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(1, 3)]:
			_dot(_glow, p + d * DETAIL, Vector2.ONE, Color(0.92, 0.3, 0.36, a))
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


## Spots that can still be furnished twinkle softly, and the one under the pointer is outlined.
func _draw_marks() -> void:
	if ruined():
		return
	for id in Balance.get_value("interior.furnishings", {}):
		var rects: Array = Game.furnishing_info(id).get("rects", [])
		var shape := _shape(id)
		if id == _hovered and not shape.is_empty():
			# A furnishing with a shape of its own, such as the pool, is outlined along that shape.
			for e in shape.size():
				var a: Vector2 = shape[e]
				var b: Vector2 = shape[(e + 1) % shape.size()]
				var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)) / DETAIL) + 1
				for n in steps + 1:
					_dot(_marks, a.lerp(b, float(n) / steps), Vector2.ONE, MARK)
		elif id == _hovered:
			for r in rects:
				var box := Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1])
				_dot(_marks, box.position - Vector2(DETAIL, DETAIL), Vector2(box.size.x / DETAIL + 2, 1), MARK)
				_dot(_marks, Vector2(box.position.x - DETAIL, box.end.y), Vector2(box.size.x / DETAIL + 2, 1), MARK)
				_dot(_marks, box.position - Vector2(DETAIL, 0), Vector2(1, box.size.y / DETAIL), MARK)
				_dot(_marks, Vector2(box.end.x, box.position.y), Vector2(1, box.size.y / DETAIL), MARK)
		elif not Game.furnishings.has(id) and Game.furnishing_block(id) == "" and not rects.is_empty():
			var r: Array = rects[0]
			var c := Vector2(roundf((r[0] + r[2]) / 2.0), roundf((r[1] + r[3]) / 2.0))
			var a := 0.35 + 0.35 * sin(_t * 2.5 + c.x * 0.1)
			for d in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0), Vector2.ZERO]:
				_dot(_marks, c + d * DETAIL, Vector2.ONE, Color(MARK, a))


## While weaving, the heddle lifts every other warp thread so the shed opens, the shuttle carries the lavender weft
## through it, and the beater swings down to pack the new row against the cloth; the next pass crosses the threads
## the other way. The rows woven this time show along the cloth's edge, and fade once the weaving stops.
func _draw_loom() -> void:
	if ruined() or (_weaving <= 0.0 and _woven <= 0.0):
		return
	var g := func(x: float, y: float, w: float, h: float, colour: Color) -> void:
		_loom.draw_rect(Rect2(Vector2(floorf(x), floorf(y)) * DETAIL, Vector2(w, h) * DETAIL), colour)
	var elapsed := PASSES * PASS_SECONDS - _weaving
	var k := int(clampf(floorf(elapsed / PASS_SECONDS), 0, PASSES - 1))
	var t := fposmod(elapsed, PASS_SECONDS) / PASS_SECONDS if _weaving > 0.0 else 1.0
	# The rows woven so far: a band of lavender weft over and under the warp, brightest where newest.
	var rows := mini(k + (1 if t > 0.75 else 0), PASSES) if _weaving > 0.0 else PASSES
	var fade := 1.0 if _weaving > 0.0 else _woven
	for r in rows:
		var y := FELL_Y - r % 3
		for x in range(WARP_LEFT, WARP_RIGHT, 1):
			var over := (x + r) % 2 == 0
			g.call(x, y, 1, 1, Color(WEFT if over else WEFT_SHADE, fade * (0.75 + 0.25 * float(r == rows - 1))))
	if _weaving <= 0.0:
		return
	# The shed: the raised threads light, the lowered ones in shadow, crossing over the open gap.
	var lift := 1 if k % 2 == 0 else 0
	for x in range(WARP_LEFT, WARP_RIGHT, 2):
		var up := ((x - WARP_LEFT) / 2 + lift) % 2 == 0
		g.call(x, SHED_Y - (2 if up else -1), 1, 2, THREAD if up else THREAD_SHADE)
		g.call(x, SHED_Y, 1, 1, Color(0.1, 0.06, 0.05, 0.6))
	# The heddle bar, lifted or lowered with the threads it carries.
	var hy := HEDDLE_Y - lift
	g.call(WARP_LEFT - 3, hy, WARP_RIGHT - WARP_LEFT + 6, 1, WOOD_LIGHT)
	g.call(WARP_LEFT - 3, hy + 1, WARP_RIGHT - WARP_LEFT + 6, 1, WOOD_DARK)
	# The shuttle crosses in the first part of the pass, trailing its weft; the beater swings in the last part.
	var going_right := k % 2 == 0
	var across := clampf(t / 0.7, 0.0, 1.0)
	across = across * across * (3.0 - 2.0 * across)
	var start := float(WARP_LEFT - 6) if going_right else float(WARP_RIGHT + 6)
	var finish := float(WARP_RIGHT + 6) if going_right else float(WARP_LEFT - 6)
	var sx := lerpf(start, finish, across)
	var from := minf(start, sx)
	var to := maxf(start, sx)
	g.call(maxf(from, WARP_LEFT - 1), SHED_Y + 1, minf(to, WARP_RIGHT + 1) - maxf(from, WARP_LEFT - 1), 1, WEFT)
	if t < 0.7:
		# A little boat of wood with pointed ends, its bobbin of lavender yarn showing in the middle.
		g.call(sx - 3, SHED_Y, 7, 1, WOOD_DARK)
		g.call(sx - 2, SHED_Y - 1, 5, 1, WOOD_LIGHT)
		g.call(sx - 2, SHED_Y, 5, 1, WOOD)
		g.call(sx - 1, SHED_Y + 1, 3, 1, WOOD_DARK)
		g.call(sx, SHED_Y, 1, 1, WEFT)
	else:
		var swing := sin(clampf((t - 0.7) / 0.3, 0.0, 1.0) * PI)
		var by := lerpf(SHED_Y - 3, FELL_Y - 1, swing)
		g.call(WARP_LEFT - 2, by, WARP_RIGHT - WARP_LEFT + 4, 1, WOOD_LIGHT)
		g.call(WARP_LEFT - 2, by + 1, WARP_RIGHT - WARP_LEFT + 4, 1, WOOD_DARK)


func _pet_at(point: Vector2) -> AnimatedSprite2D:
	if ruined():
		return null
	for pet in [_cat, _dog]:
		if pet.modulate.a < 0.5 or pet.sprite_frames == null or not pet.sprite_frames.has_animation(pet.animation):
			continue
		var tex: Texture2D = pet.sprite_frames.get_frame_texture(pet.animation, pet.frame)
		var used := Rect2(tex.get_image().get_used_rect())
		var box := Rect2(pet.position + (pet.offset + used.position) * DETAIL, used.size * DETAIL)
		if box.grow(2).has_point(point):
			return pet
	return null


## A point on the screen as a pixel of the painting.
func _picture_point(ui_point: Vector2) -> Vector2:
	return (ui_point * Windowing.ui_scale - _display.position) / _display.scale.x * DETAIL - _origin


## A furnishing's own outline, as points, for one whose spot is not a simple box.
func _shape(id: String) -> PackedVector2Array:
	var points := PackedVector2Array()
	for pt in Game.furnishing_info(id).get("shape", []):
		points.append(Vector2(pt[0], pt[1]))
	return points


func _spot_at(point: Vector2) -> String:
	if ruined():
		return ""
	for id in Balance.get_value("interior.furnishings", {}):
		var shape := _shape(id)
		if not shape.is_empty():
			if Geometry2D.is_point_in_polygon(point, shape):
				return String(id)
			continue
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
		_wake_dog()
	else:
		Sfx.play("cat", -4.0)
	Game.add_stat("pets", 1)
	_hearts.append({"at": pet.position + Vector2(6 if dog else 0, -26 if dog else -30), "age": 0.0})
	if not dog:
		_stir(pet)


## A stroked cat stirs without waking: a little wriggle, then it settles.
func _stir(pet: AnimatedSprite2D) -> void:
	if _stirring.has(pet):
		return
	_stirring[pet] = true
	var tween := create_tween()
	for k in 3:
		tween.tween_property(pet, "position:y", pet.position.y - DETAIL, 0.1)
		tween.tween_property(pet, "position:y", pet.position.y, 0.1)
	tween.tween_callback(func(): _stirring.erase(pet))


func _dog_play(anim: String, backwards := false) -> void:
	if not _dog.sprite_frames.has_animation(anim):
		return
	_dog.offset = _dog_offsets.get(anim, Vector2.ZERO)
	if backwards:
		_dog.play_backwards(anim)
	else:
		_dog.play(anim)


## Stroked, the sleeping dog rises from the rug, wags its tail for a little while, then lies back down and sleeps.
func _wake_dog() -> void:
	if _dog_awake or not _dog.sprite_frames.has_animation("happy"):
		return
	_dog_awake = true
	var frames := _dog.sprite_frames
	var rise := frames.get_frame_count("lie_down") / frames.get_animation_speed("lie_down") if frames.has_animation("lie_down") else 0.0
	_dog_play("lie_down", true)
	_dog_tween = create_tween()
	_dog_tween.tween_interval(rise)
	_dog_tween.tween_callback(_dog_play.bind("happy"))
	_dog_tween.tween_interval(2.6)
	_dog_tween.tween_callback(_dog_play.bind("lie_down"))
	_dog_tween.tween_interval(rise)
	_dog_tween.tween_callback(func():
		_dog_play("sleep")
		_dog_awake = false)


## A few passes of the shuttle, each beaten home with a soft knock.
func _weave() -> void:
	if _weaving > 0.0:
		return
	_weaving = PASSES * PASS_SECONDS
	# The shuttle hisses through, then the beater knocks the row home.
	for k in PASSES:
		get_tree().create_timer(PASS_SECONDS * k + 0.1).timeout.connect(func(): Sfx.play("rustle", -18.0, 0.15))
		get_tree().create_timer(PASS_SECONDS * (k + 0.85)).timeout.connect(func(): Sfx.play("made", -14.0, 0.1))


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
		Ui.fade_in(_panel)
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
	var focus := Ui.focus_hint(_panel)
	Ui.clear(_list)
	(func(): Ui.pad_focus(_panel, focus)).call_deferred()
	if ruined():
		_title.text = tr("A ruin")
		Ui.para(_list, tr("Wind and rain come in through the roof. Restore the farmhouse to make it a home, then furnish it room by room."), 210)
		return
	_title.text = tr(String(Game.furnishing_info(_selected).get("name", ""))) if _selected != "" else tr("Furnish the house")
	var ids: Array = [_selected] if _selected != "" else Balance.get_value("interior.furnishings", {}).keys()
	for id in ids:
		_furnishing_card(String(id), _selected == "")
	if _selected != "":
		Ui.button(_list, tr("See everything"), func(): _open(""))
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
	var card := Ui.card(_list)
	if named:
		Ui.label(card, tr(String(f.get("name", "")))).add_theme_color_override("font_color", UiTheme.HEADING)
	Ui.para(card, tr(String(f.get("desc", ""))), 200)
	if Game.furnishings.has(id):
		Ui.label(card, tr("In place")).add_theme_color_override("font_color", UiTheme.MUTED)
		return
	var block := Game.furnishing_block(id)
	if block != "":
		Ui.para(card, tr(block), 200).add_theme_color_override("font_color", UiTheme.RED)
		return
	var r := Ui.row(card)
	var buy := Ui.button(r, tr("Buy for %d sestertii") % int(f.get("price", 0)), func():
		if Game.buy_furnishing(id):
			Sfx.play("coins", -6.0)
			# Each furnishing arrives with its own sound: a fire lit, pots set down.
			for sound in f.get("sounds", []):
				Sfx.play(String(sound), -2.0)
			_sprites[id].visible = true
			Ui.fade_in(_sprites[id], 0.6)
			_signature = "")
	buy.disabled = Game.coins < int(f.get("price", 0))
