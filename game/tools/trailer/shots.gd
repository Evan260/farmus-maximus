extends Node
## The trailer's scripted shots: each one sets the estate up, moves the camera and clicks things with a drawn pointer,
## so tools/trailer/make_trailer.py can record it in movie mode the same way every time.
## Started by debug_tools.gd with --trailer-shot=NAME; the shot list and timings are in make_trailer.py.

## The estate scene, supplied by debug_tools.gd.
var m: Node
var shot := ""
var _pointer: Sprite2D
var _young := false
## True in the narrow portrait view of the short cut, where each shot frames its subject rather than a whole zone.
var _narrow := false
var _ring: Sprite2D


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_pointer = Sprite2D.new()
	_pointer.texture = _arrow()
	_pointer.centered = false
	_pointer.scale = Vector2.ONE * Windowing.scale
	_pointer.visible = false
	layer.add_child(_pointer)
	_ring = Sprite2D.new()
	_ring.texture = _ring_texture()
	_ring.scale = Vector2.ONE * Windowing.scale
	_ring.modulate.a = 0.0
	layer.add_child(_ring)
	# The estate's own setup runs first, then the shot takes over.
	await get_tree().process_frame
	await get_tree().process_frame
	_narrow = m._view_size().x < 300
	# The Triumph's wreath and the enlarged storehouse belong on the finished estate, not on the young farm.
	_young = Game.villa_stage < Game.villa_stages().size()
	# Its storehouse is the small first one, holding what a young farm would, so it has room for the harvest.
	if _young:
		Game.levels["storage"] = 1
		Game.storage = {"lavender": 7, "bread": 4, "olive_oil": 2, "dried_lavender": 3, "stone": 4, "timber": 2}
		m._dress_storehouse()
	# Every working building has a batch on, so the mill turns, the presses work and the oven burns while in view.
	if not m.hud.visible:
		for id in Game.buildings:
			if Game.buildings[id]["state"] == "working":
				for item in Game.current_recipe(id).get("in", {}):
					Game.add_item(String(item), 40, true)
				Game.load_building(id)
	if m.hud.visible:
		Game.aureus = 0
		# The cart parks along the bottom edge, where the toolbar would hide it; the interface shows it again each frame.
		if shot != "plant":
			m.hud._toolbar.modulate.a = 0.0
	# Shots such as the town or the house are set up wholly by their launch flags and have no script of their own.
	if has_method("_shot_" + shot):
		call("_shot_" + shot)


## The wreath is hidden rather than the Triumph taken away, which the game would award again with a fanfare.
func _process(_delta: float) -> void:
	if _young and m.villa._wreath:
		m.villa._wreath.visible = false


# Shots -------------------------------------------------------------------

## Golden hour on the finished estate: a slow drift along the lavender towards the villa.
func _shot_hook() -> void:
	_look_at(Estate.HOME + 150)
	_pan(70.0, 9.0)


## The farm as Uncle Marcus left it: the ruined farmhouse behind bare beds.
func _shot_ruin() -> void:
	for i in Game.plots.size():
		if Game.plots[i]["zone"] == "home":
			Game.plots[i]["crop"] = ""
			Game.plots[i]["growth"] = 0.0
	_look_at(Estate.VILLA_BASE.x if _narrow else Estate.HOME + 240)
	_pan(10.0 if _narrow else 18.0, 6.0)


## The core loop by hand: pick the lavender in bloom, then sow the empty beds.
func _shot_plant() -> void:
	for i in Game.plots.size():
		if Game.plots[i]["zone"] == "home" and not Game.plots[i]["unlocked"]:
			Game.plots[i]["unlocked"] = true
			Game.plots[i]["crop"] = ""
	_look_at(Estate.HOME + 200)
	await _wait(1.6)
	_pointer.visible = true
	_pointer.position = Vector2(_screen(Vector2(m.cam_x + m._view_size().x / 2.0 + 10, 200)))
	m.hud.select_tool("harvest")
	for v in _beds_in_view(func(i): return Game.plot_visual(i) == "bloom").slice(0, 3):
		await _click_plot(v)
	m.hud.select_tool("seed:lavender")
	for v in _beds_in_view(func(i): return Game.plot_visual(i) == "empty").slice(0, 2):
		await _click_plot(v)


## The cart sets off for market with the day's goods.
func _shot_cart() -> void:
	_look_at(Estate.CART_HOME_X + 170)
	await _wait(1.8)
	Game.send_cart()


## The cart comes home from market with the takings; the road is long, so the clip is cut from its last stretch.
## The game pays as the trip ends, before the cart is back in view, so here the coins arrive with the cart instead.
func _shot_coins() -> void:
	_look_at(Estate.CART_HOME_X + 170)
	Game.cart_returned.connect(func(value: int) -> void:
		Game.coins -= value
		await m._rig_tween.finished
		Game.coins += value, CONNECT_ONE_SHOT)
	Game.cart = {"away": true, "time_left": 0.2, "items": 16, "value": 1260, "load": []}


## The farmhand at work in the home beds; the narrow view finds her before the part that is used.
func _shot_helper() -> void:
	_look_at(Estate.HOME + 240)
	if _narrow and m._helpers.has("farmhand"):
		await _wait(1.3)
		var hand: Node2D = m._helpers["farmhand"]
		_look_at(hand.position.x)
		# Close up there is no room for the pets to wander past her: the dog sits a little behind her, on the side she
		# is walking away from, and the cat is out of sight.
		var behind := 1.0 if hand.sprite.flip_h else -1.0
		m.dog.position.x = hand.position.x + 46.0 * behind
		m.dog.sprite.flip_h = behind > 0.0
		m.dog._state = "sit"
		m.dog._timer = 60.0
		m.dog.sprite.play("sit")
		m.cat.position.x = m.cam_x - 80.0


## The yard at dusk, the bakery's ovens alight.
func _shot_bakery() -> void:
	Game.buildings["bakery"]["state"] = "working"
	Game.add_item("flour", 40, true)
	Game.load_building("bakery")
	Game.building_changed.emit("bakery")
	_look_at(_building_x("bakery") if _narrow else Game.zone_info("yard")["x"] + 240)


## The villa grows: the scaffold goes up, and comes down on the next stage.
func _shot_villa() -> void:
	_look_at(Estate.VILLA_BASE.x)
	# The demo farm builds five times faster than the game; here the scaffold has time to rise before the reveal.
	Game.build_speed = 1.0
	await _wait(1.0)
	Game.upgrade_villa()
	Game.villa_build["time_left"] = 2.4


func _shot_pasture() -> void:
	_look_at(Game.zone_info("pasture")["x"] + 240)


func _shot_vineyard() -> void:
	_look_at(_building_x("wine_press") if _narrow else Game.zone_info("vineyard")["x"] + 240)
	_pan(-12.0 if _narrow else -30.0, 6.0)


func _shot_grove() -> void:
	_look_at(Game.zone_info("grove")["x"] + 240)


## The hoopoe drops into the middle of the view, is clicked, calls and flies off.
func _shot_hoopoe() -> void:
	_look_at(Estate.HOME + 240)
	await _wait(1.0)
	var bird: Sprite2D = m._wildlife._hoopoe
	var middle: float = m.cam_x + m._view_size().x / 2.0
	m._wildlife.land_hoopoe(Rect2(middle - 40, 0, 80, 270))
	bird.position = Vector2(middle, 277)
	bird.flip_h = false
	await _wait(1.2)
	await _click_on(bird.position + Vector2(-2, -8))


## Inside the farmhouse by night, the fire lit and the dog stroked; the house's own top bar is hidden.
func _shot_inside() -> void:
	await _wait(0.2)
	m.interior._ui_root.get_child(0).modulate.a = 0.0


## A morning in the market town; the market's own top bar is hidden.
func _shot_town() -> void:
	await _wait(0.6)
	m.market._ui_root.get_child(0).modulate.a = 0.0


## The dog on the path is petted, and hearts rise. The camera finds the dog before the part the trailer uses.
func _shot_pet() -> void:
	await _wait(1.4)
	_look_at(m.dog.position.x)
	await _wait(0.6)
	await _click_on(m.dog.position + Vector2(0, -8))


## A whole day passes in a few seconds while the helpers keep at it.
func _shot_timelapse() -> void:
	_look_at(Estate.VILLA_BASE.x if _narrow else Estate.HOME + 240)
	Game.speed = 160.0


## The finished estate by night: lamplit windows, fireflies, the Milky Way.
func _shot_night() -> void:
	_look_at(Estate.VILLA_BASE.x + 30 if _narrow else Estate.HOME + 420)
	_pan(-30.0 if _narrow else -60.0, 9.0)


## The view behind the logo at the end: the vineyard hills at dusk.
func _shot_endcard() -> void:
	_look_at(Game.zone_info("vineyard")["x"] + 240)


# Camera and pointer ------------------------------------------------------

## The middle of a building's doorway, for framing it in the narrow view.
func _building_x(id: String) -> float:
	for v in m.building_views:
		if v.id == id:
			return m._door_x(v)
	return m.cam_x + m._view_size().x / 2.0


func _look_at(x: float) -> void:
	m.cam_x = x - m._view_size().x / 2.0
	m._update_view()


func _pan(dx: float, seconds: float) -> void:
	var from: float = m.cam_x
	create_tween().tween_method(func(x): m.cam_x = x; m._update_view(), from, from + dx, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _screen(world: Vector2) -> Vector2:
	return ((world - Vector2(m.cam_x, m._camera.position.y)) * Windowing.scale).round()


## Beds in the middle of the view whose state matches, front row first, from left to right.
func _beds_in_view(wanted: Callable) -> Array:
	var margin := 20.0 if _narrow else 60.0
	var left: float = m.cam_x + margin
	var right: float = m.cam_x + m._view_size().x - margin
	var beds: Array = m.plot_views.filter(func(v): return v.position.x > left and v.position.x < right and wanted.call(v.index))
	beds.sort_custom(func(a, b): return a.position.y > b.position.y if a.position.y != b.position.y else a.position.x < b.position.x)
	return beds


## The pointer comes in along the path from the lower left, clicks, then drifts back down out of the way, so it never
## passes over the beds or covers what the click sets off.
func _click_on(at: Vector2) -> void:
	_pointer.visible = true
	_pointer.position = _screen(at + Vector2(-40, 10))
	await _move_to(at)
	await _press()
	m._click(at)
	await _wait(0.15)
	_move_to(at + Vector2(-26, 12))


func _click_plot(v: Node2D) -> void:
	await _move_to(v.position + Vector2(15, -6))
	await _press()
	m._click_plot(v.index)
	await _wait(0.25)


func _move_to(world: Vector2) -> void:
	var t := create_tween()
	t.tween_property(_pointer, "position", _screen(world), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished


## The pointer dips a pixel and a small ring spreads from its tip, so a click reads on screen.
func _press() -> void:
	_pointer.position.y += Windowing.scale
	_ring.position = _pointer.position
	_ring.scale = Vector2.ONE * Windowing.scale * 0.5
	_ring.modulate.a = 1.0
	var t := create_tween().set_parallel()
	t.tween_property(_ring, "scale", Vector2.ONE * Windowing.scale * 1.2, 0.3)
	t.tween_property(_ring, "modulate:a", 0.0, 0.3)
	await _wait(0.08)
	_pointer.position.y -= Windowing.scale


## The familiar arrow pointer, drawn in the interface's ink and parchment.
static func _arrow() -> Texture2D:
	var rows := [
		"X.........",
		"XX........",
		"XoX.......",
		"XooX......",
		"XoooX.....",
		"XooooX....",
		"XoooooX...",
		"XooooooX..",
		"XoooooooX.",
		"XooooooooX",
		"XoooooXXXX",
		"XooXooX...",
		"XoX.XooX..",
		"XX..XooX..",
		"X....XooX.",
		".....XooX.",
		"......XX..",
	]
	var img := Image.create(10, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 10:
			var c: String = rows[y][x]
			if c == "X":
				img.set_pixel(x, y, Color(0.29, 0.18, 0.14))
			elif c == "o":
				img.set_pixel(x, y, Color(0.99, 0.95, 0.86))
	return ImageTexture.create_from_image(img)


static func _ring_texture() -> Texture2D:
	var img := Image.create(11, 11, false, Image.FORMAT_RGBA8)
	for y in 11:
		for x in 11:
			var d := Vector2(x - 5, y - 5).length()
			if d > 3.6 and d < 4.8:
				img.set_pixel(x, y, Color(0.99, 0.95, 0.86, 0.9))
	return ImageTexture.create_from_image(img)
