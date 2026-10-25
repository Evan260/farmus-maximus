extends Node2D
## Builds the estate from its layers and buildings, pans across it, and turns clicks into farm actions.

const PlotView := preload("res://scripts/plot_view.gd")
const BuildingView := preload("res://scripts/building_view.gd")
const ZoneSign := preload("res://scripts/zone_sign.gd")
const Dog := preload("res://scripts/dog.gd")
const Critters := preload("res://scripts/critters.gd")
const Fireflies := preload("res://scripts/fireflies.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const BG := "res://assets/backgrounds/estate/"
const OLD_BG := "res://assets/backgrounds/home_farm/"
const ESTATE_WIDTH := 1920.0
## The home farm is the second zone, so everything on it sits one screen to the right.
const HOME := 480.0
## Bottom centre of the villa, where the path in the field meets its steps.
const VILLA_BASE := Vector2(HOME + 371, 237)
const FRONT_ROW := 263
const BACK_ROW := 246
const SHADOW := Color(0.16, 0.11, 0.12, 0.28)
## How far each background layer moves for every pixel the camera pans: the far ones barely move, which gives depth.
const PARALLAX := {"sky": 0.05, "mountains": 0.1, "land": 0.18}
## Where the cart parks, on the soil just right of the path, with the donkey at its handles.
const CART_HOME_X := HOME + 380.0
const RIG_BASE := 266
const PAN_SPEED := 260.0

var plot_views: Array = []
var building_views: Array = []
var signs: Array = []
var hud: CanvasLayer
var dog: Node2D
## The left edge of the view in estate pixels.
var cam_x := 0.0
var _daylight: CanvasModulate
var _sky_node: Node2D
var _sky_day: Sprite2D
var _sky_night: Sprite2D
var _mountains: Sprite2D
var _land: Sprite2D
var _villa: Sprite2D
var _villa_shadow: Sprite2D
var _villa_outline: Node2D
var _villa_hovered := false
var _cart: Sprite2D
var _cart_shadow: Sprite2D
var _donkey: AnimatedSprite2D
var _rig_tween: Tween
var _storehouse: Sprite2D
var _glow_layer: CanvasLayer
var _window_glow: Sprite2D
var _clouds: Array = []
var _hammer_timer := 0.0
var _camera: Camera2D
var _sky_layer: CanvasLayer
var _zone_shade: Node2D
## Painted scenery that is hidden in the transparent desktop strip, so only the farm floats over the desktop.
var _scenery: Array = []
var _click_area_timer := 0.0
## The plot chosen with the keyboard or a gamepad, or -1 when the mouse is in use.
var _selected := -1
var _drag_from := Vector2.ZERO
var _drag_start_cam := 0.0
var _dragging := false
var _pressed := false
var _pan_tween: Tween


func _ready() -> void:
	if "--demo" in OS.get_cmdline_user_args():
		_load_demo_state()
	_daylight = CanvasModulate.new()
	add_child(_daylight)
	# The sky gets its own layer, outside the night tint, so the night sky's stars and moon keep their own colours.
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = -1
	_sky_layer.follow_viewport_enabled = true
	add_child(_sky_layer)
	_sky_node = Node2D.new()
	_sky_layer.add_child(_sky_node)
	_sky_day = _add_texture(load(BG + "layer_sky.png"), Vector2.ZERO, _sky_node)
	_sky_night = _add_texture(load(BG + "layer_sky_night.png"), Vector2.ZERO, _sky_node)
	for i in 3:
		var c := _add_trimmed(load(OLD_BG + "cloud_%d.png" % (i + 1)), Vector2([60, 330, 560][i], [18, 52, 30][i]), false, 0, _sky_node)
		_clouds.append({"sprite": c, "speed": [2.2, 1.4, 3.0][i]})
	_glow_layer = CanvasLayer.new()
	_glow_layer.layer = 1
	_glow_layer.follow_viewport_enabled = true
	add_child(_glow_layer)
	_mountains = _add_texture(load(BG + "layer_mountains.png"), Vector2.ZERO)
	_land = _add_texture(load(BG + "layer_land.png"), Vector2.ZERO)
	_scenery.append_array([_mountains, _land])

	var pine := _add_trimmed(load("res://assets/sprites/trees/umbrella_pine_1.png"), Vector2(HOME - 60, 0), true, 240)
	_scenery.append(pine)
	_scenery.append(_add_texture(Lighting.ellipse_texture(64, 7, SHADOW), Vector2(pine.position.x + pine.region_rect.size.x / 2 - 32, 236)))
	_villa_shadow = _add_texture(null, Vector2.ZERO)
	_villa = _add_trimmed(_villa_texture(), Vector2.ZERO)
	_window_glow = _add_texture(null, Vector2.ZERO, _glow_layer)
	_window_glow.region_enabled = true
	_villa_outline = Node2D.new()
	_villa_outline.draw.connect(func(): if _villa_hovered: _villa_outline.draw_rect(_villa_rect().grow(1), Color(1, 0.96, 0.85, 0.7), false, 1.0))
	add_child(_villa_outline)
	_place_villa()
	_add_texture(Lighting.ellipse_texture(70, 7, SHADOW), Vector2(HOME + 194, 230))
	_storehouse = _add_trimmed(load("res://assets/sprites/farm/storehouse.png"), Vector2(HOME + 198, 0), true, 236)
	_build_buildings()
	_add_texture(load(BG + "ground.png"), Vector2(-40, 0))
	_zone_shade = Node2D.new()
	_zone_shade.draw.connect(_draw_zone_shade)
	add_child(_zone_shade)
	_build_plots()
	_build_signs()

	var critters := Critters.new()
	critters.bloom_points = _bloom_points
	add_child(critters)
	dog = Dog.new()
	dog.position = Vector2(HOME + 345, 268)
	dog.min_x = HOME + 10
	dog.max_x = HOME + 456
	add_child(dog)
	_cart_shadow = _add_texture(Lighting.ellipse_texture(96, 6, SHADOW), Vector2.ZERO)
	_cart = _add_trimmed(load("res://assets/sprites/farm/cart.png"), Vector2(CART_HOME_X, 0), true, RIG_BASE)
	_donkey = AnimatedSprite2D.new()
	_donkey.sprite_frames = _donkey_frames()
	_donkey.centered = false
	_donkey.offset = Vector2(-32, -_feet_line(load("res://assets/sprites/donkey/walk_east/frame_00.png")))
	_donkey.play("stand")
	add_child(_donkey)
	_park_rig()

	_glow_layer.add_child(Fireflies.new())
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_camera.make_current()
	get_viewport().size_changed.connect(_update_view)
	Windowing.view_changed.connect(_update_view)
	hud = Hud.new()
	hud.zone_chosen.connect(pan_to_zone)
	add_child(hud)

	Game.planted.connect(func(i): Sfx.play("plant"); _view(i).bounce())
	Game.unlocked.connect(func(_i): Sfx.play("unlock"))
	Game.harvested.connect(_on_harvested)
	Game.villa_build_started.connect(func(_stage): _on_build_started())
	Game.villa_upgraded.connect(func(_stage): _on_villa_finished())
	Game.cart_left.connect(_on_cart_left)
	Game.cart_returned.connect(_on_cart_returned)
	Game.zone_bought.connect(_on_zone_bought)
	Game.building_changed.connect(_on_building_changed)
	Game.building_made.connect(_on_building_made)
	dog.petted.connect(_on_dog_petted)
	if Game.cart["away"]:
		_cart.position.x = ESTATE_WIDTH + 60
		_donkey.position.x = ESTATE_WIDTH + 130
	cam_x = HOME + 240.0 - get_viewport_rect().size.x / 2.0
	_update_view()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			var z := Game.zone_info(arg.trim_prefix("--zone="))
			cam_x = float(z.get("x", 0)) + 240.0 - get_viewport_rect().size.x / 2.0
			_update_view()
		elif arg.begins_with("--shot="):
			_take_screenshot(arg.trim_prefix("--shot="))


## Saves exactly what the window shows after the scene settles, then quits; used for store screenshots and layout checks.
func _take_screenshot(path: String) -> void:
	for i in 45:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


func _process(delta: float) -> void:
	var night := Lighting.night_amount(Game.day_time)
	_daylight.color = Lighting.color_at(Game.day_time)
	_sky_day.modulate = _daylight.color
	_sky_night.modulate.a = night
	_window_glow.modulate.a = night
	for c in _clouds:
		var sprite: Sprite2D = c["sprite"]
		sprite.position.x += c["speed"] * delta
		if sprite.position.x > 770:
			sprite.position.x = -sprite.region_rect.size.x - 10
		# The drifting day clouds fade out at night, when the night sky has clouds of its own.
		sprite.modulate = Color(_daylight.color, 1.0 - night)
	var keys := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if keys != 0.0:
		_pan_by(keys * PAN_SPEED * delta)
	_cart_shadow.position = Vector2(_cart.position.x - 2, RIG_BASE - 5)
	if Windowing.strip and Windowing.transparent:
		_click_area_timer -= delta
		if _click_area_timer <= 0.0:
			_click_area_timer = 0.5
			Windowing.set_click_area(_click_area())
	if Game.villa_build["active"]:
		_hammer_timer -= delta
		if _hammer_timer <= 0.0:
			_hammer_timer = randf_range(1.2, 2.6)
			Sfx.play("hammer", -10.0, 0.15)
			_dust(_villa.position + Vector2(randf_range(10, _villa.region_rect.size.x - 10), _villa.region_rect.size.y - 4), 6)
	for v in building_views:
		if Game.buildings[v.id]["state"] == "repairing" and randf() < delta * 0.5:
			Sfx.play("hammer", -14.0, 0.2)
			_dust(v.position + Vector2(randf_range(-20, 20), -2), 4)


## Fills the farm with plants at every stage, for screenshots and clips; saving is switched off so a real save is never touched.
func _load_demo_state() -> void:
	Saves.enabled = false
	Saves.pending_summary = {}
	Game.new_game()
	Game.coins = 1800
	Game.storage = {"lavender": 7}
	var stages := [1.0, 1.0, 0.7, 1.0, 0.4, 1.0, 1.0, 0.1, 1.0, 1.0, 0.8, 1.0, 1.0, 0.3, 1.0, 1.0, 0.0]
	for i in Game.plots.size():
		var p: Dictionary = Game.plots[i]
		if p["zone"] == "home":
			p["unlocked"] = i < 15
			if p["unlocked"]:
				p["crop"] = "lavender"
				p["growth"] = stages[i] * Game.time_to_ready(p)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			Game.day_time = float(arg.trim_prefix("--hour="))
		elif arg.begins_with("--villa="):
			Game.villa_stage = int(arg.trim_prefix("--villa="))
		elif arg == "--send-cart":
			Game.send_cart.call_deferred()
		elif arg == "--estate":
			# Shows the whole estate in use: every zone owned, a mix of building states, and olive trees growing.
			for z in Game.zones_owned:
				Game.zones_owned[z] = true
			var looks := {"drying_shed": "working", "mill": "working", "bakery": "repairing", "beehives": "working", "olive_press": "owned", "unguent": "ruin"}
			for id in looks:
				Game.buildings[id]["state"] = looks[id]
				Game.buildings[id]["time_left"] = 20.0
			Game.buildings["mill"]["busy"] = true
			Game.buildings["mill"]["progress"] = 12.0
			var g := 0
			for i in Game.plots.size():
				if Game.plots[i]["zone"] == "grove":
					Game.plots[i]["unlocked"] = true
					Game.plots[i]["crop"] = "olives"
					Game.plots[i]["growth"] = [1.0, 0.5, 1.0, 0.2, 1.0, 0.8][g] * Game.time_to_ready(Game.plots[i])
					g += 1


func _build_plots() -> void:
	var spots: Array = []
	# The back row sits half a plot to the right of the front row, so every plant shows between the ones in front.
	for i in 9:
		spots.append(Vector2(HOME + 8 + i * 36, FRONT_ROW))
	for i in 8:
		spots.append(Vector2(HOME + 26 + i * 36, BACK_ROW))
	# Olive trees are wider, so the grove has one row, spaced out in front of the beehives and the press.
	for i in 6:
		spots.append(Vector2(18 + i * 62, FRONT_ROW))
	var count := mini(spots.size(), Game.plots.size())
	var order := range(count)
	order.sort_custom(func(a, b): return spots[a].y < spots[b].y)
	for i in order:
		var v := PlotView.new()
		v.index = i
		v.position = spots[i]
		add_child(v)
		plot_views.append(v)


func _build_buildings() -> void:
	for id in Game.buildings:
		var v := BuildingView.new()
		v.id = id
		v.position = Vector2(float(Game.building_info(id).get("x", 0)), 236)
		add_child(v)
		building_views.append(v)


func _build_signs() -> void:
	for z in Game.zones():
		if int(z.get("deed", 0)) == 0:
			continue
		var s := ZoneSign.new()
		s.zone_id = z["id"]
		s.position = Vector2(float(z["x"]) + float(z.get("sign_x", 240)), 240)
		add_child(s)
		signs.append(s)


func _draw_zone_shade() -> void:
	# Land that is not owned yet is shaded, so it reads as somebody else's field.
	for z in Game.zones():
		if not Game.zone_owned(z["id"]):
			_zone_shade.draw_rect(Rect2(float(z["x"]), 226, 480, 50), Color(0.12, 0.1, 0.08, 0.35))


## Frames the scene: the camera follows cam_x across the estate, anchored to the bottom so the desktop strip shows the farm.
func _update_view() -> void:
	var view := get_viewport_rect().size
	cam_x = clampf(cam_x, 0.0, maxf(0.0, ESTATE_WIDTH - view.x))
	_camera.position = Vector2(round(cam_x), 270.0 - view.y)
	var left := roundf(cam_x)
	_sky_node.position.x = round(left * (1.0 - PARALLAX["sky"]))
	_mountains.position.x = round(left * (1.0 - PARALLAX["mountains"]))
	_land.position.x = round(left * (1.0 - PARALLAX["land"]))
	var see_scenery := not (Windowing.strip and Windowing.transparent)
	_sky_layer.visible = see_scenery
	for node in _scenery:
		node.visible = see_scenery
	_click_area_timer = 0.0
	if hud:
		hud.set_zone(_zone_at(left + view.x / 2.0))


func _pan_by(dx: float) -> void:
	if _pan_tween:
		_pan_tween.kill()
	cam_x += dx
	_update_view()


func pan_to_zone(zone_id: String) -> void:
	var z := Game.zone_info(zone_id)
	var target := clampf(float(z.get("x", 0)) + 240.0 - get_viewport_rect().size.x / 2.0, 0.0, ESTATE_WIDTH - get_viewport_rect().size.x)
	if _pan_tween:
		_pan_tween.kill()
	_pan_tween = create_tween()
	_pan_tween.tween_method(func(x): cam_x = x; _update_view(), cam_x, target, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _zone_at(x: float) -> String:
	for z in Game.zones():
		if x >= float(z["x"]) and x < float(z["x"]) + 480:
			return z["id"]
	return "home"


## The outline of everything visible in the transparent strip, so clicks anywhere else fall through to the desktop.
func _click_area() -> PackedVector2Array:
	var view := get_viewport_rect().size
	var top := view.y - (270.0 - 214.0)
	var tall := [Rect2(_villa.position, _villa.region_rect.size), Rect2(_storehouse.position, _storehouse.region_rect.size)]
	for v in building_views:
		tall.append(v.world_rect())
	for s in signs:
		if s.visible:
			tall.append(s.world_rect())
	var in_view := []
	for r in tall:
		var moved := Rect2(r.position - _camera.position, r.size)
		if moved.end.x > 0 and moved.position.x < view.x:
			in_view.append(moved)
	in_view.sort_custom(func(a, b): return a.position.x < b.position.x)
	var points := PackedVector2Array([Vector2(0, view.y), Vector2(0, top)])
	var last_x := 0.0
	for r in in_view:
		var x0 := clampf(maxf(r.position.x, last_x), 0, view.x)
		var x1 := clampf(r.end.x, 0, view.x)
		if x1 <= x0:
			continue
		var y := minf(r.position.y, top)
		points.append_array([Vector2(x0, top), Vector2(x0, y), Vector2(x1, y), Vector2(x1, top)])
		last_x = x1
	points.append_array([Vector2(view.x, top), Vector2(view.x, view.y)])
	var bar: Rect2 = hud.compact_rect()
	if bar.has_area():
		# The bar floats in the top-left corner, so the outline detours up around it before following the skyline.
		var detour := PackedVector2Array([Vector2(0, view.y), Vector2(0, bar.position.y), Vector2(bar.end.x, bar.position.y), Vector2(bar.end.x, top)])
		points = detour + points.slice(2)
	return points


func _unhandled_input(event: InputEvent) -> void:
	if _handle_pad(event):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			_pan_by(-32.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			_pan_by(32.0)
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				_pressed = true
				_dragging = event.button_index == MOUSE_BUTTON_MIDDLE
				_drag_from = event.position
				_drag_start_cam = cam_x
			else:
				# A press that did not move far is a click; one that moved was a drag across the estate.
				if _pressed and not _dragging and event.button_index == MOUSE_BUTTON_LEFT:
					_click(get_global_mouse_position())
				_pressed = false
				_dragging = false
	elif event is InputEventMouseMotion:
		if _pressed:
			if not _dragging and event.position.distance_to(_drag_from) > 4.0:
				_dragging = true
			if _dragging:
				cam_x = _drag_start_cam - (event.position.x - _drag_from.x)
				_update_view()
				return
		_selected = -1
		_update_hover(get_global_mouse_position())


func _click(point: Vector2) -> void:
	if dog.contains(point):
		dog.pet()
		return
	var view := _plot_at(point)
	if view:
		_click_plot(view.index)
		return
	for s in signs:
		if s.contains(point):
			Game.buy_zone(s.zone_id)
			return
	var b := _building_at(point)
	if b:
		hud.show_building(b.id)
		return
	if _cart_rect().has_point(point):
		Game.send_cart()
		return
	if _villa_rect().has_point(point):
		hud.show_building(hud.VILLA)


## Arrow keys or a gamepad's d-pad move between plots, and Enter or the A button acts on the chosen one.
func _handle_pad(event: InputEvent) -> bool:
	var moves := {"ui_left": Vector2.LEFT, "ui_right": Vector2.RIGHT, "ui_up": Vector2.UP, "ui_down": Vector2.DOWN}
	for action in moves:
		if event.is_action_pressed(action):
			_move_selection(moves[action])
			get_viewport().set_input_as_handled()
			return true
	if event.is_action_pressed("ui_accept") and _selected >= 0:
		_click_plot(_selected)
		get_viewport().set_input_as_handled()
		return true
	return false


func _move_selection(dir: Vector2) -> void:
	if _selected < 0:
		_selected = 0
	else:
		var from: Vector2 = _view(_selected).position
		var best := -1
		var best_score := INF
		for v in plot_views:
			var d: Vector2 = v.position - from
			if v.index == _selected or d.dot(dir) <= 0.0:
				continue
			# Prefer plots straight ahead in the pressed direction over ones off to the side.
			var score := d.length() + absf(d.cross(dir)) * 2.0
			if score < best_score:
				best_score = score
				best = v.index
		if best >= 0:
			_selected = best
	for v in plot_views:
		v.hovered = v.index == _selected
	var chosen := _view(_selected)
	# Keep the chosen plot in view, panning when it is near an edge.
	var view := get_viewport_rect().size
	if chosen.position.x < cam_x + 40 or chosen.position.x > cam_x + view.x - 60:
		cam_x = chosen.position.x - view.x / 2.0
		_update_view()
	_describe_plot(_selected)


func _click_plot(i: int) -> void:
	match Game.plot_visual(i):
		"locked":
			if not Game.zone_owned(String(Game.plots[i]["zone"])):
				hud.toast("Buy this land first")
			else:
				Game.try_unlock(i)
		"empty":
			Game.try_plant(i)
		"bloom":
			Game.try_harvest(i)
		_:
			hud.toast("Still growing")
	if _selected >= 0:
		_describe_plot(_selected)
	else:
		_update_hover(get_global_mouse_position())


func _update_hover(point: Vector2) -> void:
	var view := _plot_at(point)
	for v in plot_views:
		v.hovered = v == view
	var sign_hit: Node2D = null
	for s in signs:
		s.hovered = s.contains(point)
		if s.hovered:
			sign_hit = s
	var building: Node2D = null if view or sign_hit else _building_at(point)
	for b in building_views:
		b.hovered = b == building
	var on_villa := not view and not sign_hit and not building and not _cart_rect().has_point(point) and _villa_rect().has_point(point)
	if on_villa != _villa_hovered:
		_villa_hovered = on_villa
		_villa_outline.queue_redraw()
	if view:
		_describe_plot(view.index)
	elif sign_hit:
		var z := Game.zone_info(sign_hit.zone_id)
		hud.set_info("Buy the %s deed: %d sestertii" % [String(z.get("name", "")).to_lower(), int(z.get("deed", 0))])
	elif building:
		hud.set_info("%s: click for details" % Game.building_info(building.id).get("name", ""))
	elif _villa_hovered:
		hud.set_info("%s: click for details" % Game.villa_stages()[clampi(Game.villa_stage - 1, 0, Game.villa_stages().size() - 1)].get("name", "Farmhouse"))
	elif dog.contains(point):
		hud.set_info("Pet the dog")
	elif Rect2(_storehouse.position, _storehouse.region_rect.size).has_point(point):
		hud.set_info("Storehouse: %d / %d" % [Game.stored_total(), Game.storage_capacity()])
	elif _cart_rect().has_point(point):
		hud.set_info("Click the cart to sell")
	else:
		hud.set_info("")


func _describe_plot(i: int) -> void:
	match Game.plot_visual(i):
		"locked":
			if not Game.zone_owned(String(Game.plots[i]["zone"])):
				hud.set_info("Buy this land to plant here")
			else:
				hud.set_info("Unlock this plot: %d sestertii" % Game.unlock_cost())
		"empty":
			var seed := Game.crop_info(Game.seed_for_plot(i))
			hud.set_info("Plant %s: %d sestertii" % [String(seed.get("name", "")).to_lower(), int(seed.get("plant_cost", 0))])
		"bloom":
			hud.set_info("%s is ready: click to harvest" % Game.crop_info(Game.plots[i]["crop"]).get("name", ""))
		_:
			hud.set_info("%s growing: %d%%" % [Game.crop_info(Game.plots[i]["crop"]).get("name", ""), int(Game.growth_fraction(i) * 100)])


func _plot_at(point: Vector2) -> Node2D:
	# Front-row plots overlap the back row, so the front row is checked first.
	for k in range(plot_views.size() - 1, -1, -1):
		if plot_views[k].contains(point):
			return plot_views[k]
	return null


func _building_at(point: Vector2) -> Node2D:
	for v in building_views:
		if v.world_rect().has_point(point):
			return v
	return null


func _view(i: int) -> Node2D:
	for v in plot_views:
		if v.index == i:
			return v
	return null


func _bloom_points() -> Array:
	var points := []
	for v in plot_views:
		if Game.plot_visual(v.index) == "bloom":
			points.append(v.position + Vector2(14, -24))
	return points


func _cart_rect() -> Rect2:
	return Rect2(_cart.position, Vector2(_donkey.position.x + 24 - _cart.position.x, _cart.region_rect.size.y))


func _on_harvested(plot_index: int, amount: int) -> void:
	var v := _view(plot_index)
	Sfx.play("harvest")
	v.bounce()
	hud.float_text(v.position + Vector2(10, -34) - _camera.position, "+%d" % amount)
	var colours := [Color(0.74, 0.57, 0.87), Color(0.57, 0.38, 0.69), Color(0.62, 0.66, 0.52)]
	match String(Game.plots[plot_index]["crop"]):
		"wheat":
			colours = [Color(0.94, 0.85, 0.54), Color(0.8, 0.6, 0.2)]
		"olives":
			colours = [Color(0.3, 0.22, 0.3), Color(0.55, 0.6, 0.45)]
	_burst(v.position + Vector2(14, -18), colours, 10)


func _on_building_made(id: String, item: String, amount: int) -> void:
	for v in building_views:
		if v.id == id:
			hud.float_text(v.position + Vector2(-16, -v.local_rect().size.y - 14) - _camera.position, "+%d %s" % [amount, String(Balance.get_value("items.%s.name" % item, item)).to_lower()])
			_burst(v.position + Vector2(0, -v.local_rect().size.y / 2), [Color(1, 0.9, 0.6), Color(0.95, 0.8, 0.5)], 6)


func _on_building_changed(id: String) -> void:
	var state := String(Game.buildings[id]["state"])
	for v in building_views:
		if v.id != id:
			continue
		match state:
			"owned":
				Sfx.play("coins")
				hud.toast("You own the %s. Repair it to put it to work." % String(Game.building_info(id).get("name", "")).to_lower())
			"repairing":
				Sfx.play("hammer")
				_dust(v.position, 14)
				hud.toast("Repairs have begun")
			"working":
				if int(Game.buildings[id]["level"]) == 0 and not Game.buildings[id]["busy"]:
					Sfx.play("villa_complete")
					_dust(v.position, 24)
					hud.toast("The %s is working again!" % String(Game.building_info(id).get("name", "")).to_lower())


func _on_zone_bought(zone_id: String) -> void:
	Sfx.play("villa_complete")
	_zone_shade.queue_redraw()
	var z := Game.zone_info(zone_id)
	_dust(Vector2(float(z["x"]) + 240, 250), 30)
	hud.toast("The %s is yours!" % String(z.get("name", "")).to_lower())


func _on_cart_left(_items: int, value: int) -> void:
	Sfx.play("cart")
	hud.toast("The cart heads to market with %d sestertii of goods" % value)
	_donkey.flip_h = false
	_cart.flip_h = false
	_donkey.play("walk")
	# The road to town runs off the right edge of the estate, so the cart travels the whole way there.
	_move_rig(ESTATE_WIDTH + 60, (ESTATE_WIDTH + 60 - _cart.position.x) / 90.0)


func _on_cart_returned(coins: int) -> void:
	Sfx.play("cart")
	# Coming home the donkey leads from the right, so the rig is mirrored with the donkey in front.
	_cart.flip_h = true
	_donkey.flip_h = true
	_cart.position.x = ESTATE_WIDTH + 60
	_donkey.position.x = ESTATE_WIDTH + 40
	_donkey.play("walk")
	_move_rig(CART_HOME_X + 24, (ESTATE_WIDTH + 60 - CART_HOME_X) / 90.0, true)
	await _rig_tween.finished
	_dust(Vector2(CART_HOME_X + 40, RIG_BASE), 10)
	_park_rig()
	Sfx.play("coins")
	hud.float_text(Vector2(CART_HOME_X + 24, RIG_BASE - 46) - _camera.position, "+%d" % coins)
	_burst(Vector2(CART_HOME_X + 30, RIG_BASE - 20), [Color(1, 0.86, 0.35), Color(0.96, 0.72, 0.25)], 12)
	hud.toast("The cart is back: +%d sestertii" % coins)


func _on_dog_petted() -> void:
	Sfx.play("pet", -2.0, 0.12)
	var heart := Sprite2D.new()
	heart.texture = Lighting.heart_texture()
	heart.position = dog.position + Vector2(0, -32)
	add_child(heart)
	var t := create_tween().set_parallel()
	t.tween_property(heart, "position:y", heart.position.y - 12, 1.0)
	t.tween_property(heart, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(heart.queue_free)


func _on_build_started() -> void:
	Sfx.play("hammer")
	_place_villa()
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 16)
	hud.toast("Work on the villa has begun")


func _on_villa_finished() -> void:
	_place_villa()
	Sfx.play("villa_complete")
	hud.toast("The villa has been restored!")
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 40)
	_villa.modulate = Color(1.6, 1.5, 1.3)
	create_tween().tween_property(_villa, "modulate", Color.WHITE, 0.9)


## Parks the cart with the donkey standing at its handles, both facing right towards the road to market.
func _park_rig() -> void:
	_cart.flip_h = false
	_donkey.flip_h = false
	_cart.position.x = CART_HOME_X
	_donkey.position = Vector2(CART_HOME_X + _cart.region_rect.size.x + 8, RIG_BASE)
	_donkey.play("stand")


## Moves cart and donkey together; when returning, the donkey walks in front on the left.
func _move_rig(cart_x: float, seconds: float, returning := false) -> void:
	if _rig_tween:
		_rig_tween.kill()
	var donkey_x := cart_x - 22.0 if returning else cart_x + _cart.region_rect.size.x + 8
	_rig_tween = create_tween().set_parallel()
	_rig_tween.tween_property(_cart, "position:x", cart_x, seconds)
	_rig_tween.tween_property(_donkey, "position:x", donkey_x, seconds)


func _donkey_frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	f.add_animation("walk")
	f.set_animation_speed("walk", 9.0)
	for i in range(1, 9):
		f.add_frame("walk", load("res://assets/sprites/donkey/walk_east/frame_%02d.png" % i))
	f.add_animation("stand")
	f.add_frame("stand", load("res://assets/sprites/donkey/walk_east/frame_00.png"))
	return f


func _feet_line(tex: Texture2D) -> int:
	var used := tex.get_image().get_used_rect()
	return used.position.y + used.size.y


func _villa_texture() -> Texture2D:
	if Game.villa_build["active"]:
		return load("res://assets/sprites/villa/scaffold.png")
	var stages := Game.villa_stages()
	var stage: Dictionary = stages[clampi(Game.villa_stage - 1, 0, stages.size() - 1)]
	return load("res://assets/sprites/villa/%s.png" % stage.get("sprite", "stage1"))


func _villa_rect() -> Rect2:
	return Rect2(_villa.position, _villa.region_rect.size)


func _place_villa() -> void:
	var tex := _villa_texture()
	_villa.texture = tex
	var used := tex.get_image().get_used_rect()
	_villa.region_rect = used
	_villa.position = Vector2(round(VILLA_BASE.x - used.size.x / 2.0), VILLA_BASE.y - used.size.y + 1)
	_villa_shadow.texture = Lighting.ellipse_texture(used.size.x + 12, 7, SHADOW)
	_villa_shadow.position = Vector2(_villa.position.x - 6, VILLA_BASE.y - 5)
	_window_glow.texture = _window_glow_texture(tex)
	_window_glow.region_rect = used
	_window_glow.position = _villa.position


## Lamp light for the villa's windows: every glass-blue pixel becomes warm light, shown only at night.
func _window_glow_texture(tex: Texture2D) -> ImageTexture:
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var glow := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	# The ruin and the scaffolding have no glass, only dark holes, so they stay dark.
	if not Game.villa_build["active"] and Game.villa_stage > 1:
		for x in img.get_width():
			for y in img.get_height():
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.b > c.r + 0.08 and c.b > c.g + 0.02:
					glow.set_pixel(x, y, Color(1.0, 0.82, 0.45, 0.95))
	return ImageTexture.create_from_image(glow)


## A one-shot puff of pixel particles.
func _burst(pos: Vector2, colours: Array, amount: int) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.7
	p.direction = Vector2.UP
	p.spread = 70.0
	p.initial_velocity_min = 18.0
	p.initial_velocity_max = 40.0
	p.gravity = Vector2(0, 90)
	var g := Gradient.new()
	g.colors = PackedColorArray(colours)
	p.color_initial_ramp = g
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _dust(pos: Vector2, amount: int) -> void:
	_burst(pos, [Color(0.78, 0.68, 0.55, 0.9), Color(0.66, 0.58, 0.48, 0.8)], amount)


func _add_texture(tex: Texture2D, pos: Vector2, parent: Node = self) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	parent.add_child(s)
	return s


## Adds a sprite cropped to its visible pixels; with from_bottom, pos.y is ignored and the sprite stands on base_y.
func _add_trimmed(tex: Texture2D, pos: Vector2, from_bottom := false, base_y := 0, parent: Node = self) -> Sprite2D:
	var s := _add_texture(tex, pos, parent)
	var used := tex.get_image().get_used_rect()
	s.region_enabled = true
	s.region_rect = used
	if from_bottom:
		s.position.y = base_y - used.size.y
	return s
