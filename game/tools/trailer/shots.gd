extends Node
## The trailer's scripted shots: each one sets the estate up, moves the camera and clicks things with a drawn pointer,
## so tools/trailer/make_trailer.py can record it in movie mode the same way every time.
## Started by debug_tools.gd with --trailer-shot=NAME; the shot list and timings are in make_trailer.py.

## The estate scene, supplied by debug_tools.gd.
var m: Node
var shot := ""
var _pointer: Sprite2D
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
	# Where the interface shows, the storehouse holds what a young farm would, not the demo's piles of everything.
	if m.hud.visible:
		Game.levels["storage"] = 1
		Game.storage = {"lavender": 7, "bread": 4, "olive_oil": 2, "dried_lavender": 3, "stone": 4, "timber": 2}
		Game.aureus = 0
		# The cart parks along the bottom edge, where the toolbar would hide it; the interface shows it again each frame.
		if shot != "plant":
			m.hud._toolbar.modulate.a = 0.0
	# Shots such as the town or the house are set up wholly by their launch flags and have no script of their own.
	if has_method("_shot_" + shot):
		call("_shot_" + shot)


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
	_look_at(Estate.HOME + 240)
	_pan(18.0, 6.0)


## The core loop by hand: pick the lavender in bloom, then sow the empty beds.
func _shot_plant() -> void:
	for i in Game.plots.size():
		if Game.plots[i]["zone"] == "home" and not Game.plots[i]["unlocked"]:
			Game.plots[i]["unlocked"] = true
			Game.plots[i]["crop"] = ""
	_look_at(Estate.HOME + 200)
	await _wait(1.6)
	_pointer.visible = true
	_pointer.position = Vector2(_screen(Vector2(m.cam_x + 250, 200)))
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


## The farmhand at work in the home beds.
func _shot_helper() -> void:
	_look_at(Estate.HOME + 240)


## The yard at dusk, the bakery's ovens alight.
func _shot_bakery() -> void:
	Game.buildings["bakery"]["state"] = "working"
	Game.building_changed.emit("bakery")
	_look_at(Game.zone_info("yard")["x"] + 240)


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
	_look_at(Game.zone_info("vineyard")["x"] + 240)
	_pan(-30.0, 6.0)


func _shot_grove() -> void:
	_look_at(Game.zone_info("grove")["x"] + 240)


## The hoopoe drops into the middle of the view, is clicked, calls and flies off.
func _shot_hoopoe() -> void:
	_look_at(Estate.HOME + 240)
	await _wait(1.0)
	var bird: Sprite2D = m._wildlife._hoopoe
	m._wildlife.land_hoopoe(Rect2(m.cam_x + 200, 0, 80, 270))
	bird.position = Vector2(m.cam_x + 240, 277)
	bird.flip_h = false
	await _wait(1.2)
	_pointer.visible = true
	var at := bird.position + Vector2(-2, -8)
	_pointer.position = _screen(at + Vector2(-34, -16))
	await _move_to(at)
	await _press()
	m._click(at)
	# The pointer drifts aside after the click, so it never covers what happens next.
	await _wait(0.15)
	_move_to(at + Vector2(-22, 16))


## Inside the farmhouse by night, the fire lit and the dog stroked; the house's own top bar is hidden.
func _shot_inside() -> void:
	await _wait(0.2)
	m.interior._ui_root.get_child(0).modulate.a = 0.0


## A morning in the market town; the market's own top bar is hidden.
func _shot_town() -> void:
	await _wait(0.6)
	m.market._ui_root.get_child(0).modulate.a = 0.0


## The cat on the farm is stroked, and hearts rise.
func _shot_pet() -> void:
	_look_at(Estate.HOME + 400)
	await _wait(2.0)
	_pointer.visible = true
	var at: Vector2 = m.cat.position + Vector2(0, -6)
	_pointer.position = _screen(at + Vector2(30, -20))
	await _move_to(at)
	await _press()
	m._click(at)
	# The pointer drifts aside after the click, so it never covers what happens next.
	await _wait(0.15)
	_move_to(at + Vector2(-22, 16))


## A whole day passes in a few seconds while the helpers keep at it.
func _shot_timelapse() -> void:
	_look_at(Estate.HOME + 240)
	Game.speed = 160.0


## The finished estate by night: lamplit windows, fireflies, the Milky Way.
func _shot_night() -> void:
	_look_at(Estate.HOME + 420)
	_pan(-60.0, 9.0)


## The view behind the logo at the end: the vineyard hills at dusk.
func _shot_endcard() -> void:
	_look_at(Game.zone_info("vineyard")["x"] + 240)


# Camera and pointer ------------------------------------------------------

func _look_at(x: float) -> void:
	m.cam_x = x - m._view_size().x / 2.0
	m._update_view()


func _pan(dx: float, seconds: float) -> void:
	var from: float = m.cam_x
	create_tween().tween_method(func(x): m.cam_x = x; m._update_view(), from, from + dx, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _screen(world: Vector2) -> Vector2:
	return ((world - m._camera.position) * Windowing.scale).round()


## Beds in the middle of the view whose state matches, front row first, from left to right.
func _beds_in_view(wanted: Callable) -> Array:
	var left: float = m.cam_x + 60
	var right: float = m.cam_x + m._view_size().x - 60
	var beds: Array = m.plot_views.filter(func(v): return v.position.x > left and v.position.x < right and wanted.call(v.index))
	beds.sort_custom(func(a, b): return a.position.y > b.position.y if a.position.y != b.position.y else a.position.x < b.position.x)
	return beds


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


## A small pixel arrow in the interface's ink and parchment.
static func _arrow() -> Texture2D:
	var rows := [
		"X.......",
		"XX......",
		"XoX.....",
		"XooX....",
		"XoooX...",
		"XooooX..",
		"XoooooX.",
		"XooooooX",
		"XoooXXXX",
		"XoXooX..",
		"XX.XooX.",
		"X...XoX.",
		".....X..",
	]
	var img := Image.create(8, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 8:
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
