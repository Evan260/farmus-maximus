extends Node2D
## Builds the estate from its layers and buildings, pans across it, and turns clicks into farm actions.

const PlotView := preload("res://scripts/plot_view.gd")
const BuildingView := preload("res://scripts/building_view.gd")
const ZoneSign := preload("res://scripts/zone_sign.gd")
const Dog := preload("res://scripts/dog.gd")
const Critters := preload("res://scripts/critters.gd")
const Fireflies := preload("res://scripts/fireflies.gd")
const Walker := preload("res://scripts/world/walker.gd")
const WeatherFx := preload("res://scripts/world/weather_fx.gd")
const RainFx := preload("res://scripts/world/rain_fx.gd")
const SkyView := preload("res://scripts/world/sky_view.gd")
const WorldRoot := preload("res://scripts/world/world_root.gd")
const Wildlife := preload("res://scripts/world/wildlife.gd")
const Pasture := preload("res://scripts/world/pasture.gd")
const DecorView := preload("res://scripts/world/decor_view.gd")
const Channels := preload("res://scripts/world/channels.gd")
const Builder := preload("res://scripts/world/builder.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const MarketView := preload("res://scripts/ui/market_view.gd")
const SWAY := preload("res://assets/shaders/sway.gdshader")
const BG := "res://assets/backgrounds/estate/"
const PEOPLE := "res://assets/sprites/people/"
## The home farm is the second zone, so everything on it sits one screen to the right.
const HOME := 480.0
## Bottom centre of the villa, where the path in the field meets its steps.
const VILLA_BASE := Vector2(HOME + 371, 237)
const FRONT_ROW := 263
const BACK_ROW := 246
const SHADOW := Color(0.16, 0.11, 0.12, 0.28)
## How far each background layer moves for every pixel the camera pans: the far ones barely move, which gives depth.
## The painting is 768 pixels wide, so the land layer's rate is as high as it can be while still covering the whole pan.
const PARALLAX := {"sky": 0.04, "mountains": 0.08, "land": 0.15}
## Where the cart parks, on the soil just right of the path, with the donkey at its handles.
const CART_HOME_X := HOME + 380.0
const RIG_BASE := 266
const PAN_SPEED := 260.0
## Where each helper spends their day, in estate pixels.
const HELPER_GROUNDS := {
	"farmhand": [490.0, 930.0], "miller": [1130.0, 1400.0], "beekeeper": [150.0, 300.0], "perfumer": [990.0, 1610.0],
	"presser": [360.0, 1900.0], "stablehand": [1940.0, 2380.0], "trader": [900.0, 950.0],
}
## Seasons tint the whole scene a little: fresh in spring, golden in autumn, cool and pale in winter.
const SEASON_TINT := {"spring": Color(0.98, 1.02, 0.98), "summer": Color(1.03, 1.0, 0.94), "autumn": Color(1.04, 0.95, 0.86), "winter": Color(0.9, 0.94, 1.02)}

var estate_width := 2400.0
var plot_views: Array = []
var building_views: Array = []
var signs: Array = []
var hud: CanvasLayer
var market: CanvasLayer
var dog: Node2D
var cat: Node2D
## The left edge of the view in estate pixels.
var cam_x := 0.0
## The estate itself, drawn in its own pixel-art viewport; the sky behind it and the interface over it are drawn at screen resolution.
var world: Node2D
var _viewport: SubViewport
var _container: SubViewportContainer
var _sky_view: Node2D
var _daylight: CanvasModulate
var _mountains: Sprite2D
var _land: Sprite2D
## Mirrored copies of the far layers to their right, so a very wide window never sees past the painting's edge.
var _mountains_far: Sprite2D
var _land_far: Sprite2D
var _villa: Sprite2D
var _villa_shadow: Sprite2D
var _villa_outline: Node2D
var _villa_hovered := false
var _stork: Sprite2D
var _cart: Sprite2D
var _cart_shadow: Sprite2D
var _wheel: Sprite2D
## The goods heaped in the cart, drawn behind its side boards so they sit inside it.
var _cart_load: Node2D
var _cart_x := 0.0
## The near shaft and the harness straps, drawn over the donkey so the cart is visibly hitched to it.
var _harness: Node2D
var _cart_returning := false
var _donkey: AnimatedSprite2D
var _rig_tween: Tween
var _storehouse: Sprite2D
var _glow_layer: CanvasLayer
var _window_glow: Sprite2D
var _hammer_timer := 0.0
var _camera: Camera2D
var _sky_layer: CanvasLayer
var _zone_shade: Node2D
var _helpers := {}
## Builders at work, by the site they are working on.
var _builders := {}
var _traveller_timer := 40.0
var _dog_dig_check := 5.0
var _follow_timer := 0.0
## Painted scenery that is hidden in the transparent desktop strip, so only the farm floats over the desktop.
var _scenery: Array = []
var _click_area_timer := 0.0
## The spot chosen with the keyboard or a gamepad, or Vector2.INF when the mouse is in use.
var _pad_point := Vector2.INF
var _drag_from := Vector2.ZERO
var _drag_start_cam := 0.0
var _dragging := false
var _pressed := false
var _pan_tween: Tween
var _last_view_width := 480.0


func _ready() -> void:
	estate_width = float(Balance.get_value("estate.width", 2400))
	if "--demo" in OS.get_cmdline_user_args():
		_load_demo_state()
	# The sky has its own layer at screen resolution, outside the night tint, so clouds and the moon move smoothly
	# and the night sky's stars keep their own colours.
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = -1
	add_child(_sky_layer)
	_sky_view = SkyView.new()
	_sky_view.sky_visible = func(): return _sky_layer.visible
	_sky_layer.add_child(_sky_view)
	var screen := CanvasLayer.new()
	add_child(screen)
	_container = SubViewportContainer.new()
	_container.stretch = true
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(_container)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.snap_2d_transforms_to_pixel = true
	_viewport.snap_2d_vertices_to_pixel = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_container.add_child(_viewport)
	world = WorldRoot.new()
	world.on_input = _world_input
	_viewport.add_child(world)
	_daylight = CanvasModulate.new()
	world.add_child(_daylight)
	_glow_layer = CanvasLayer.new()
	_glow_layer.layer = 1
	_glow_layer.follow_viewport_enabled = true
	world.add_child(_glow_layer)
	_mountains = _add_texture(load(BG + "layer_mountains.png"), Vector2.ZERO)
	_mountains_far = _add_texture(_mountains.texture, Vector2.ZERO)
	_mountains_far.flip_h = true
	_land = _add_texture(load(BG + "layer_land.png"), Vector2.ZERO)
	_land_far = _add_texture(_land.texture, Vector2.ZERO)
	_land_far.flip_h = true
	_scenery.append_array([_mountains, _land, _mountains_far, _land_far])

	var pine := _add_trimmed(load("res://assets/sprites/trees/umbrella_pine_1.png"), Vector2(HOME - 60, 0), true, 240)
	_sway(pine)
	_scenery.append(pine)
	_scenery.append(_add_texture(Lighting.ellipse_texture(64, 7, SHADOW), Vector2(pine.position.x + pine.region_rect.size.x / 2 - 32, 236)))
	_villa_shadow = _add_texture(null, Vector2.ZERO)
	_villa = _add_trimmed(_villa_texture(), Vector2.ZERO)
	_stork = _add_texture(load("res://assets/sprites/animals/stork/nest.png") if ResourceLoader.exists("res://assets/sprites/animals/stork/nest.png") else null, Vector2.ZERO)
	_window_glow = _add_texture(null, Vector2.ZERO, _glow_layer)
	_window_glow.region_enabled = true
	_villa_outline = Node2D.new()
	_villa_outline.draw.connect(func(): if _villa_hovered: _villa_outline.draw_rect(_villa_rect().grow(1), Color(1, 0.96, 0.85, 0.7), false, 1.0))
	world.add_child(_villa_outline)
	_place_villa()
	_add_texture(Lighting.ellipse_texture(70, 7, SHADOW), Vector2(HOME + 194, 230))
	_storehouse = _add_trimmed(load("res://assets/sprites/farm/storehouse.png"), Vector2(HOME + 198, 0), true, 236)
	_build_buildings()
	var decor := DecorView.new()
	decor.glow_layer = _glow_layer
	world.add_child(decor)
	_add_texture(load(BG + "ground.png"), Vector2(-40, 0))
	var pasture := Pasture.new()
	world.add_child(pasture)
	_zone_shade = Node2D.new()
	_zone_shade.draw.connect(_draw_zone_shade)
	world.add_child(_zone_shade)
	var ground_fx := WeatherFx.new()
	ground_fx.plant_tops = _plant_tops
	world.add_child(ground_fx)
	world.add_child(Channels.new())
	_build_plots()
	_build_signs()

	var critters := Critters.new()
	critters.bloom_points = _bloom_points
	world.add_child(critters)
	var wildlife := Wildlife.new()
	wildlife.lizard_wall = Rect2(_storehouse.position + Vector2(6, 20), Vector2(_storehouse.region_rect.size.x - 12, 18))
	world.add_child(wildlife)
	if ResourceLoader.exists("res://assets/sprites/animals/cat_small/east.png"):
		cat = Walker.new()
		cat.dir = "res://assets/sprites/animals/cat_small/"
		cat.min_x = HOME + 190
		cat.max_x = HOME + 270
		cat.speed = 10.0
		cat.idle_anim = "sleep"
		cat.position = Vector2(HOME + 250, 240)
		world.add_child(cat)
	dog = Dog.new()
	dog.position = Vector2(HOME + 345, 268)
	dog.min_x = HOME + 10
	dog.max_x = HOME + 456
	world.add_child(dog)
	_cart_shadow = _add_texture(Lighting.ellipse_texture(96, 6, SHADOW), Vector2.ZERO)
	# The load is drawn just before the cart, so the cart's side boards hide its bottom and it sits inside.
	_cart_load = Node2D.new()
	world.add_child(_cart_load)
	_cart = _add_trimmed(load("res://assets/sprites/farm/cart.png"), Vector2(CART_HOME_X, 0), true, RIG_BASE)
	# The wheel is a separate sprite so it can turn; the body keeps the full cart's outline for placement.
	_cart.texture = load("res://assets/sprites/farm/cart_body.png")
	_wheel = Sprite2D.new()
	_wheel.texture = load("res://assets/sprites/farm/cart_wheel.png")
	_wheel.centered = false
	_wheel.offset = Vector2(-12, -12)
	_cart.add_child(_wheel)
	_donkey = AnimatedSprite2D.new()
	_donkey.sprite_frames = _donkey_frames()
	_donkey.centered = false
	_donkey.offset = Vector2(-32, -_feet_line(load("res://assets/sprites/donkey/walk_east/frame_00.png")))
	_donkey.play("stand")
	world.add_child(_donkey)
	_harness = Node2D.new()
	_harness.draw.connect(_draw_harness)
	world.add_child(_harness)
	_park_rig()
	for id in Game.helpers:
		_spawn_helper(id)

	_glow_layer.add_child(Fireflies.new())
	var weather_layer := CanvasLayer.new()
	weather_layer.layer = 2
	world.add_child(weather_layer)
	weather_layer.add_child(RainFx.new())
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	world.add_child(_camera)
	_camera.make_current()
	Windowing.view_changed.connect(_apply_scale)
	_apply_scale()
	hud = Hud.new()
	hud.zone_chosen.connect(pan_to_zone)
	hud.town_requested.connect(go_to_town)
	add_child(hud)
	market = MarketView.new()
	market.left_town.connect(func(): hud.visible = true)
	add_child(market)

	Game.planted.connect(func(i): Sfx.play("plant"); _view(i).bounce())
	Game.dug_up.connect(func(i): Sfx.play("plant", -4.0); _dust(_view(i).position + Vector2(15, -2), 10))
	Game.unlocked.connect(func(_i): Sfx.play("unlock"))
	Game.harvested.connect(_on_harvested)
	Game.villa_build_started.connect(func(_stage): _on_build_started())
	Game.villa_upgraded.connect(func(_stage): _on_villa_finished())
	Game.cart_left.connect(_on_cart_left)
	Game.cart_returned.connect(_on_cart_returned)
	Game.zone_bought.connect(_on_zone_bought)
	Game.building_changed.connect(_on_building_changed)
	Game.building_made.connect(_on_building_made)
	Game.helper_hired.connect(_spawn_helper)
	Game.weather_changed.connect(_on_weather_changed)
	Game.animal_added.connect(func(_k): Sfx.play("unlock"))
	dog.petted.connect(_on_dog_petted)
	if Game.cart["away"]:
		_cart.position.x = estate_width + 60
		_donkey.position.x = _harness_x(_cart.position.x, false)
	cam_x = HOME + 240.0 - _last_view_width / 2.0
	_update_view()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			var z := Game.zone_info(arg.trim_prefix("--zone="))
			cam_x = float(z.get("x", 0)) + 240.0 - _last_view_width / 2.0
			_update_view()
		elif arg == "--town":
			go_to_town.call_deferred()
		elif arg.begins_with("--panel="):
			_open_panel.call_deferred(arg.trim_prefix("--panel="))
		elif arg.begins_with("--shot="):
			_take_screenshot(arg.trim_prefix("--shot="))
		elif arg.begins_with("--burst="):
			_take_burst(arg.trim_prefix("--burst="))


## Saves exactly what the window shows after the scene settles, then quits; used for store screenshots and layout checks.
func _take_screenshot(path: String) -> void:
	for i in 45:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


## Saves eight frames a quarter of a second apart, for checking anything that flickers or moves.
func _take_burst(prefix: String) -> void:
	for i in 45:
		await get_tree().process_frame
	for k in 8:
		get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, k])
		await get_tree().create_timer(0.25).timeout
	get_tree().quit()


func _open_panel(which: String) -> void:
	if which.begins_with("journal:"):
		hud.open_window("journal")
		hud.show_journal_entry(which.trim_prefix("journal:"))
	elif which in ["journal", "helpers", "store", "settings", "upgrades"]:
		hud.open_window(which)
	else:
		hud.show_building(which)


func go_to_town() -> void:
	if Windowing.strip:
		return
	hud.close_windows()
	hud.visible = false
	market.enter()


func _process(delta: float) -> void:
	var night := Lighting.night_amount(Game.day_time)
	var light: Color = Lighting.color_at(Game.day_time) * SEASON_TINT.get(Game.calendar.season_id(), Color.WHITE)
	if Game.calendar.weather in ["cloudy", "rain"]:
		light = light.darkened(0.12)
	_daylight.color = Color(light, 1.0)
	# At night the far mountains become dark shapes against the starry sky instead of glowing blue.
	var far := Color.WHITE.lerp(Color(0.62, 0.6, 0.7), night)
	_mountains.modulate = far
	_mountains_far.modulate = far
	_window_glow.modulate.a = night
	var windy := 1.6 if Game.calendar.weather in ["rain", "cloudy"] else 1.0
	if PlotView.wind:
		PlotView.wind.set_shader_parameter("strength", 0.0 if Settings.reduced_motion else windy)
	var keys := Input.get_axis("pan_left", "pan_right") + Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) * float(absf(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)) > 0.2)
	if keys != 0.0 and not market.visible:
		_pan_by(keys * PAN_SPEED * delta)
	_cart_shadow.position = Vector2(_cart.position.x - 2, RIG_BASE - 5)
	_cart_load.position = _cart.position
	_harness.queue_redraw()
	# The wheel turns by the distance travelled over its radius, in steps fine enough to look smooth at this size.
	var rolled := _cart.position.x - _cart_x
	_cart_x = _cart.position.x
	if rolled != 0.0:
		_wheel.rotation = snappedf(_wheel.rotation + rolled / 12.0, PI / 24.0)
	if Engine.get_process_frames() % 20 == 0:
		_update_cart_load()
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
	_update_life(delta)
	if Windowing.strip and Windowing.follow:
		_follow_timer -= delta
		if _follow_timer <= 0.0:
			_follow_timer = 20.0
			pan_to_zone(_busiest_zone())


## The zone with the most ready to harvest and the most workshops at work, for the strip to show.
func _busiest_zone() -> String:
	var score := {}
	for i in Game.plots.size():
		if Game.is_ready(i):
			score[Game.plots[i]["zone"]] = int(score.get(Game.plots[i]["zone"], 0)) + 2
	for id in Game.buildings:
		if Game.buildings[id]["busy"]:
			var zone := String(Game.building_info(id).get("zone", "home"))
			score[zone] = int(score.get(zone, 0)) + 1
	var best := _zone_at(cam_x + _view_size().x / 2.0)
	for zone in score:
		if int(score[zone]) > int(score.get(best, 0)):
			best = zone
	return best


## The people and animals that come and go: the dog's digging, the trader by the cart, travellers on the road, the cat and dog napping.
func _update_life(delta: float) -> void:
	if Engine.get_process_frames() % 30 == 0:
		_sync_builders()
	_dog_dig_check -= delta
	if _dog_dig_check <= 0.0:
		_dog_dig_check = 5.0
		if Game.dog_timer <= 0.0 and Lighting.night_amount(Game.day_time) < 0.5:
			_dust(dog.position + Vector2(8, -2), 8)
			Sfx.play("plant", -6.0)
			Game.dog_dig()
	var trader: Node2D = _helpers.get("trader")
	if trader:
		trader.visible = not Game.cart["away"]
	_traveller_timer -= delta
	if _traveller_timer <= 0.0:
		_traveller_timer = randf_range(90.0, 240.0)
		var who: String = ["shepherd", "traveller"][randi() % 2]
		if ResourceLoader.exists(PEOPLE + who + "/east.png"):
			var w := Walker.new()
			w.dir = PEOPLE + who + "/"
			var from_right := randf() < 0.5
			w.position = Vector2(estate_width + 20 if from_right else 1430.0, 270)
			w.leave_at = 1430.0 if from_right else estate_width + 20
			w.speed = 16.0
			world.add_child(w)
	if cat and dog and dog.get("_state") == "sleep" and cat.sprite.animation == "sleep" and absf(cat.position.x - dog.position.x) < 60.0:
		var view := Rect2(_camera.position, _view_size())
		if view.has_point(cat.position):
			Game.discover("sighting:cat_and_dog")
	var view_rect := Rect2(_camera.position, _view_size())
	if cat and view_rect.has_point(cat.position):
		Game.discover("animal:cat")
	if _stork.visible and view_rect.has_point(_stork.position):
		Game.discover("animal:stork")
	if view_rect.position.x < HOME + 400 and view_rect.end.x > HOME:
		Game.discover("animal:bees")
		Game.discover("animal:butterflies")
	if Lighting.night_amount(Game.day_time) > 0.6:
		Game.discover("animal:fireflies")


## Every building under repair has a builder at work on it, and the villa two, until the work is done.
func _sync_builders() -> void:
	var sites := {}
	for v in building_views:
		if Game.buildings[v.id]["state"] == "repairing":
			var r: Rect2 = v.world_rect()
			sites[v.id] = {"rect": r, "ladders": Game.building_info(v.id).get("ladders", []).map(func(x): return r.position.x + float(x))}
	if Game.villa_build["active"]:
		var r := _villa_rect()
		var ladders: Array = Balance.get_value("villa.ladders", []).map(func(x): return r.position.x + float(x))
		sites["villa_a"] = {"rect": r, "ladders": ladders}
		sites["villa_b"] = {"rect": r, "ladders": ladders}
	for id in _builders.keys():
		if not sites.has(id):
			_builders[id].queue_free()
			_builders.erase(id)
	for id in sites:
		if not _builders.has(id):
			var b := Builder.new()
			b.site = sites[id]["rect"]
			b.ladders = sites[id]["ladders"]
			world.add_child(b)
			_builders[id] = b


func _spawn_helper(id: String) -> void:
	if _helpers.has(id) or not ResourceLoader.exists(PEOPLE + id + "/east.png"):
		return
	var w := Walker.new()
	w.dir = PEOPLE + id + "/"
	var ground: Array = HELPER_GROUNDS.get(id, [HOME, HOME + 400])
	w.min_x = float(ground[0])
	w.max_x = float(ground[1])
	w.position = Vector2(randf_range(w.min_x, w.max_x), 270)
	var info := Game.helper_info(id)
	if info.has("zones") or info.has("crops"):
		w.find_work = func() -> float: return _ready_plot_x(info)
		w.work_done = func(x: float) -> void: Game.helper_harvest(id, _plot_near(x))
		w.work_seconds = clampf(Game.helper_interval(id) * 0.6, 0.8, 4.0)
		Game.live_helpers[id] = true
	world.add_child(w)
	_helpers[id] = w


## The plot whose plant stands at this spot, as a helper reaching it sees it.
func _plot_near(x: float) -> int:
	var best := -1
	for v in plot_views:
		if absf(v.position.x + 15.0 - x) < 2.0 and Game.is_ready(v.index):
			best = v.index
	return best


## Where a helper would find a ripe plant to pick, or NAN when there is none.
func _ready_plot_x(info: Dictionary) -> float:
	for v in plot_views:
		var p: Dictionary = Game.plots[v.index]
		if Game.is_ready(v.index) and ((info.has("zones") and p["zone"] in info["zones"]) or (info.has("crops") and p["crop"] in info["crops"])):
			return v.position.x + 15.0
	return NAN


## Fills the farm with plants at every stage, for screenshots and clips; saving is switched off so a real save is never touched.
func _load_demo_state() -> void:
	Saves.enabled = false
	Saves.pending_summary = {}
	Settings.intro_seen = true
	Settings.show_tutorial = false
	Game.new_game()
	Game.coins = 1800
	Game.storage = {"lavender": 7}
	var stages := [1.0, 1.0, 0.7, 1.0, 0.4, 1.0, 1.0, 0.1, 1.0, 1.0, 0.8, 1.0, 1.0, 0.3, 1.0, 1.0, 0.0]
	for i in Game.plots.size():
		var p: Dictionary = Game.plots[i]
		if p["zone"] == "home":
			p["unlocked"] = i < 15
			if p["unlocked"]:
				p["crop"] = ["lavender", "lavender", "lavender_violet", "lavender", "lavender_bluegrey", "lavender", "lavender_white", "wheat"][i % 8]
				p["growth"] = stages[i] * Game.time_to_ready(p)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			Game.day_time = float(arg.trim_prefix("--hour="))
		elif arg.begins_with("--villa="):
			Game.villa_stage = int(arg.trim_prefix("--villa="))
		elif arg.begins_with("--weather="):
			Game.calendar.weather = arg.trim_prefix("--weather=")
			Game.calendar.weather_left = 9999.0
			Game.calendar.wet_left = 9999.0 if Game.calendar.weather == "rain" else 0.0
		elif arg.begins_with("--day="):
			Game.calendar.day = int(arg.trim_prefix("--day="))
		elif arg == "--send-cart":
			Game.send_cart.call_deferred()
		elif arg == "--estate":
			_demo_estate()


## Shows the whole estate in use: every zone owned, a mix of building states, helpers at work, animals and decorations.
func _demo_estate() -> void:
	Game.villa_stage = maxi(Game.villa_stage, 5)
	for z in Game.zones_owned:
		Game.zones_owned[z] = true
	for c in Balance.get_value("crops", {}):
		Game.unlock_crop(c)
	var looks := {"drying_shed": "working", "mill": "working", "bakery": "repairing", "beehives": "working", "olive_press": "owned",
		"unguent": "ruin", "wine_press": "working", "cellar": "working", "barn": "working", "dairy": "repairing", "lararium": "working"}
	for id in looks:
		Game.buildings[id]["state"] = looks[id]
		Game.buildings[id]["time_left"] = 20.0
	Game.buildings["mill"]["busy"] = true
	Game.buildings["mill"]["progress"] = 12.0
	Game.buildings["cellar"]["casks"] = [100.0, 2000.0, 4000.0]
	Game.buildings["barn"]["animals"] = {"chicken": 5, "goat": 3}
	Game.buildings["barn"]["feed"] = 12
	for h in ["farmhand", "miller", "beekeeper", "presser", "stablehand", "perfumer", "trader"]:
		Game.helpers[h] = 1
	for d in ["statue", "lanterns", "planters", "fountain", "bench", "dovecote", "column", "sundial", "birdbath", "pergola"]:
		Game.decorations[d] = true
	Game.levels["channels"] = 1
	Game.storage = {"lavender": 3, "lavender@1": 2, "olive_oil": 2, "bread@2": 1, "stone": 4, "honey": 2}
	var fills := {"grove": [1.0, 0.5, 1.0, 0.2, 1.0, 0.8], "vineyard": [1.0, 0.7, 1.0, 0.3, 1.0, 0.6]}
	var counts := {"grove": 0, "vineyard": 0}
	for i in Game.plots.size():
		var zone := String(Game.plots[i]["zone"])
		if fills.has(zone):
			Game.plots[i]["unlocked"] = true
			Game.plots[i]["crop"] = ("herbs" if counts[zone] % 3 == 1 else "olives") if zone == "grove" else "grapes"
			Game.plots[i]["growth"] = fills[zone][counts[zone]] * Game.time_to_ready(Game.plots[i])
			counts[zone] += 1
	Game.market.add_order()
	Game.market.add_order()


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
	# Vines stand in a row along the front of the slope, leaving the presses and the cellar in view behind them.
	for i in 6:
		spots.append(Vector2(1452 + i * 40, FRONT_ROW))
	var count := mini(spots.size(), Game.plots.size())
	var order := range(count)
	order.sort_custom(func(a, b): return spots[a].y < spots[b].y)
	for i in order:
		var v := PlotView.new()
		v.index = i
		v.position = spots[i]
		world.add_child(v)
		plot_views.append(v)


func _build_buildings() -> void:
	for id in Game.buildings:
		var v := BuildingView.new()
		v.id = id
		v.position = Vector2(float(Game.building_info(id).get("x", 0)), 236)
		world.add_child(v)
		building_views.append(v)


func _build_signs() -> void:
	for z in Game.zones():
		if int(z.get("deed", 0)) == 0:
			continue
		var s := ZoneSign.new()
		s.zone_id = z["id"]
		s.position = Vector2(float(z["x"]) + float(z.get("sign_x", 240)), 240)
		world.add_child(s)
		signs.append(s)


func _draw_zone_shade() -> void:
	# Land that is not owned yet is shaded, so it reads as somebody else's field.
	for z in Game.zones():
		if not Game.zone_owned(z["id"]):
			_zone_shade.draw_rect(Rect2(float(z["x"]), 226, 480, 50), Color(0.12, 0.1, 0.08, 0.35))


## Frames the scene: the camera follows cam_x across the estate, anchored to the bottom so the desktop strip shows the farm.
func _update_view() -> void:
	var view := _view_size()
	# When the window changes size the view keeps its centre, so resizing never jumps to another part of the estate.
	if view.x != _last_view_width:
		cam_x += (_last_view_width - view.x) / 2.0
		_last_view_width = view.x
	cam_x = clampf(cam_x, 0.0, maxf(0.0, estate_width - view.x))
	_camera.position = Vector2(round(cam_x), 270.0 - view.y)
	var left := roundf(cam_x)
	var s := float(Windowing.scale)
	# The sky is drawn at screen resolution, so it follows the unrounded pan and slides smoothly.
	_sky_view.scale = Vector2(s, s)
	_sky_view.position = Vector2(-cam_x * PARALLAX["sky"] * s, -(270.0 - view.y) * s)
	_mountains.position.x = round(left * (1.0 - PARALLAX["mountains"]))
	_land.position.x = round(left * (1.0 - PARALLAX["land"]))
	_mountains_far.position.x = _mountains.position.x + 768.0
	_land_far.position.x = _land.position.x + 768.0
	var see_scenery := not (Windowing.strip and Windowing.transparent)
	_sky_layer.visible = see_scenery
	for node in _scenery:
		node.visible = see_scenery
	_click_area_timer = 0.0
	if hud:
		hud.set_zone(_zone_at(left + view.x / 2.0))


## Sizes the estate's viewport to the window at the current pixel scale, so the picture always fills the window.
func _apply_scale() -> void:
	_container.stretch_shrink = Windowing.scale
	_update_view.call_deferred()


func _view_size() -> Vector2:
	return Vector2(_viewport.size) if _viewport else Vector2(480, 270)


func _pan_by(dx: float) -> void:
	if _pan_tween:
		_pan_tween.kill()
	cam_x += dx
	_update_view()


func pan_to_zone(zone_id: String) -> void:
	var z := Game.zone_info(zone_id)
	var target := clampf(float(z.get("x", 0)) + 240.0 - _view_size().x / 2.0, 0.0, estate_width - _view_size().x)
	if _pan_tween:
		_pan_tween.kill()
	if Settings.reduced_motion:
		cam_x = target
		_update_view()
		return
	_pan_tween = create_tween()
	_pan_tween.tween_method(func(x): cam_x = x; _update_view(), cam_x, target, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _zone_at(x: float) -> String:
	for z in Game.zones():
		if x >= float(z["x"]) and x < float(z["x"]) + 480:
			return z["id"]
	return "home"


func _step_zone(step: int) -> void:
	var ids := Game.zones().map(func(z): return String(z["id"]))
	var now := ids.find(_zone_at(cam_x + _view_size().x / 2.0))
	pan_to_zone(ids[clampi(now + step, 0, ids.size() - 1)])


## The outline of everything visible in the transparent strip, so clicks anywhere else fall through to the desktop.
func _click_area() -> PackedVector2Array:
	var view := _view_size()
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
	bar = Rect2(bar.position * Windowing.ui_scale / Windowing.scale, bar.size * Windowing.ui_scale / Windowing.scale)
	if bar.has_area():
		# The bar floats in the top-left corner, so the outline detours up around it before following the skyline.
		var detour := PackedVector2Array([Vector2(0, view.y), Vector2(0, bar.position.y), Vector2(bar.end.x, bar.position.y), Vector2(bar.end.x, top)])
		points = detour + points.slice(2)
	return points


func _world_input(event: InputEvent) -> void:
	if market.visible:
		return
	if event.is_action_pressed("prev_zone"):
		_step_zone(-1)
		return
	if event.is_action_pressed("next_zone"):
		_step_zone(1)
		return
	if event.is_action_pressed("open_market"):
		go_to_town()
		return
	if _handle_pad(event):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			_pan_by(-32.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			_pan_by(32.0)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not Windowing.strip:
			var under := _plot_at(world.get_global_mouse_position())
			if under:
				Game.dig_up(under.index)
				_update_hover(world.get_global_mouse_position())
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				_pressed = true
				_dragging = event.button_index == MOUSE_BUTTON_MIDDLE
				_drag_from = event.position
				_drag_start_cam = cam_x
			else:
				# A press that did not move far is a click; one that moved was a drag across the estate.
				if _pressed and not _dragging and event.button_index == MOUSE_BUTTON_LEFT:
					_click(world.get_global_mouse_position())
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
		_pad_point = Vector2.INF
		_update_hover(world.get_global_mouse_position())


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
		return
	if Rect2(_storehouse.position, _storehouse.region_rect.size).has_point(point):
		hud.open_window("store")


## Arrow keys or a gamepad's d-pad move between everything that can be clicked, and Enter or the A button clicks it.
func _handle_pad(event: InputEvent) -> bool:
	if hud.window_open():
		return false
	var moves := {"ui_left": Vector2.LEFT, "ui_right": Vector2.RIGHT, "ui_up": Vector2.UP, "ui_down": Vector2.DOWN}
	for action in moves:
		if event.is_action_pressed(action):
			_move_selection(moves[action])
			world.get_viewport().set_input_as_handled()
			return true
	if event.is_action_pressed("dig_up") and _pad_point != Vector2.INF:
		var under := _plot_at(_pad_point)
		if under:
			Game.dig_up(under.index)
			_update_hover(_pad_point)
		world.get_viewport().set_input_as_handled()
		return true
	if event.is_action_pressed("ui_accept") and _pad_point != Vector2.INF:
		_click(_pad_point)
		_update_hover(_pad_point)
		world.get_viewport().set_input_as_handled()
		return true
	return false


## Points that a click would act on: every plot, building, sign, the villa, the storehouse, the cart and the dog.
func _targets() -> Array:
	var points := []
	for v in plot_views:
		points.append(v.position + Vector2(14, -1))
	# Buildings and the villa are picked near their tops, above any plants growing in front of them.
	for b in building_views:
		var r: Rect2 = b.world_rect()
		points.append(r.position + Vector2(r.size.x / 2.0, 8))
	for sgn in signs:
		if sgn.visible:
			points.append(sgn.world_rect().get_center())
	points.append(_villa_rect().position + Vector2(_villa_rect().size.x / 2.0, 10))
	points.append(_storehouse.position + Vector2(_storehouse.region_rect.size.x / 2.0, 8))
	if not Game.cart["away"]:
		points.append(_cart_rect().get_center())
	points.append(dog.position + Vector2(0, -12))
	return points


func _move_selection(dir: Vector2) -> void:
	var points := _targets()
	if _pad_point == Vector2.INF:
		var centre := Vector2(cam_x + _view_size().x / 2.0, 255)
		_pad_point = points[0]
		for p in points:
			if p.distance_to(centre) < _pad_point.distance_to(centre):
				_pad_point = p
	else:
		var best := Vector2.INF
		var best_score := INF
		for p in points:
			var d: Vector2 = p - _pad_point
			if d.length() < 2.0 or d.dot(dir) <= 0.0:
				continue
			# Prefer targets straight ahead in the pressed direction over ones off to the side.
			var score := d.length() + absf(d.cross(dir)) * 2.0
			if score < best_score:
				best_score = score
				best = p
		if best != Vector2.INF:
			_pad_point = best
	# Keep the chosen target in view, panning when it is near an edge.
	var view := _view_size()
	if _pad_point.x < cam_x + 40 or _pad_point.x > cam_x + view.x - 60:
		cam_x = _pad_point.x - view.x / 2.0
		_update_view()
	_update_hover(_pad_point)


func _click_plot(i: int) -> void:
	match Game.plot_visual(i):
		"locked":
			if not Game.zone_owned(String(Game.plots[i]["zone"])):
				hud.toast(tr("Buy this land first"))
			else:
				Game.try_unlock(i)
		"empty":
			Game.try_plant(i)
		"bloom":
			Game.try_harvest(i)
		_:
			hud.toast(tr("Still growing. Right-click to dig it up."))
	_update_hover(_pad_point if _pad_point != Vector2.INF else world.get_global_mouse_position())


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
		var block := Game.zone_block(sign_hit.zone_id)
		hud.set_info(tr(block) if block != "" else tr("Buy the %s deed: %d sestertii") % [tr(String(z.get("name", ""))).to_lower(), int(z.get("deed", 0))])
	elif building:
		hud.set_info(tr("%s: click for details") % tr(String(Game.building_info(building.id).get("name", ""))))
	elif _villa_hovered:
		hud.set_info(tr("%s: click for details") % tr(String(Game.villa_stages()[clampi(Game.villa_stage - 1, 0, Game.villa_stages().size() - 1)].get("name", "Farmhouse"))))
	elif dog.contains(point):
		hud.set_info(tr("Pet the dog"))
	elif Rect2(_storehouse.position, _storehouse.region_rect.size).has_point(point):
		hud.set_info(tr("Storehouse: %d / %d") % [Game.stored_total(), Game.storage_capacity()])
	elif _cart_rect().has_point(point):
		hud.set_info(tr("Click the cart to sell"))
	else:
		hud.set_info("")


func _describe_plot(i: int) -> void:
	var crop_name := tr(String(Game.crop_info(Game.plots[i]["crop"]).get("name", "")))
	match Game.plot_visual(i):
		"locked":
			if not Game.zone_owned(String(Game.plots[i]["zone"])):
				hud.set_info(tr("Buy this land to plant here"))
			else:
				hud.set_info(tr("Dig a new bed here: %d sestertii") % Game.unlock_cost())
		"empty":
			var seed_id := Game.seed_for_plot(i)
			if seed_id == "":
				hud.set_info(tr("Buy cuttings for this land at the market"))
			else:
				var seed := Game.crop_info(seed_id)
				hud.set_info(tr("Plant %s: %d sestertii") % [tr(String(seed.get("name", ""))).to_lower(), int(seed.get("plant_cost", 0))])
		"bloom":
			hud.set_info(tr("%s is ready: click to harvest, right-click to dig up") % crop_name)
		_:
			var notes := []
			if not Game.watered(i):
				notes.append(tr("dry"))
			if Game.plots[i].get("manured", false):
				notes.append(tr("manured"))
			hud.set_info(tr("%s growing: %d%%") % [crop_name, int(Game.growth_fraction(i) * 100)] + ("  (%s)" % ", ".join(notes) if not notes.is_empty() else "") + "   " + tr("right-click to dig up"))


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


func _plant_tops() -> Array:
	var tops := []
	for v in plot_views:
		if Game.plots[v.index]["crop"] != "":
			tops.append(v.plant_top())
	return tops


func _cart_rect() -> Rect2:
	return Rect2(_cart.position, Vector2(_donkey.position.x + 24 - _cart.position.x, _cart.region_rect.size.y))


func _on_harvested(plot_index: int, amount: int) -> void:
	var v := _view(plot_index)
	Sfx.play("harvest")
	v.bounce()
	hud.float_text(v.position + Vector2(10, -34) - _camera.position, "+%d" % amount)
	var colours := [Color(0.74, 0.57, 0.87), Color(0.57, 0.38, 0.69), Color(0.62, 0.66, 0.52)]
	match String(Game.crop_info(Game.plots[plot_index]["crop"]).get("item", "")):
		"wheat":
			colours = [Color(0.94, 0.85, 0.54), Color(0.8, 0.6, 0.2)]
		"olives":
			colours = [Color(0.3, 0.22, 0.3), Color(0.55, 0.6, 0.45)]
		"grapes":
			colours = [Color(0.42, 0.2, 0.42), Color(0.4, 0.55, 0.3)]
		"herbs":
			colours = [Color(0.5, 0.62, 0.45), Color(0.7, 0.8, 0.95)]
		"white_lavender":
			colours = [Color(0.95, 0.94, 0.98), Color(0.8, 0.78, 0.85)]
	_burst(v.position + Vector2(14, -18), colours, 10)


func _on_building_made(id: String, item: String, amount: int) -> void:
	Sfx.play({"aged_wine": "cork", "bread": "oven", "herb_bread": "oven"}.get(item, "made"), -4.0)
	for v in building_views:
		if v.id == id:
			hud.float_text(v.position + Vector2(-16, -v.local_rect().size.y - 14) - _camera.position, "+%d %s" % [amount, tr(String(Balance.get_value("items.%s.name" % item, item))).to_lower()])
			_burst(v.position + Vector2(0, -v.local_rect().size.y / 2), [Color(1, 0.9, 0.6), Color(0.95, 0.8, 0.5)], 6)


func _on_building_changed(id: String) -> void:
	var state := String(Game.buildings[id]["state"])
	var name := tr(String(Game.building_info(id).get("name", ""))).to_lower()
	for v in building_views:
		if v.id != id:
			continue
		match state:
			"owned":
				Sfx.play("coins")
				hud.toast(tr("You own the %s. Repair it to put it to work.") % name)
			"repairing":
				Sfx.play("hammer")
				_dust(v.position, 14)
				hud.toast(tr("Repairs have begun"))
			"working":
				if int(Game.buildings[id]["level"]) == 0 and not Game.buildings[id]["busy"] and Game.buildings[id]["queue"].is_empty():
					Sfx.play("villa_complete")
					_dust(v.position, 24)
					hud.toast(tr("The %s is working again!") % name)


func _on_zone_bought(zone_id: String) -> void:
	Sfx.play("villa_complete")
	_zone_shade.queue_redraw()
	var z := Game.zone_info(zone_id)
	_dust(Vector2(float(z["x"]) + 240, 250), 30)
	hud.toast(tr("The %s is yours!") % tr(String(z.get("name", ""))).to_lower())


func _on_weather_changed(weather: String, before: String) -> void:
	if weather == "rain":
		Sfx.play("rain_start")
		hud.toast(tr("Rain is falling: the fields are watered"))
	elif weather == "mist" and Lighting.night_amount(Game.day_time) < 0.6:
		Game.discover("sighting:mist")


func _on_cart_left(_items: int, value: int) -> void:
	Sfx.play("cart")
	hud.toast(tr("The cart heads to market with %d sestertii of goods") % value)
	_face_rig(false)
	_donkey.play("walk")
	# The road to town runs off the right edge of the estate, so the cart travels the whole way there.
	_move_rig(estate_width + 60, (estate_width + 60 - _cart.position.x) / 90.0)


func _on_cart_returned(coins: int) -> void:
	Sfx.play("cart")
	# Coming home the donkey leads from the right, so the rig is mirrored with the donkey in front.
	_face_rig(true)
	_cart_returning = true
	_cart.position.x = estate_width + 60
	_donkey.position.x = _harness_x(_cart.position.x, true)
	_donkey.play("walk")
	_move_rig(CART_HOME_X, (estate_width + 60 - CART_HOME_X) / 90.0, true)
	await _rig_tween.finished
	_dust(Vector2(CART_HOME_X + 40, RIG_BASE), 10)
	_cart_returning = false
	_park_rig()
	Sfx.play("coins")
	hud.float_text(Vector2(CART_HOME_X + 24, RIG_BASE - 46) - _camera.position, "+%d" % coins)
	_burst(Vector2(CART_HOME_X + 30, RIG_BASE - 20), [Color(1, 0.86, 0.35), Color(0.96, 0.72, 0.25)], 12)
	hud.toast(tr("The cart is back: +%d sestertii") % coins)


func _on_dog_petted() -> void:
	Sfx.play("pet", -2.0, 0.12)
	Game.add_stat("pets", 1)
	var heart := Sprite2D.new()
	heart.texture = Lighting.heart_texture()
	heart.position = dog.position + Vector2(0, -32)
	world.add_child(heart)
	var t := create_tween().set_parallel()
	t.tween_property(heart, "position:y", heart.position.y - 12, 1.0)
	t.tween_property(heart, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(heart.queue_free)


func _on_build_started() -> void:
	Sfx.play("hammer")
	_place_villa()
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 16)
	hud.toast(tr("Work on the villa has begun"))


func _on_villa_finished() -> void:
	_place_villa()
	Sfx.play("villa_complete")
	hud.toast(tr("The villa has been restored: %s!") % tr(String(Game.villa_stages()[Game.villa_stage - 1]["name"])).to_lower())
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 40)
	_villa.modulate = Color(1.6, 1.5, 1.3)
	create_tween().tween_property(_villa, "modulate", Color.WHITE, 0.9)


## Parks the cart with the donkey standing at its handles, both facing right towards the road to market.
func _park_rig() -> void:
	_face_rig(false)
	_cart.position.x = CART_HOME_X
	_donkey.position = Vector2(_harness_x(CART_HOME_X, false), RIG_BASE)
	_donkey.play("stand")


## Where the donkey stands so the shaft tips reach its harness: going out the shafts point right, coming home the cart is turned round.
func _harness_x(cart_x: float, homeward: bool) -> float:
	return cart_x + 2.0 if homeward else cart_x + 58.0


func _face_rig(homeward: bool) -> void:
	_cart.flip_h = homeward
	_donkey.flip_h = homeward
	_wheel.position = Vector2(45.0 if homeward else 15.0, 23.0)
	_update_cart_load()


## The near shaft runs from the front of the cart along the donkey's side to the collar at its shoulder,
## with a strap over its back holding the shaft up; the painted shafts on the cart are the far side's.
func _draw_harness() -> void:
	var home := _cart.flip_h
	var dir := -1.0 if home else 1.0
	var a := Vector2(_cart.position.x + (26.0 if home else 34.0), _cart.position.y + 17.0).round()
	var b := Vector2(_donkey.position.x + 12.0 * dir, float(RIG_BASE) - 20.0).round()
	var leather := Color(0.3, 0.17, 0.11)
	var steps := int(absf(b.x - a.x))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / maxf(1.0, steps)).round()
		_harness.draw_rect(Rect2(p, Vector2.ONE), Color(0.62, 0.4, 0.23))
		_harness.draw_rect(Rect2(p + Vector2(0, 1), Vector2.ONE), Color(0.4, 0.24, 0.14))
	# The back strap rises from the shaft over the saddle; the collar strap wraps the chest at the shaft's end.
	var saddle_x := roundf(_donkey.position.x + 2.0 * dir)
	var on_shaft := roundf(lerpf(a.y, b.y, (saddle_x - a.x) / (b.x - a.x))) if b.x != a.x else a.y
	_harness.draw_rect(Rect2(saddle_x, float(RIG_BASE) - 27.0, 1, on_shaft - (float(RIG_BASE) - 27.0)), leather)
	_harness.draw_rect(Rect2(b.x, b.y - 5, 1, 7), leather)


## What the cart carries: the goods waiting to go while it is home, its load on the road, and a purse of coins coming back.
func _update_cart_load() -> void:
	var keys: Array = []
	if _cart_returning:
		keys = ["sestertius"]
	elif Game.cart["away"]:
		keys = Game.cart.get("load", [])
	else:
		var goods: Dictionary = Game.sellable_goods()
		keys = goods.keys()
		keys.sort_custom(func(a, b): return goods[a] > goods[b])
	var paths := []
	for key in keys:
		var path := "res://assets/sprites/icons/%s.png" % Game.item_base(key)
		if ResourceLoader.exists(path) and not path in paths:
			paths.append(path)
	paths = paths.slice(0, 4)
	while _cart_load.get_child_count() < paths.size():
		var icon := Sprite2D.new()
		icon.centered = false
		_cart_load.add_child(icon)
	for k in _cart_load.get_child_count():
		var icon: Sprite2D = _cart_load.get_child(k)
		icon.visible = k < paths.size()
		if icon.visible:
			icon.texture = load(paths[k])
			var x := 4.0 + k * 8.0
			# Each good sits down in the bed: its visible bottom is placed below the cart's rim, which hides it.
			var bottom := icon.texture.get_image().get_used_rect().end.y
			icon.position = Vector2(x if not _cart.flip_h else 60.0 - x - 16.0, 9 - bottom)


## Moves cart and donkey together; when returning, the donkey walks in front on the left.
func _move_rig(cart_x: float, seconds: float, returning := false) -> void:
	if _rig_tween:
		_rig_tween.kill()
	var donkey_x := _harness_x(cart_x, returning)
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
	var path := "res://assets/sprites/villa/%s.png" % stage.get("sprite", "stage1")
	return load(path) if ResourceLoader.exists(path) else load("res://assets/sprites/villa/stage2.png")


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
	# Storks only nest on a well-kept roof, so they arrive with the peristyle garden.
	_stork.visible = _stork.texture != null and Game.villa_stage >= 5 and not Game.villa_build["active"]
	if _stork.texture:
		_stork.position = Vector2(_villa.position.x + used.size.x * 0.68, _villa.position.y - _stork.texture.get_height() + 12)


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


func _sway(s: Sprite2D) -> void:
	var m := ShaderMaterial.new()
	m.shader = SWAY
	m.set_shader_parameter("height", s.region_rect.size.y if s.region_enabled else float(s.texture.get_height()))
	m.set_shader_parameter("strength", 0.0 if Settings.reduced_motion else 1.0)
	s.material = m


## A one-shot puff of pixel particles.
func _burst(pos: Vector2, colours: Array, amount: int) -> void:
	if Settings.reduced_motion:
		amount = maxi(2, amount / 3)
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
	world.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _dust(pos: Vector2, amount: int) -> void:
	_burst(pos, [Color(0.78, 0.68, 0.55, 0.9), Color(0.66, 0.58, 0.48, 0.8)], amount)


func _add_texture(tex: Texture2D, pos: Vector2, parent: Node = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	(parent if parent else world).add_child(s)
	return s


## Adds a sprite cropped to its visible pixels; with from_bottom, pos.y is ignored and the sprite stands on base_y.
func _add_trimmed(tex: Texture2D, pos: Vector2, from_bottom := false, base_y := 0, parent: Node = null) -> Sprite2D:
	var s := _add_texture(tex, pos, parent)
	var used := tex.get_image().get_used_rect()
	s.region_enabled = true
	s.region_rect = used
	if from_bottom:
		s.position.y = base_y - used.size.y
	return s
