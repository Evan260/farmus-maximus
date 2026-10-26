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
const Cat := preload("res://scripts/world/cat.gd")
const Scaffold := preload("res://scripts/world/scaffold.gd")
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
const CART_HOME_X := HOME + 505.0
## The lowest row the view shows: the road to town runs along the bottom, below the fields.
const BOTTOM := 286.0
## The helpers who are women, so their greeting uses a woman's voice.
const WOMEN := ["miller", "perfumer", "stablehand"]
const RIG_BASE := 282
## How much longer and taller each cart is than the first, as tools/art/make_cart_levels.py draws them.
const CART_GROW := [Vector2i(0, 0), Vector2i(12, 3), Vector2i(24, 6), Vector2i(36, 8)]
## The middle of the castellum, where the aqueduct's water is let into the farm's channel.
const CASTELLUM_X := 468.0
## Where the original storehouse's left edge and foot fall in the pictures of its later levels.
const STORE_HOUSE_AT := Vector2(47, 88)
## Where milestones stand along the road, in estate pixels.
const MILESTONES := [330, 930, 1530, 2130]
const PAN_SPEED := 260.0
## Where each helper spends their day, in estate pixels.
const HELPER_GROUNDS := {
	"farmhand": [490.0, 930.0], "miller": [1130.0, 1400.0], "beekeeper": [150.0, 300.0], "perfumer": [990.0, 1610.0],
	"presser": [360.0, 1900.0], "stablehand": [1940.0, 2380.0], "trader": [1080.0, 1120.0],
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
## Each building's state as last seen, by building.
var _building_states := {}
## Scaffolding stood against the storehouse while it is being enlarged.
var _store_scaffold: Node2D
## The fenced pasture with its hens and goats.
var _pasture: Node2D
## The Roman road paved over the dirt one, as far as it has been laid.
var _road: Sprite2D
var _road_works: Node2D
## The raised kerbstones along the road's far edge, laid by the second road improvement.
var _kerb: Sprite2D
## How far along the road the milestones have been set.
var _milestone_reach := -40.0
## How far the gravel footpath along the verge has been laid.
var _footpath_reach := -40.0
## Where the paving has reached while a stretch is being laid.
var _paving_front := -40.0
## How far the paving itself reaches along the road.
var _paved_reach := -40.0
## The water channel along the front of the home farm.
var _channels: Node2D
## The cart that brings paving stones up to the work, with its donkey and its load.
var _stone_cart: Node2D
var _stone_donkey: AnimatedSprite2D
## Where the stone cart stands on the road, and its wheel.
var _stone_x := 0.0
var _stone_wheel: Sprite2D
## Scaffolding stood in front of the farmhouse while it is being restored.
var _villa_scaffold: Node2D
var _villa_hovered := false
var _stork: Sprite2D
## The stork's poses by name, and how long until it changes pose.
var _stork_poses := {}
var _stork_timer := 4.0
var _cart: Sprite2D
var _cart_shadow: Sprite2D
var _wheel: Sprite2D
## The wagon's second pair of wheels, under the front of the bed, for the biggest cart.
var _front_wheel: Sprite2D
## The cart's back rim and the inside of its bed, drawn behind the goods; the cart itself is the front wall and wheels.
var _cart_back: Sprite2D
## Where the cart's left edge stands when it is parked at home.
var _cart_park_x := 0.0
## True while the cart is setting off for the market with the player.
var _riding := false
## How many pixels longer and taller than the first cart the current one is.
var _cart_grow := Vector2i.ZERO
## The goods heaped in the cart, drawn behind its side boards so they sit inside it.
var _cart_load: Node2D
var _cart_x := 0.0
## The near shaft and the harness straps, drawn over the donkey so the cart is visibly hitched to it.
var _harness: Node2D
var _cart_returning := false
var _donkey: AnimatedSprite2D
## Where the donkey is on its own between dusk and dawn: "" while it is hitched to the cart, "out" while it walks to
## the barn, "barn" for the night, and "back" while it comes home in the morning.
var _donkey_night := ""
var _donkey_tween: Tween
var _donkey_first_look := true
## How far the trader's cart has tipped forward, in radians, with no donkey in its shafts.
var _cart_tilt := 0.0
## The paving cart's back, heap and front, which tip together, and where its donkey is between dusk and dawn.
var _stone_parts: Array = []
var _stone_night := ""
var _rig_tween: Tween
var _storehouse: Sprite2D
var _glow_layer: CanvasLayer
## Which way the view drifts behind the title screen.
var _title_drift := 1.0
## Rabbits, the fox and other wild visitors.
var _wildlife: Node2D
## Shepherds and travellers on the road, while they are on the estate.
var _passers: Array = []
## The golden laurel wreath over the villa door, hung for the Triumph.
var _wreath: Sprite2D
## One light per villa window, each with its own evening: when it is lit, when it goes out, and its flicker.
var _windows: Array = []
var _windows_night := -1
var _hammer_timer := 0.0
var _camera: Camera2D
var _sky_layer: CanvasLayer
var _helpers := {}
## Builders at work, by the site they are working on.
var _builders := {}
## Weeds and bushes grown up around each building still in ruins, by building.
var _overgrowth := {}
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
var _centre := HOME + 240.0


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
	_villa_scaffold = Scaffold.new()
	_villa_scaffold.storeys = 2
	_villa_scaffold.visible = false
	world.add_child(_villa_scaffold)
	_stork = _add_texture(load("res://assets/sprites/animals/stork/nest.png") if ResourceLoader.exists("res://assets/sprites/animals/stork/nest.png") else null, Vector2.ZERO)
	_villa_outline = Node2D.new()
	_villa_outline.draw.connect(_draw_villa_overlay)
	world.add_child(_villa_outline)
	_place_villa()
	_add_texture(Lighting.ellipse_texture(70, 7, SHADOW), Vector2(HOME + 194, 230))
	_storehouse = _add_trimmed(load("res://assets/sprites/farm/storehouse.png"), Vector2(HOME + 198, 0), true, 236)
	_dress_storehouse()
	_build_buildings()
	_scatter_meadow.call_deferred()
	_flowers_by_hives.call_deferred()
	_root_in_ground.call_deferred(_villa_rect().grow_individual(-12, 0, -12, 0), 851, _villa)
	_root_in_ground.call_deferred(Rect2(_storehouse.position, _storehouse.region_rect.size), 678, _storehouse)
	_sync_overgrowth.call_deferred()
	var decor := DecorView.new()
	decor.glow_layer = _glow_layer
	world.add_child(decor)
	_add_texture(load(BG + "ground.png"), Vector2(-40, 0))
	_road = _add_texture(load(BG + "road_paved.png"), Vector2(-40, 270))
	_road.region_enabled = true
	_kerb = _add_texture(_road.texture, Vector2(-40, 270))
	_kerb.region_enabled = true
	_road_works = Node2D.new()
	_road_works.draw.connect(_draw_road_works)
	world.add_child(_road_works)
	_pave_road()
	_pasture = Pasture.new()
	world.add_child(_pasture)
	var ground_fx := WeatherFx.new()
	ground_fx.plant_tops = _plant_tops
	world.add_child(ground_fx)
	_channels = Channels.new()
	world.add_child(_channels)
	_build_plots()
	_build_signs()

	var critters := Critters.new()
	critters.bloom_points = _bloom_points
	world.add_child(critters)
	_wildlife = Wildlife.new()
	_wildlife.lizard_wall = Rect2(_storehouse.position + Vector2(6, 20), Vector2(_storehouse.region_rect.size.x - 12, 18))
	world.add_child(_wildlife)
	_spawn_pets()

	_cart_shadow = _add_texture(Lighting.ellipse_texture(96, 6, SHADOW), Vector2.ZERO)
	# The goods sit between the cart's back rim and its front wall, so they look loaded inside it.
	_cart_back = _add_trimmed(load("res://assets/sprites/farm/cart.png"), Vector2(CART_HOME_X, 0), true, RIG_BASE)
	_cart_back.texture = load("res://assets/sprites/farm/cart_back.png")
	_cart_load = Node2D.new()
	world.add_child(_cart_load)
	_cart = _add_trimmed(load("res://assets/sprites/farm/cart.png"), Vector2(CART_HOME_X, 0), true, RIG_BASE)
	_cart_park_x = _cart.position.x
	# The wheel is a separate sprite so it can turn; the body keeps the full cart's outline for placement.
	_cart.texture = load("res://assets/sprites/farm/cart_front.png")
	_wheel = Sprite2D.new()
	_wheel.texture = load("res://assets/sprites/farm/cart_wheel.png")
	_wheel.centered = false
	_wheel.offset = Vector2(-12, -12)
	_cart.add_child(_wheel)
	_front_wheel = Sprite2D.new()
	_front_wheel.texture = _wheel.texture
	_front_wheel.centered = false
	_front_wheel.offset = Vector2(-12, -12)
	_front_wheel.visible = false
	_cart.add_child(_front_wheel)
	_donkey = AnimatedSprite2D.new()
	_donkey.sprite_frames = _donkey_frames()
	_donkey.centered = false
	_donkey.offset = Vector2(-32, -_feet_line(load("res://assets/sprites/donkey/walk_east/frame_00.png")))
	_donkey.play("stand")
	world.add_child(_donkey)
	_harness = Node2D.new()
	_harness.draw.connect(_draw_harness)
	world.add_child(_harness)
	_size_cart()
	Game.upgrade_bought.connect(_on_upgrade_bought)
	Game.upgrade_started.connect(_on_upgrade_started)
	_store_scaffold = Scaffold.new()
	_store_scaffold.rect = Rect2(_storehouse.position, _storehouse.region_rect.size)
	_store_scaffold.visible = Game.projects.has("storage")
	world.add_child(_store_scaffold)
	_park_rig()
	_build_stone_cart()
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
	market.left_town.connect(_back_from_market)
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
	Game.pets_changed.connect(_spawn_pets)
	if Game.cart["away"]:
		_cart.position.x = estate_width + 60
		_donkey.position.x = _harness_x(_cart.position.x, false)
	_centre = HOME + 240.0
	cam_x = _centre - _last_view_width / 2.0
	_update_view()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			var z := Game.zone_info(arg.trim_prefix("--zone="))
			_centre = float(z.get("x", 0)) + 240.0
			cam_x = _centre - _last_view_width / 2.0
			_update_view()
		elif arg == "--town":
			go_to_town.call_deferred()
		elif arg.begins_with("--town="):
			go_to_town.call_deferred()
			market.call_deferred("_open", arg.trim_prefix("--town="))
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


## Saves eight frames a quarter of a second apart (or --burst-gap seconds), for checking anything that flickers or moves.
func _take_burst(prefix: String) -> void:
	for i in 45:
		await get_tree().process_frame
	for k in 8:
		get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, k])
		var gap := 0.25
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--burst-gap="):
				gap = float(arg.trim_prefix("--burst-gap="))
		await get_tree().create_timer(gap).timeout
	get_tree().quit()


func _open_panel(which: String) -> void:
	if which.begins_with("journal:"):
		hud.open_window("journal")
		hud.show_journal_entry(which.trim_prefix("journal:"))
	elif which.begins_with("settings:"):
		hud.open_window("settings")
		hud._settings.tab = which.trim_prefix("settings:")
		hud._settings.show_page()
	elif which in ["journal", "helpers", "store", "settings", "upgrades", "companions"]:
		hud.open_window(which)
	else:
		hud.show_building(which)


## The donkey sets off down the road with the cart before the market town comes into view.
func _ride_to_market() -> void:
	if _riding:
		return
	if Settings.reduced_motion or Windowing.strip or _donkey_night != "":
		go_to_town()
		return
	_riding = true
	var wheels := Sfx.play("cart_stone" if _paved_reach > _cart.position.x + 60.0 else "cart_dirt")
	_face_rig(false)
	_donkey.play("walk")
	_move_rig(_cart.position.x + 220.0, 220.0 / 90.0)
	await get_tree().create_timer(2.1).timeout
	Sfx.fade_out(wheels, 1.2)
	go_to_town()
	_riding = false


func _back_from_market() -> void:
	hud.visible = true
	if not Game.cart["away"] and not _cart_returning:
		if _rig_tween:
			_rig_tween.kill()
		_park_rig()


func go_to_town() -> void:
	if Windowing.strip:
		return
	Dissolve.play(self, func() -> void:
		hud.close_windows()
		hud.visible = false
		market.enter())


func _process(delta: float) -> void:
	if Game.villa_build["active"]:
		_villa_outline.queue_redraw()
	var night := Lighting.night_amount(Game.day_time)
	var light: Color = Lighting.color_at(Game.day_time) * SEASON_TINT.get(Game.calendar.season_id(), Color.WHITE)
	if Game.calendar.weather in ["cloudy", "rain"]:
		light = light.darkened(0.12)
	_daylight.color = Color(light, 1.0)
	# At night the far mountains become dark shapes against the starry sky instead of glowing blue.
	var far := Color.WHITE.lerp(Color(0.62, 0.6, 0.7), night)
	_mountains.modulate = far
	_mountains_far.modulate = far
	_light_windows(night)
	var windy := 1.6 if Game.calendar.weather in ["rain", "cloudy"] else 1.0
	if PlotView.wind:
		PlotView.wind.set_shader_parameter("strength", 0.0 if Settings.reduced_motion else windy)
	var typing := get_viewport().gui_get_focus_owner() is LineEdit
	var keys := 0.0 if typing else Input.get_axis("pan_left", "pan_right") + Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) * float(absf(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)) > 0.2)
	if keys != 0.0 and not market.visible:
		_pan_by(keys * PAN_SPEED * delta)
	# Behind the title screen the view drifts slowly along the estate and back.
	if hud.title_open() and not Settings.reduced_motion:
		var edge := maxf(0.0, estate_width - _view_size().x)
		if cam_x >= edge - 1.0 or cam_x <= 1.0:
			_title_drift = -1.0 if cam_x >= edge - 1.0 else 1.0
		_pan_by(_title_drift * 9.0 * delta)
	_stable_donkey()
	_idle_stork(delta)
	_cart_shadow.position = Vector2(_cart.position.x - 2, RIG_BASE - 5)
	_cart_load.position = _cart.position
	_cart_back.position = _cart.position
	_cart_back.flip_h = _cart.flip_h
	_tip_cart(delta)
	_harness.queue_redraw()
	# The wheel turns by the distance travelled over its radius, in steps fine enough to look smooth at this size.
	var rolled := _cart.position.x - _cart_x
	_cart_x = _cart.position.x
	if rolled != 0.0:
		_wheel.rotation = snappedf(_wheel.rotation + rolled / 12.0, PI / 24.0)
		_front_wheel.rotation = _wheel.rotation
	if Engine.get_process_frames() % 20 == 0:
		_update_cart_load()
	if Windowing.strip and Windowing.transparent:
		_click_area_timer -= delta
		if _click_area_timer <= 0.0:
			_click_area_timer = 0.5
			Windowing.set_click_area(_click_area())
	if Game.villa_build["active"] and not Game.is_night():
		_hammer_timer -= delta
		if _hammer_timer <= 0.0:
			_hammer_timer = randf_range(1.2, 2.6)
			Sfx.play("hammer", -10.0, 0.15)
			_dust(_villa.position + Vector2(randf_range(10, _villa.region_rect.size.x - 10), _villa.region_rect.size.y - 4), 6)
	for v in building_views:
		if Game.buildings[v.id]["state"] in ["repairing", "upgrading"] and not Game.is_night() and randf() < delta * 0.5:
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
	_update_road_cart(delta)
	if Engine.get_process_frames() % 30 == 0:
		_sync_builders()
		_sync_overgrowth()
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
	if _traveller_timer <= 0.0 and Game.is_night():
		_traveller_timer = 30.0
	elif _traveller_timer <= 0.0:
		_traveller_timer = randf_range(90.0, 240.0)
		var who: String = ["shepherd", "traveller"][randi() % 2]
		if ResourceLoader.exists(PEOPLE + who + "/east.png"):
			var w := Walker.new()
			w.dir = PEOPLE + who + "/"
			var from_right := randf() < 0.5
			w.position = Vector2(estate_width + 20 if from_right else 1430.0, 283)
			w.leave_at = 1430.0 if from_right else estate_width + 20
			w.speed = 16.0
			w.react_folder = "greet"
			w.display_name = tr("A shepherd") if who == "shepherd" else tr("A traveller")
			w.voice = "salve_man"
			world.add_child(w)
			_passers.append(w)
	if cat and dog and dog.is_asleep() and cat.is_asleep() and absf(cat.position.x - dog.position.x) < 60.0:
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
		if Game.buildings[v.id]["state"] in ["repairing", "upgrading"]:
			var r: Rect2 = v.world_rect()
			var id := String(v.id)
			sites[id] = {"rect": r, "planks": Scaffold.plank_rows(r), "ladders": Game.building_info(id).get("ladders", []).map(func(x): return r.position.x + float(x)),
				"left": func() -> float: return float(Game.buildings[id].get("time_left", 0.0))}
	for id in Game.projects:
		var left := func() -> float: return float(Game.projects.get(id, 0.0))
		sites["project_" + id] = {"rect": _project_site(String(id)), "ladders": [], "left": left}
	if Game.villa_build["active"]:
		var r := _villa_rect()
		var ladders: Array = _villa_ladders().map(func(x): return r.position.x + x)
		var left := func() -> float: return float(Game.villa_build["time_left"])
		sites["villa_a"] = {"rect": r, "planks": Scaffold.plank_rows(r, 2), "ladders": ladders, "left": left}
		sites["villa_b"] = {"rect": r, "planks": Scaffold.plank_rows(r, 2), "ladders": ladders, "left": left}
	for id in _builders.keys():
		if not sites.has(id):
			_builders[id].leave()
			_builders.erase(id)
	for id in sites:
		# Builders on the water channel and the road move along with the work.
		if _builders.has(id):
			_builders[id].site = sites[id]["rect"]
		if not _builders.has(id):
			var b := Builder.new()
			b.site = sites[id]["rect"]
			b.ladders = sites[id]["ladders"]
			b.planks = sites[id].get("planks", [])
			b.follows = id in ["project_cart_speed", "project_channels"]
			b.time_left = sites[id]["left"]
			b.town_x = estate_width
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
	w.position = Vector2(randf_range(w.min_x, w.max_x), 269)
	# At night helpers go indoors: the farmhouse for those working near it, otherwise the end of their own patch.
	w.rests_at_night = true
	w.home_x = clampf(VILLA_BASE.x, w.min_x, w.max_x)
	var info := Game.helper_info(id)
	w.react_folder = "greet"
	w.display_name = "%s, %s" % [tr(String(info.get("name", ""))), tr(String(info.get("role", ""))).to_lower()]
	w.voice = "salve_woman" if id in WOMEN else "salve_man"
	if info.has("zones") or info.has("crops"):
		w.find_work = func() -> float: return _ready_plot_x(info)
		w.work_done = func(x: float) -> String: return Game.helper_harvest(id, _plot_near(x))
		w.carry_to = _drop_spot
		w.can_drop = _can_drop
		w.work_seconds = clampf(Game.helper_interval(id) * 0.6, 0.8, 4.0)
		Game.live_helpers[id] = true
	world.add_child(w)
	_helpers[id] = w


## Where a helper takes what they picked: into the cart when it is home and near, to a nearby workshop that uses it,
## or else to the storehouse.
func _drop_spot(item: String, from_x: float) -> float:
	# Goods go into the cart only when the trader will take them; anything kept or needed stays on the estate.
	var for_trader := Game.helpers.has("trader") and Game.for_sale(item) and not item in Game.reserved_items()
	if for_trader and absf(from_x - CART_HOME_X) < 520.0:
		return _cart_side()
	for v in building_views:
		if Game.buildings[v.id]["state"] == "working" and Game.current_recipe(v.id).get("in", {}).has(item) and absf(v.position.x - from_x) < 320.0:
			return v.position.x
	return _storehouse.position.x + _storehouse.region_rect.size.x / 2.0


## Where a helper stands to load the cart: beside its back end, clear of the wheels.
func _cart_side() -> float:
	return _cart_park_x - 5.0


## The cart takes a load only while it stands parked at home; a helper bringing goods waits for it otherwise.
func _can_drop(at: float) -> bool:
	if at != _cart_side():
		return true
	return not Game.cart["away"] and absf(_cart.position.x - _cart_park_x) < 1.0


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
	Settings.show_tutorial = false
	Game.new_game()
	Game.intro_seen = true
	Game.farm_name = "Villa Aurelia"
	# Enough of everything to buy and build anything straight away.
	Game.coins = 10000000
	Game.aureus = 1000
	Game.build_speed = 5.0
	Game.levels["storage"] = Balance.get_value("upgrades.storage.values", [12]).size() - 1
	Game.storage = {"stone": 999, "timber": 999, "tiles": 999}
	for item in Balance.get_value("items", {}):
		if String(Balance.get_value("items.%s.kind" % item, "good")) == "good":
			Game.storage[item] = 4
	Game.storage["bread"] = 15
	var stages := [1.0, 1.0, 0.7, 1.0, 0.4, 1.0, 1.0, 0.1, 1.0, 1.0, 0.8, 1.0, 1.0, 0.3, 1.0, 1.0, 0.0]
	for i in Game.plots.size():
		var p: Dictionary = Game.plots[i]
		if p["zone"] == "home":
			p["unlocked"] = i < 15 or i >= Game.plots.size() - 5
			if p["unlocked"]:
				p["crop"] = ["lavender", "lavender", "lavender_violet", "lavender", "lavender_bluegrey", "lavender", "lavender_white", "wheat"][i % 8]
				p["growth"] = stages[i % stages.size()] * Game.time_to_ready(p)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			Game.day_time = float(arg.trim_prefix("--hour="))
		elif arg.begins_with("--villa="):
			Game.villa_stage = int(arg.trim_prefix("--villa="))
		elif arg == "--aurora":
			(func() -> void: _sky_view.force_aurora = true).call_deferred()
		elif arg == "--rainbow":
			(func() -> void: _sky_view.fx.show_rainbow(40.0)).call_deferred()
		elif arg.begins_with("--weather="):
			Game.calendar.weather = arg.trim_prefix("--weather=")
			Game.calendar.weather_left = 9999.0
			Game.calendar.wet_left = 9999.0 if Game.calendar.weather == "rain" else 0.0
		elif arg.begins_with("--day="):
			Game.calendar.day = int(arg.trim_prefix("--day="))
		elif arg.begins_with("--cart="):
			Game.levels["cart_capacity"] = int(arg.trim_prefix("--cart="))
		elif arg.begins_with("--road="):
			Game.levels["cart_speed"] = int(arg.trim_prefix("--road="))
		elif arg.begins_with("--start="):
			Game.buy_upgrade.call_deferred(arg.trim_prefix("--start="))
		elif arg == "--build-villa":
			Game.upgrade_villa.call_deferred()
		elif arg == "--send-cart":
			Game.send_cart.call_deferred()
		elif arg == "--estate":
			_demo_estate()
		elif arg == "--maxed":
			_demo_estate()
			_demo_maxed()
		elif arg.begins_with("--pets="):
			var breeds := arg.trim_prefix("--pets=").split(",")
			Game.pets["dog"]["breed"] = breeds[0]
			Game.pets["dog"]["coat"] = Coats.options("dog", breeds[0]).keys()[0]
			if breeds.size() > 1:
				Game.pets["cat"]["breed"] = breeds[1]
				Game.pets["cat"]["coat"] = Coats.options("cat", breeds[1]).keys()[0]
			_spawn_pets.call_deferred()
		elif arg == "--greet":
			get_tree().create_timer(1.6).timeout.connect(func():
				for w in _people() + market._folk:
					w.greet())
		elif arg == "--triumph":
			for a in Balance.get_value("achievements", []):
				if not a.get("special", false):
					Game.journal.achievements[a["id"]] = true
			Game.check_achievements.call_deferred()


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
		Game.buildings[id]["time_left"] = float(Game.building_info(id).get("repair_seconds", 60)) * 0.8
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
	Game.storage.merge({"lavender@1": 2, "bread@2": 1}, true)
	var fills := {"grove": [1.0, 0.5, 1.0, 0.2, 1.0, 0.8], "vineyard": [1.0, 0.7, 1.0, 0.3, 1.0, 0.6]}
	var counts := {"grove": 0, "vineyard": 0}
	for i in Game.plots.size():
		var zone := String(Game.plots[i]["zone"])
		if fills.has(zone):
			Game.plots[i]["unlocked"] = true
			var olive: bool = counts[zone] % 3 != 1 and counts[zone] < 6
			Game.plots[i]["crop"] = ("olives" if olive else "herbs") if zone == "grove" else "grapes"
			Game.plots[i]["growth"] = fills[zone][counts[zone] % fills[zone].size()] * Game.time_to_ready(Game.plots[i])
			counts[zone] += 1
	Game.market.add_order()
	Game.market.add_order()


## Everything at its best: the grand estate, every building working at its top level, every helper fully trained, every
## upgrade bought, every bed planted and every page of the journal found.
func _demo_maxed() -> void:
	Game.quiet = true
	Game.villa_stage = Game.villa_stages().size()
	for id in Game.buildings:
		var b: Dictionary = Game.buildings[id]
		b["state"] = "working"
		b["level"] = Game.building_info(id).get("levels", []).size()
	var barn: Dictionary = Game.buildings["barn"]
	for kind in ["chicken", "goat"]:
		barn["animals"][kind] = Game.animal_capacity(kind)
	barn["feed"] = 40
	for h in Balance.get_value("helpers", {}):
		Game.helpers[h] = Game.helper_info(h).get("costs", [0]).size()
	for u in Game.levels:
		Game.levels[u] = Balance.get_value("upgrades.%s.values" % u, [0]).size() - 1
	for d in Balance.get_value("decorations", {}):
		Game.decorations[d] = true
	var home_crops := ["lavender", "lavender_violet", "lavender_bluegrey", "lavender_white", "wheat", "lavender"]
	for i in Game.plots.size():
		var p: Dictionary = Game.plots[i]
		p["unlocked"] = true
		if p["zone"] == "home":
			p["crop"] = home_crops[i % home_crops.size()]
			p["growth"] = (1.0 if i % 3 != 1 else 0.6) * Game.time_to_ready(p)
	for entry in Game.journal.catalogue():
		Game.discover(String(entry["id"]))
	# The trader would carry the full storehouse off at once, so every good starts marked to keep.
	for item in Balance.get_value("items", {}):
		Game.keep_goods[item] = true
	Game.quiet = false


## Tufts, weeds and wildflowers across the estate's grass, with a band of long uncut grass along its back edge where
## it meets the walls and buildings; the ground picture says where the grass is, and the planting beds are kept clear.
func _scatter_meadow() -> void:
	var ground: Image = (load(BG + "ground.png") as Texture2D).get_image()
	var grassy := func(x: float, y: float) -> bool:
		var c := ground.get_pixel(clampi(int(x) + 40, 0, ground.get_width() - 1), clampi(int(y), 0, ground.get_height() - 1))
		return c.a > 0.0 and c.g > c.r + 0.06
	var clear_of_beds := func(x: float, y: float) -> bool:
		return not plot_views.any(func(p): return absf(x - p.position.x - 15.0) < 20.0 and absf(y - p.position.y) < 12.0)
	var node := Node2D.new()
	world.add_child(node)
	world.move_child(node, plot_views[0].get_index())
	# Grass in the pasture grows behind the fence and the animals rather than over them.
	var pasture_grass := Node2D.new()
	world.add_child(pasture_grass)
	world.move_child(pasture_grass, _pasture.get_index())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var plants := []
	var x := 0.0
	while x < estate_width:
		# The castellum stands at the head of the water channel, and no grass grows across its front.
		if grassy.call(x, 240.0) and clear_of_beds.call(x, 238.0) and absf(x - CASTELLUM_X) > 26.0:
			var tall: Array[Texture2D] = GroundPlants.tall_textures()
			plants.append([tall[rng.randi() % tall.size()], Vector2(x, 238 + rng.randi_range(0, 2))])
		x += rng.randf_range(3.0, 9.0)
	for i in int(estate_width / 9.0):
		var at := Vector2(rng.randf_range(0.0, estate_width), rng.randf_range(244.0, 267.0))
		if grassy.call(at.x, at.y) and clear_of_beds.call(at.x, at.y) and absf(at.x - CASTELLUM_X) > 30.0:
			var tufts: Array[Texture2D] = GroundPlants.textures()
			plants.append([tufts[rng.randi() % tufts.size()], at])
	plants.sort_custom(func(a, b): return a[1].y < b[1].y)
	for entry in plants:
		var plant := Sprite2D.new()
		plant.texture = entry[0]
		plant.centered = false
		plant.flip_h = rng.randf() < 0.5
		plant.position = (entry[1] - Vector2(roundf(entry[0].get_width() / 2.0), entry[0].get_height())).round()
		var in_pasture: bool = entry[1].x > Pasture.FENCE_LEFT - 16.0 and entry[1].x < Pasture.FENCE_RIGHT + 10.0
		(pasture_grass if in_pasture else node).add_child(plant)
		_sway(plant)


## Wild flowers at the foot of the beehives, where the bees have the least way to go.
func _flowers_by_hives() -> void:
	var hives: Rect2 = building_views.filter(func(v): return v.id == "beehives")[0].world_rect()
	var node := Node2D.new()
	world.add_child(node)
	world.move_child(node, plot_views[0].get_index())
	var flowers := GroundPlants.flower_textures()
	for k in 5:
		var tex: Texture2D = flowers[(k * 2 + 1) % flowers.size()]
		var at := Vector2(hives.position.x - 6 + k * (hives.size.x + 12) / 4.0, hives.end.y + 2 + (k % 2) * 2).round()
		var plant := _add_texture(tex, at - Vector2(roundf(tex.get_width() / 2.0), tex.get_height()), node)
		_sway(plant)


## A fringe of grass and a few strands of vine along a building's foot, so it sits in the ground rather than on it.
func _root_in_ground(rect: Rect2, seed: int, after: Node) -> void:
	var node := Node2D.new()
	world.add_child(node)
	world.move_child(node, after.get_index() + 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var tufts := GroundPlants.textures()
	var x := rect.position.x + rng.randf_range(0.0, 6.0)
	while x < rect.end.x - 4.0:
		var tex: Texture2D = tufts[rng.randi() % tufts.size()]
		var plant := Sprite2D.new()
		plant.texture = tex
		plant.centered = false
		plant.flip_h = rng.randf() < 0.5
		plant.position = Vector2(roundf(x), rect.end.y + rng.randi_range(0, 2) - tex.get_height())
		node.add_child(plant)
		x += rng.randf_range(6.0, 16.0)
	var vines := []
	for i in rng.randi_range(2, 4):
		vines.append([roundf(rng.randf_range(rect.position.x + 4.0, rect.end.x - 4.0)), rng.randi_range(4, 10), rng.randi_range(0, 1000)])
	node.draw.connect(func() -> void:
		for v in vines:
			for k in int(v[1]):
				var vx: float = v[0] + (1.0 if (int(v[2]) + k) % 5 == 0 else 0.0)
				node.draw_rect(Rect2(vx, rect.end.y - 1 - k, 1, 1), Color8(70, 98, 46))
				if (k + int(v[2])) % 3 == 0:
					node.draw_rect(Rect2(vx + (1 if k % 2 else -1), rect.end.y - 1 - k, 1, 1), Color8(104, 132, 60)))


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
	# Beds added later, on the far side of the walkway to the farmhouse.
	for x in [866, 902, 938]:
		spots.append(Vector2(x, FRONT_ROW))
	for x in [884, 920]:
		spots.append(Vector2(x, BACK_ROW))
	# More vines further along the slope, two flower beds in front of the beehives, and one more home bed by the walkway.
	for i in 4:
		spots.append(Vector2(1692 + i * 40, FRONT_ROW))
	for x in [112, 174]:
		spots.append(Vector2(x, BACK_ROW))
	spots.append(Vector2(794, BACK_ROW))
	# Each bed is nudged a few pixels by its own number, so the rows look planted by hand rather than ruled.
	for i in spots.size():
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 7919 + 17
		spots[i] += Vector2(rng.randi_range(-3, 3), rng.randi_range(-1, 1))
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
		_building_states[id] = String(Game.buildings[id]["state"])
		_root_in_ground.call_deferred(v.world_rect(), hash(id), v)


## A building nobody has started to repair stands in weeds, long grass and brambles; they are cleared when work begins.
func _sync_overgrowth() -> void:
	for v in building_views:
		var wild := String(Game.buildings[v.id]["state"]) in ["ruin", "owned"]
		if wild and not _overgrowth.has(v.id):
			_overgrowth[v.id] = _grow_wild(v)
		elif not wild and _overgrowth.has(v.id):
			var node: Node2D = _overgrowth[v.id]
			_overgrowth.erase(v.id)
			for part in [node, node.get_meta("ground")]:
				var fade: Tween = part.create_tween()
				fade.tween_property(part, "modulate:a", 0.0, 1.5)
				fade.tween_callback(part.queue_free)


func _grow_wild(v: Node2D) -> Node2D:
	var node := Node2D.new()
	world.add_child(node)
	world.move_child(node, v.get_index() + 1)
	var r: Rect2 = v.world_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(v.id)
	var plants := []
	# A few big weeds and brambles against the walls...
	var kinds := ["grass", "grass", "weeds", "weeds", "bramble", "thistle"]
	var x := r.position.x - 8.0 + rng.randf_range(0.0, 10.0)
	while x < r.end.x:
		var tex: Texture2D = load("res://assets/sprites/wild/%s.png" % kinds[rng.randi() % kinds.size()])
		var used := tex.get_image().get_used_rect()
		plants.append([tex, Vector2(roundf(x - used.position.x), roundf(r.end.y + rng.randi_range(0, 2) - used.end.y)), used.end.y])
		x += used.size.x * rng.randf_range(1.3, 2.2)
	# ...and little tufts scattered over the ground in front, kept off the planting beds. They are drawn with the beds,
	# over the ground strip, rather than with the building behind it.
	var ground := Node2D.new()
	world.add_child(ground)
	world.move_child(ground, plot_views[0].get_index())
	node.set_meta("ground", ground)
	var tufts := GroundPlants.textures()
	for i in int(r.size.x / 6.0):
		var at := Vector2(roundf(rng.randf_range(r.position.x - 30.0, r.end.x + 30.0)), roundf(rng.randf_range(r.end.y + 4.0, 267.0)))
		if plot_views.any(func(p): return absf(at.x - p.position.x - 15.0) < 22.0 and absf(at.y - p.position.y) < 12.0):
			continue
		# The castellum at the head of the water channel stands on clear ground.
		if absf(at.x - 470.0) < 30.0:
			continue
		var tex: Texture2D = tufts[rng.randi() % tufts.size()]
		plants.append([tex, at - Vector2(roundf(tex.get_width() / 2.0), tex.get_height()), at.y, ground])
	# Plants lower on the ground stand in front of those behind them.
	plants.sort_custom(func(a, b): return a[1].y + a[0].get_height() < b[1].y + b[0].get_height())
	for entry in plants:
		var plant := Sprite2D.new()
		plant.texture = entry[0]
		plant.centered = false
		plant.flip_h = rng.randf() < 0.5
		plant.position = entry[1]
		(entry[3] if entry.size() > 3 else node).add_child(plant)
		_sway(plant)
	return node


func _build_signs() -> void:
	for z in Game.zones():
		if int(z.get("deed", 0)) == 0:
			continue
		var s := ZoneSign.new()
		s.zone_id = z["id"]
		s.position = Vector2(float(z["x"]) + float(z.get("sign_x", 240)), 240)
		world.add_child(s)
		signs.append(s)


## Frames the scene: the camera follows cam_x across the estate, anchored to the bottom so the desktop strip shows the farm.
func _update_view() -> void:
	var view := _view_size()
	# When the window changes size the view keeps its centre, so resizing never jumps to another part of the estate.
	var resized := view.x != _last_view_width
	if resized:
		cam_x = _centre - view.x / 2.0
		_last_view_width = view.x
	# The centre is noted before the edges of the estate hold the camera back, so it survives a passing window size.
	if not resized:
		_centre = cam_x + view.x / 2.0
	cam_x = clampf(cam_x, 0.0, maxf(0.0, estate_width - view.x))
	_camera.position = Vector2(round(cam_x), BOTTOM - view.y)
	var left := roundf(cam_x)
	var s := float(Windowing.scale)
	# The sky is drawn at screen resolution, so it follows the unrounded pan and slides smoothly.
	_sky_view.scale = Vector2(s, s)
	_sky_view.position = Vector2(-cam_x * PARALLAX["sky"] * s, -(BOTTOM - view.y) * s)
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
	# The estate's picture is resized in the same frame as the window, rather than when the container next lays out,
	# so dragging the window's edge never shows a stretched or lagging frame.
	var window := get_viewport().get_visible_rect().size
	_container.size = window
	_viewport.size = Vector2i((window / Windowing.scale).ceil())
	_update_view()


## The estate's view in its own pixels: the window divided by the pixel scale, which the viewport takes on a moment later.
func _view_size() -> Vector2:
	return (get_viewport().get_visible_rect().size / Windowing.scale).floor()


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
	var top := view.y - (BOTTOM - 214.0)
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
	# Letters typed into a name field are not commands for the estate.
	if market.visible or (event is InputEventKey and get_viewport().gui_get_focus_owner() is LineEdit):
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
		# A trackpad sends many small scroll steps, each with a fraction of a wheel notch in its factor.
		var notch: float = 24.0 * (event.factor if event.factor > 0.0 else 1.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			_pan_by(-notch)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			_pan_by(notch)
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				_pressed = true
				_dragging = event.button_index == MOUSE_BUTTON_MIDDLE
				_drag_from = event.position
				_drag_start_cam = cam_x
			else:
				# A press that did not move far is a click; one that moved was a drag across the estate.
				if _pressed and not _dragging and event.button_index == MOUSE_BUTTON_LEFT:
					if hud.close_windows():
						Sfx.play("click", -10.0)
					else:
						_click(world.get_global_mouse_position())
				_pressed = false
				_dragging = false
	elif event is InputEventPanGesture:
		# Two fingers sliding on a trackpad pan the estate directly, sideways or up and down alike.
		_pan_by((event.delta.x + event.delta.y) * 6.0)
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


## A farm animal under the pointer that answers a click: a hen or goat in the pasture, the stork on its nest, or the
## donkey at the cart. Returns which, or "".
func _animal_at(point: Vector2) -> String:
	var grazing: Node2D = _pasture.animal_at(point)
	if grazing:
		return String(grazing.get_meta("kind"))
	if _stork.visible and Rect2(_stork.position, _stork.texture.get_size()).has_point(point):
		return "stork"
	if _donkey.visible and Hit.frame_rect(_donkey, _donkey).has_point(point):
		return "donkey"
	if not _wildlife.rabbit_at(point).is_empty():
		return "rabbit"
	return ""


func _call_out(animal: String, point: Vector2) -> void:
	var grazing: Node2D = _pasture.animal_at(point)
	if animal == "rabbit":
		_wildlife.startle(_wildlife.rabbit_at(point), point)
		return
	if grazing:
		grazing.react()
	elif animal == "donkey" and _donkey.animation == "stand" and not _riding:
		_donkey.play("bray")
		_donkey.animation_finished.connect(func(): _donkey.play("stand"), CONNECT_ONE_SHOT)
	elif animal == "stork" and not _stork.has_meta("bobbing"):
		# A stork greets by throwing its head back and clattering its bill, which reads as a quick bob at this size.
		_stork.set_meta("bobbing", true)
		var home := _stork.position
		var bob := create_tween()
		for k in 4:
			bob.tween_property(_stork, "position", home + Vector2(0, -1), 0.09)
			bob.tween_property(_stork, "position", home, 0.09)
		bob.tween_callback(func(): _stork.remove_meta("bobbing"))
	var sound: String = {"hen": "cluck", "goat": "goat", "stork": "stork", "donkey": "donkey"}.get(animal, "")
	Sfx.play(sound, -4.0, 0.1)
	_hearts(point + Vector2(0, -6))


## The dog or cat under the pointer, if it stands in front of the plant there (or there is no plant).
func _pet_at(point: Vector2, plant: Node2D) -> Node2D:
	for pet in [cat, dog] + _people():
		if pet and pet.contains(point) and (plant == null or pet.position.y >= plant.position.y):
			return pet
	return null


## The helpers, the trader and anyone passing along the road, who wave back when clicked.
func _people() -> Array:
	_passers = _passers.filter(func(w): return is_instance_valid(w))
	return _helpers.values() + _passers


## A click goes to whatever the pointer shows as hovered: a dog or cat in front, plants and signs, then buildings.
func _click(point: Vector2) -> void:
	var view := _plot_at(point)
	var pet := _pet_at(point, view)
	if pet:
		if pet in [cat, dog]:
			pet.pet()
		else:
			pet.greet()
		return
	if view:
		_click_plot(view.index)
		return
	var animal := _animal_at(point)
	if animal != "":
		_call_out(animal, point)
		return
	for s in signs:
		if s.contains(point):
			Game.buy_zone(s.zone_id)
			return
	var b := _building_at(point)
	if b:
		hud.show_building(b.id)
		return
	if _cart_rect().has_point(point) and not Game.cart["away"]:
		_ride_to_market()
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


## A click on a plot does what the tool in hand does there; a ripe plant is picked with any tool but the spade.
func _click_plot(i: int) -> void:
	var look := Game.plot_visual(i)
	if look == "locked":
		if not Game.zone_owned(String(Game.plots[i]["zone"])):
			hud.toast(tr("Buy this land first"))
		else:
			Game.try_unlock(i)
	elif hud.tool == "dig":
		if look in ["empty"]:
			hud.toast(tr("Nothing growing here to dig up"))
		else:
			Game.dig_up(i)
	elif look == "bloom":
		Game.try_harvest(i)
	elif look == "empty":
		if hud.tool == "seed":
			Game.try_plant(i)
		else:
			hud.toast(tr("Choose a seed in the toolbar to plant here"))
	else:
		hud.toast(tr("Still growing"))
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
	var pet_hit: Node2D = _pet_at(point, view) if not sign_hit else null
	if pet_hit:
		view = null
		for v in plot_views:
			v.hovered = false
	var pet: bool = pet_hit != null
	var animal: String = "" if view or sign_hit or pet else _animal_at(point)
	var building: Node2D = null if view or sign_hit or pet or animal != "" else _building_at(point)
	for b in building_views:
		b.hovered = b == building
	var on_villa := not view and not sign_hit and not pet and animal == "" and not building and not _cart_rect().has_point(point) and _villa_rect().has_point(point)
	if on_villa != _villa_hovered:
		_villa_hovered = on_villa
		_villa_outline.queue_redraw()
	if view:
		_describe_plot(view.index)
	elif sign_hit:
		var z := Game.zone_info(sign_hit.zone_id)
		var block := Game.zone_block(sign_hit.zone_id)
		hud.set_info(tr(block) if block != "" else tr("Buy the %s deed: %d sestertii") % [tr(String(z.get("name", ""))).to_lower(), int(z.get("deed", 0))])
	elif pet:
		hud.set_info(tr("Pet %s") % Game.pet_name("dog" if pet_hit == dog else "cat") if pet_hit in [cat, dog] else pet_hit.display_name)
	elif animal != "":
		hud.set_info(tr({"hen": "A hen", "goat": "A goat", "stork": "The stork on its nest", "donkey": "The donkey", "rabbit": "A rabbit"}.get(animal, "")))
	elif building:
		hud.set_info(tr("%s: click for details") % tr(String(Game.building_info(building.id).get("name", ""))))
	elif _villa_hovered:
		hud.set_info(tr("%s: click for details") % tr(String(Game.villa_stages()[clampi(Game.villa_stage - 1, 0, Game.villa_stages().size() - 1)].get("name", "Farmhouse"))))
	elif Rect2(_storehouse.position, _storehouse.region_rect.size).has_point(point):
		hud.set_info(tr("Storehouse: %d / %d") % [Game.stored_total(), Game.storage_capacity()])
	elif _cart_rect().has_point(point):
		hud.set_info(tr("The trader is away at market") if Game.cart["away"] else tr("Ride the cart to market"))
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
			if hud.tool != "seed":
				hud.set_info(tr("An empty bed: choose a seed in the toolbar"))
			elif seed_id == "":
				hud.set_info(tr(Game.seed_block(i)))
			else:
				var seed := Game.crop_info(seed_id)
				hud.set_info(tr("Plant %s: %d sestertii") % [tr(String(seed.get("name", ""))).to_lower(), int(seed.get("plant_cost", 0))])
		"bloom":
			hud.set_info(tr("Dig up the %s") % crop_name.to_lower() if hud.tool == "dig" else tr("%s is ready: click to harvest") % crop_name)
		_:
			var notes := []
			if not Game.watered(i):
				notes.append(tr("dry"))
			if Game.plots[i].get("manured", false):
				notes.append(tr("manured"))
			hud.set_info(tr("%s growing: %d%%") % [crop_name, int(Game.growth_fraction(i) * 100)] + ("  (%s)" % ", ".join(notes) if not notes.is_empty() else "") + ("   " + tr("click to dig up") if hud.tool == "dig" else ""))


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
	var reach := _donkey.position.x + 24 - _cart.position.x if _donkey_night == "" else _cart.region_rect.size.x
	return Rect2(_cart.position, Vector2(reach, _cart.region_rect.size.y))


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
	call_deferred("_note_state", id, state)
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
			"upgrading":
				Sfx.play("hammer")
				_dust(v.position, 14)
				hud.toast(tr("Builders are improving the %s") % name)
			"working":
				if _building_states.get(id, "") == "upgrading":
					Sfx.play("villa_complete")
					_dust(v.position, 24)
					hud.toast(tr("The %s is now level %d") % [name, int(Game.buildings[id]["level"]) + 1])
				elif int(Game.buildings[id]["level"]) == 0 and not Game.buildings[id]["busy"] and Game.buildings[id]["queue"].is_empty():
					Sfx.play("villa_complete")
					_dust(v.position, 24)
					hud.toast(tr("The %s is working again!") % name)


## Remembers each building's state, so a building coming back to work can tell an upgrade from a repair.
func _note_state(id: String, state: String) -> void:
	_building_states[id] = state


func _on_zone_bought(zone_id: String) -> void:
	Sfx.play("villa_complete")
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
	# Sent off while the donkey is stabled, it is fetched and put in the shafts straight away.
	if _donkey_night != "":
		if _donkey_tween:
			_donkey_tween.kill()
		_donkey_night = ""
		_donkey.visible = true
		_donkey.modulate.a = 1.0
		_donkey.position.y = RIG_BASE
		_donkey.speed_scale = 1.0
		_harness.visible = true
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
	Sfx.play("dog", -9.0, 0.06)
	Game.add_stat("pets", 1)
	_hearts(dog.position + Vector2(0, -32))


func _hearts(at: Vector2) -> void:
	var heart := Sprite2D.new()
	heart.texture = Lighting.heart_texture()
	heart.position = at
	world.add_child(heart)
	var t := create_tween().set_parallel()
	t.tween_property(heart, "position:y", heart.position.y - 12, 1.0)
	t.tween_property(heart, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(heart.queue_free)


func _on_build_started() -> void:
	Sfx.play("hammer")
	_place_villa()
	_villa_scaffold.visible = true
	if not Settings.reduced_motion:
		_villa_scaffold.rise()
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 16)
	hud.toast(tr("Work on the villa has begun"))


func _on_villa_finished() -> void:
	_place_villa()
	if Settings.reduced_motion:
		_villa_scaffold.visible = false
	else:
		_villa_scaffold.sink().tween_callback(func(): _villa_scaffold.visible = Game.villa_build["active"])
	Sfx.play("villa_complete")
	hud.toast(tr("The villa has been restored: %s!") % tr(String(Game.villa_stages()[Game.villa_stage - 1]["name"])).to_lower())
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 40)
	_villa.modulate = Color(1.6, 1.5, 1.3)
	create_tween().tween_property(_villa, "modulate", Color.WHITE, 0.9)


## Parks the cart with the donkey standing at its handles, both facing right towards the road to market.
func _park_rig() -> void:
	# A donkey walking to or from the barn, or stabled for the night, keeps to what it is doing.
	var walking_alone := _donkey_night != ""
	var facing := _donkey.flip_h
	_face_rig(false)
	_cart.position.x = CART_HOME_X
	if walking_alone:
		_donkey.flip_h = facing
		return
	_donkey.position = Vector2(_harness_x(CART_HOME_X, false), RIG_BASE)
	_donkey.play("stand")


## Now and then the stork blinks, bobs its head or turns to look back over its shoulder, then settles again.
func _idle_stork(delta: float) -> void:
	if not _stork.visible or _stork.has_meta("bobbing"):
		return
	if _stork_poses.is_empty():
		for pose in ["nest", "nest_look", "nest_blink", "nest_nod"]:
			var path := "res://assets/sprites/animals/stork/%s.png" % pose
			if ResourceLoader.exists(path):
				_stork_poses[pose] = load(path)
	_stork_timer -= delta
	if _stork_timer > 0.0 or _stork_poses.size() < 4:
		return
	if _stork.texture != _stork_poses["nest"]:
		_stork.texture = _stork_poses["nest"]
		_stork_timer = randf_range(3.0, 8.0)
		return
	var pick := randf()
	if pick < 0.45:
		_stork.texture = _stork_poses["nest_blink"]
		_stork_timer = 0.15
	elif pick < 0.75:
		_stork.texture = _stork_poses["nest_nod"]
		_stork_timer = 0.5
	else:
		_stork.texture = _stork_poses["nest_look"]
		_stork_timer = randf_range(2.0, 4.0)


## At nightfall, once the cart is home, the donkey is unhitched and walks down the road to the barn in the pasture,
## turns in at its door and goes inside; at daybreak it comes out, walks back and is put in the shafts again.
func _stable_donkey() -> void:
	var night := Game.is_night()
	var with_cart: bool = Game.cart["away"] or _cart_returning or _riding
	if _donkey_night == "" and night and not with_cart:
		# A farm opened at night finds the donkey already stabled rather than watching it walk the whole way.
		if _donkey_first_look:
			_donkey_night = "barn"
			_donkey.visible = false
			_harness.visible = false
		else:
			_donkey_walk_to_barn()
	elif _donkey_night == "barn" and not night:
		_donkey_walk_home()
	_donkey_first_look = false


func _donkey_walk_to_barn() -> void:
	_donkey_night = "out"
	_harness.visible = false
	_dust(Vector2(_donkey.position.x, RIG_BASE), 6)
	var door := Vector2((Pasture.BARN_LEFT + Pasture.BARN_RIGHT) / 2.0, 252.0)
	_donkey.flip_h = false
	_donkey_stroll(true)
	_donkey_tween = create_tween()
	_donkey_tween.tween_property(_donkey, "position:x", door.x, absf(door.x - _donkey.position.x) / 26.0)
	_donkey_tween.tween_property(_donkey, "position:y", door.y, (RIG_BASE - door.y) / 14.0)
	_donkey_tween.tween_callback(_donkey.play.bind("stand"))
	_donkey_tween.tween_property(_donkey, "modulate:a", 0.0, 0.8)
	_donkey_tween.tween_callback(func():
		_donkey_night = "barn"
		_donkey.visible = false)


func _donkey_walk_home() -> void:
	_donkey_night = "back"
	var home := Vector2(_harness_x(CART_HOME_X, false), RIG_BASE)
	_donkey.position = Vector2((Pasture.BARN_LEFT + Pasture.BARN_RIGHT) / 2.0, 252.0)
	_donkey.modulate.a = 0.0
	_donkey.visible = true
	_donkey.flip_h = true
	_donkey.play("stand")
	_donkey_tween = create_tween()
	_donkey_tween.tween_property(_donkey, "modulate:a", 1.0, 0.8)
	_donkey_tween.tween_callback(_donkey_stroll.bind(true))
	_donkey_tween.tween_property(_donkey, "position:y", float(RIG_BASE), (RIG_BASE - 252.0) / 14.0)
	_donkey_tween.tween_property(_donkey, "position:x", home.x, absf(_donkey.position.x - home.x) / 26.0)
	# Back at the cart it turns round to face the road, and the harness goes on again.
	_donkey_tween.tween_callback(func():
		_donkey_stroll(false)
		_donkey_night = ""
		_harness.visible = true
		if not Game.cart["away"] and not _cart_returning:
			_park_rig())


## A two-wheeled cart with no donkey between its shafts tips forward until the shaft ends rest on the ground, about
## its axle, and comes level again when the donkey is put back in.
func _tip_cart(delta: float) -> void:
	var axle := _wheel.position
	# The four-wheeled wagon stands on its own wheels, so only the two-wheeled carts tip.
	var target := _rest_angle(44.0 + _cart_grow.x) if _donkey_night != "" and not _front_wheel.visible else 0.0
	_cart_tilt = move_toward(_cart_tilt, target, delta * 0.25)
	for sprite in [_cart, _cart_back]:
		sprite.rotation = _cart_tilt
		sprite.offset = axle.rotated(-_cart_tilt) - axle
	_cart_load.rotation = _cart_tilt
	_cart_load.position = _cart.position + axle - axle.rotated(_cart_tilt)
	if not _stone_parts.is_empty():
		var rest: Vector2 = _stone_parts[0].get_meta("rest")
		_tip_parts(_stone_parts, rest + Vector2(15, 23), _rest_angle(44.0) if _stone_night != "" else 0.0, delta)


## How far a cart tips forward before its shaft ends touch the ground: the shaft ends are reach pixels ahead of the
## axle and 4 above it, and the ground is 12 below the axle, where the wheel stands.
func _rest_angle(reach: float) -> float:
	var tip := Vector2(reach, -4.0)
	return asin(12.0 / tip.length()) - tip.angle()


## Tips a cart made of separate pictures about its axle, easing towards the angle; each part turns about the axle from
## where it rests.
func _tip_parts(parts: Array, axle: Vector2, target: float, delta: float) -> void:
	var angle := move_toward(float(parts[0].rotation), target, delta * 0.25)
	for part in parts:
		var rest: Vector2 = part.get_meta("rest")
		part.rotation = angle
		part.position = axle + (rest - axle).rotated(angle)


## Walks the donkey at an amble on its own, its legs slowed to match, or puts it back to the cart's pace.
func _donkey_stroll(walking: bool) -> void:
	_donkey.play("walk" if walking else "stand")
	var pace := Walker.natural_pace(_donkey.sprite_frames, "walk")
	_donkey.speed_scale = 26.0 / pace if walking and pace > 0.0 else 1.0


## Where the donkey stands so the shaft tips reach its harness: going out the shafts point right, coming home the cart is turned round.
func _harness_x(cart_x: float, homeward: bool) -> float:
	return cart_x + 2.0 if homeward else cart_x + 58.0 + _cart_grow.x


## Each bigger cart is its own picture: stakes, then a wicker rail, then a four-wheeled wagon, each a little longer and
## taller than the last; the wheel and shafts stay at the same height.
func _size_cart() -> void:
	var level := clampi(int(Game.levels.get("cart_capacity", 0)), 0, CART_GROW.size() - 1)
	_cart_grow = CART_GROW[level]
	var used := load("res://assets/sprites/farm/cart.png").get_image().get_used_rect() as Rect2i
	for pair in [[_cart_back, "cart_back"], [_cart, "cart_front"]]:
		var s: Sprite2D = pair[0]
		var path := "res://assets/sprites/farm/%s_%d.png" % [pair[1], level]
		s.texture = load(path if level > 0 and ResourceLoader.exists(path) else "res://assets/sprites/farm/%s.png" % pair[1])
		s.region_rect = Rect2(used.position, used.size + _cart_grow)
		s.position.y = RIG_BASE - s.region_rect.size.y
	_front_wheel.visible = level >= 3
	_face_rig(_cart.flip_h)
	_harness.queue_redraw()
	if not Game.cart["away"] and not _cart_returning:
		_park_rig()


## Each improvement to the road is worked along its whole length: first the paving, then a kerb of raised stones along
## its far edge with milestones beside it, then a gravel footpath along the verge. While one is under way it reaches as
## far as the work has come.
func _pave_road() -> void:
	var level := int(Game.levels.get("cart_speed", 0))
	var front := 2440.0
	if Game.projects.has("cart_speed"):
		var done := clampf(1.0 - float(Game.projects["cart_speed"]) / maxf(1.0, Game.upgrade_seconds("cart_speed")), 0.0, 1.0)
		front = roundf(lerpf(-40.0, 2440.0, done))
	var reach := func(stage: int) -> float:
		if level > stage:
			return 2440.0
		return front if level == stage and Game.projects.has("cart_speed") else -40.0
	_paving_front = front
	var paved: float = reach.call(0)
	_paved_reach = paved
	_road.visible = paved > -40.0
	# The paving's own far kerb is only shown once the kerbstones have been laid.
	_road.region_rect = Rect2(0, 3, paved + 40.0, 17)
	_road.position = Vector2(-40.0, 273.0)
	_kerb.visible = float(reach.call(1)) > -40.0
	_kerb.region_rect = Rect2(0, 0, float(reach.call(1)) + 40.0, 3)
	_kerb.position = Vector2(-40.0, 270.0)
	_milestone_reach = reach.call(1)
	_footpath_reach = reach.call(2)
	_road_works.queue_redraw()


## Ahead of the paving, a strip of levelled gravel waits for the stones, with a heap of them at the working edge; the
## milestones stand at the road's far side as far as they have been set.
func _draw_road_works() -> void:
	# The footpath: a strip of pale packed gravel along the verge, flecked with darker stones.
	if _footpath_reach > -40.0:
		_road_works.draw_rect(Rect2(-40, 266, _footpath_reach + 40.0, 4), Color8(196, 178, 140))
		_road_works.draw_rect(Rect2(-40, 266, _footpath_reach + 40.0, 1), Color8(214, 198, 160))
		for x in range(-40, int(_footpath_reach), 5):
			_road_works.draw_rect(Rect2(x + (x * 7) % 3, 267 + (x * 13) % 3, 1, 1), Color8(150, 134, 108))
	for at in MILESTONES:
		if at <= _milestone_reach:
			_draw_milestone(float(at))
	if not Game.projects.has("cart_speed") or int(Game.levels.get("cart_speed", 0)) > 0:
		return
	var x := _paving_front
	var gravel := Color8(150, 138, 118)
	for i in 40:
		var shade := gravel.darkened(0.08 * ((i * 7) % 3))
		_road_works.draw_rect(Rect2(x + i, 272, 1, 18), shade)
	for k in 14:
		var at := Vector2(x + (k * 13) % 38, 273 + (k * 5) % 15)
		_road_works.draw_rect(Rect2(at, Vector2(1, 1)), gravel.darkened(0.25))
	var stone := Color8(128, 122, 116)
	for row in 4:
		var w := 8 - row * 2
		_road_works.draw_rect(Rect2(x + 2 + row, 270 - row * 2, w, 2), stone.lightened(0.08 * row))
		_road_works.draw_rect(Rect2(x + 2 + row, 271 - row * 2, w, 1), stone.darkened(0.2))
	for k in 5:
		_road_works.draw_rect(Rect2(x + 12 + k * 5, 278 + (k % 2) * 5, 3, 2), stone)


## A Roman milestone: a short round column on a square foot, lit on its left, with its lettering as a dark band.
func _draw_milestone(x: float) -> void:
	var stone := Color8(196, 188, 170)
	var shade := Color8(150, 142, 128)
	_road_works.draw_rect(Rect2(x - 3, 266, 7, 3), shade)
	_road_works.draw_rect(Rect2(x - 3, 266, 7, 1), stone)
	for row in 12:
		var y := 254 + row
		_road_works.draw_rect(Rect2(x - 2, y, 2, 1), stone.lightened(0.08) if row < 2 else stone)
		_road_works.draw_rect(Rect2(x, y, 2, 1), shade)
		_road_works.draw_rect(Rect2(x + 2, y, 1, 1), shade.darkened(0.2))
	_road_works.draw_rect(Rect2(x - 2, 253, 4, 1), stone.lightened(0.12))
	_road_works.draw_rect(Rect2(x - 2, 258, 4, 1), shade.darkened(0.35))
	_road_works.draw_rect(Rect2(x - 1, 260, 3, 1), shade.darkened(0.3))
	_road_works.draw_rect(Rect2(x - 4, 269, 9, 1), Color(0.18, 0.14, 0.08, 0.3))


## A donkey cart heaped with paving stones stands on the new road just behind the work and moves up as the paving
## advances, so the builders always have stones to hand.
func _update_road_cart(delta: float) -> void:
	var paving := Game.projects.has("cart_speed")
	if not paving:
		if _stone_cart.visible:
			_stone_cart.visible = false
		return
	_pave_road()
	var target := maxf(0.0, _paving_front - 96.0)
	if not _stone_cart.visible:
		_stone_cart.visible = true
		_stone_x = target
	var before := _stone_x
	_stable_stone_donkey()
	# It waits until the work has moved on a few steps, then walks up to it at an amble, rather than inching along; only
	# if the work has got well ahead does it hurry.
	if _stone_night != "":
		pass
	elif target - _stone_x > 8.0 or (_stone_donkey.animation == "walk" and target > _stone_x):
		var pace := 14.0 if target - _stone_x < 60.0 else 26.0
		_stone_x = move_toward(_stone_x, target, pace * delta)
		_stone_donkey.play("walk")
		_stone_donkey.speed_scale = pace / maxf(1.0, Walker.natural_pace(_stone_donkey.sprite_frames, "walk"))
	else:
		_stone_donkey.play("stand")
		_stone_donkey.speed_scale = 1.0
	_stone_wheel.rotation += (_stone_x - before) / 11.0
	_stone_cart.position = Vector2(roundf(_stone_x), 0)


## The paving cart's donkey keeps the same hours as the trader's: unhitched at dusk and walked to the barn, and back to
## its cart at daybreak.
func _stable_stone_donkey() -> void:
	var night: bool = Game.is_night()
	var barn := Vector2((Pasture.BARN_LEFT + Pasture.BARN_RIGHT) / 2.0 - _stone_cart.position.x, 252.0)
	var home := Vector2(58, RIG_BASE)
	if _stone_night == "" and night:
		_stone_night = "out"
		_stone_donkey.flip_h = false
		_stone_donkey.play("walk")
		var walk := create_tween()
		walk.tween_property(_stone_donkey, "position:x", barn.x, absf(barn.x - home.x) / 26.0)
		walk.tween_property(_stone_donkey, "position:y", barn.y, (RIG_BASE - barn.y) / 14.0)
		walk.tween_property(_stone_donkey, "modulate:a", 0.0, 0.8)
		walk.tween_callback(func(): _stone_night = "barn")
	elif _stone_night == "barn" and not night:
		_stone_night = "back"
		_stone_donkey.position = barn
		_stone_donkey.flip_h = true
		_stone_donkey.play("walk")
		var walk := create_tween()
		walk.tween_property(_stone_donkey, "modulate:a", 1.0, 0.8)
		walk.tween_property(_stone_donkey, "position:y", float(RIG_BASE), (RIG_BASE - barn.y) / 14.0)
		walk.tween_property(_stone_donkey, "position:x", home.x, absf(barn.x - home.x) / 26.0)
		walk.tween_callback(func():
			_stone_donkey.flip_h = false
			_stone_donkey.play("stand")
			_stone_night = "")


## A paving cart in three layers like the trader's: the back rim, the heap of stones, and the front wall with its
## wheel, so the stones sit down inside the bed.
func _build_stone_cart() -> void:
	_stone_cart = Node2D.new()
	_stone_cart.visible = false
	world.add_child(_stone_cart)
	var used := Rect2(load("res://assets/sprites/farm/cart.png").get_image().get_used_rect())
	var top := RIG_BASE - used.size.y
	for part in ["cart_back", "heap", "cart_front"]:
		if part == "heap":
			var heap := Node2D.new()
			heap.position = Vector2(0, top)
			heap.set_meta("rest", heap.position)
			heap.draw.connect(_draw_stone_heap.bind(heap))
			_stone_cart.add_child(heap)
			_stone_parts.append(heap)
			continue
		var s := Sprite2D.new()
		s.texture = load("res://assets/sprites/farm/%s.png" % part)
		s.centered = false
		s.region_enabled = true
		s.region_rect = used
		s.position = Vector2(0, top)
		s.set_meta("rest", s.position)
		_stone_cart.add_child(s)
		_stone_parts.append(s)
		if part == "cart_front":
			_stone_wheel = Sprite2D.new()
			_stone_wheel.texture = load("res://assets/sprites/farm/cart_wheel.png")
			_stone_wheel.position = Vector2(15, 23)
			s.add_child(_stone_wheel)
	_stone_donkey = AnimatedSprite2D.new()
	_stone_donkey.sprite_frames = _donkey_frames()
	_stone_donkey.centered = false
	_stone_donkey.offset = Vector2(-32, -_feet_line(load("res://assets/sprites/donkey/walk_east/frame_00.png")))
	_stone_donkey.position = Vector2(58, RIG_BASE)
	_stone_donkey.play("stand")
	_stone_cart.add_child(_stone_donkey)


## A mound of flat grey paving stones piled in the bed, highest in the middle; the front wall hides its bottom.
func _draw_stone_heap(heap: Node2D) -> void:
	var tones := [Color8(122, 116, 110), Color8(136, 129, 120), Color8(114, 109, 106), Color8(146, 138, 128)]
	var k := 0
	for layer in 3:
		var y := 5 - layer * 2
		var x := 5 + layer * 3
		while x < 33 - layer * 3:
			var w := 6 - (k % 3)
			var c: Color = tones[(k * 3 + layer) % tones.size()]
			heap.draw_rect(Rect2(x, y, w, 3), c)
			heap.draw_rect(Rect2(x, y, w, 1), c.lightened(0.18))
			heap.draw_rect(Rect2(x + w - 1, y, 1, 3), c.darkened(0.25))
			x += w + (1 if k % 4 == 0 else 0)
			k += 1


## Where builders work on a farm improvement: at the storehouse, along the water channel, or on the next stretch of road.
func _project_site(id: String) -> Rect2:
	match id:
		"storage":
			return Rect2(_storehouse.position, _storehouse.region_rect.size)
		"channels":
			return Rect2(_channels.front() - 30.0, 236, 50, 31)
	return Rect2(_paving_front - 30.0, 250, 50, 31)


func _on_upgrade_started(id: String) -> void:
	Sfx.play("hammer")
	var site := _project_site(id)
	_dust(Vector2(site.position.x + site.size.x / 2.0, site.end.y), 14)
	hud.toast(tr("The builders have started work"))
	if id == "storage":
		_store_scaffold.visible = true
		_store_scaffold.rise()


## Each enlargement shows on the storehouse: a lean-to with jars, then crates and shutters, a loft with a hoist, and a
## second bay with great storage jars. The house itself stays on its spot in every picture.
func _dress_storehouse() -> void:
	var level := int(Game.levels.get("storage", 0))
	var path := "res://assets/sprites/farm/storehouse_%d.png" % level
	if level < 1 or not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var used := tex.get_image().get_used_rect()
	_storehouse.texture = tex
	_storehouse.region_rect = used
	_storehouse.position = Vector2(HOME + 198 - (STORE_HOUSE_AT.x - used.position.x), 236 - (STORE_HOUSE_AT.y - used.position.y))
	if _store_scaffold:
		_store_scaffold.rect = Rect2(_storehouse.position, _storehouse.region_rect.size)


func _on_upgrade_bought(id: String) -> void:
	if id == "storage":
		_dress_storehouse()
		_dust(_storehouse.position + Vector2(_storehouse.region_rect.size.x / 2.0, _storehouse.region_rect.size.y), 20)
	if id == "storage" and _store_scaffold.visible:
		_store_scaffold.sink().tween_callback(func(): _store_scaffold.visible = Game.projects.has("storage"))
	if id in Game.BUILT_UPGRADES:
		Sfx.play("villa_complete")
		hud.toast(tr("The work is finished"))
	if id == "cart_speed":
		_pave_road()
		_dust(Vector2(cam_x + _view_size().x / 2.0, 280), 24)
	if id == "cart_capacity":
		_size_cart()
		_dust(Vector2(_cart.position.x + 30, RIG_BASE), 14)


func _face_rig(homeward: bool) -> void:
	_cart.flip_h = homeward
	_donkey.flip_h = homeward
	_wheel.position = Vector2(45.0 + _cart_grow.x if homeward else 15.0, 23.0 + _cart_grow.y)
	var front := 21.0 + _cart_grow.x
	_front_wheel.position = Vector2(60.0 + _cart_grow.x - front if homeward else front, 23.0 + _cart_grow.y)
	_update_cart_load()


## The near shaft runs from the front of the cart along the donkey's side to the collar at its shoulder,
## with a strap over its back holding the shaft up; the painted shafts on the cart are the far side's.
func _draw_harness() -> void:
	var home := _cart.flip_h
	var dir := -1.0 if home else 1.0
	var a := Vector2(_cart.position.x + (26.0 if home else 34.0 + _cart_grow.x), _cart.position.y + 17.0 + _cart_grow.y).round()
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
	# As many goods as fit along the bed, raised to show above a wicker rail on the carts that have one.
	paths = paths.slice(0, 4 + _cart_grow.x / 12)
	var rail := 5.0 if int(Game.levels.get("cart_capacity", 0)) >= 2 else 0.0
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
			icon.position = Vector2(x if not _cart.flip_h else 60.0 + _cart_grow.x - x - 16.0, 9 - bottom - rail)


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
	# Standing, the donkey breathes, flicks an ear and swishes its tail, slowly, rather than freezing.
	f.add_animation("stand")
	f.set_animation_speed("stand", 4.0)
	for i in 9:
		f.add_frame("stand", load("res://assets/sprites/donkey/idle_east/frame_%02d.png" % i))
	f.add_animation("bray")
	f.set_animation_speed("bray", 8.0)
	f.set_animation_loop("bray", false)
	for i in 9:
		f.add_frame("bray", load("res://assets/sprites/donkey/bray_east/frame_%02d.png" % i))
	return f


func _feet_line(tex: Texture2D) -> int:
	var used := tex.get_image().get_used_rect()
	return used.position.y + used.size.y


func _villa_texture() -> Texture2D:
	var stages := Game.villa_stages()
	var stage: Dictionary = stages[clampi(Game.villa_stage - 1, 0, stages.size() - 1)]
	var path := "res://assets/sprites/villa/%s.png" % stage.get("sprite", "stage1")
	return load(path) if ResourceLoader.exists(path) else load("res://assets/sprites/villa/stage2.png")


func _villa_rect() -> Rect2:
	return Rect2(_villa.position, _villa.region_rect.size)


## The farmhouse's hover outline, and while it is being restored a progress bar over its roof like the other buildings'.
func _draw_villa_overlay() -> void:
	var r := _villa_rect()
	if _villa_hovered:
		UiKit.outline(_villa_outline, r, Color(1, 0.96, 0.85, 0.7))
	if not Game.villa_build["active"]:
		return
	var total := float(Game.villa_stages()[mini(Game.villa_stage, Game.villa_stages().size() - 1)].get("build_seconds", 1))
	var fill := clampf(1.0 - float(Game.villa_build["time_left"]) / maxf(total, 1.0), 0.0, 1.0)
	var bar := Rect2(roundf(r.position.x + r.size.x / 2.0 - 16.0), r.position.y - 6, 32, 3)
	_villa_outline.draw_rect(bar, Color(0.2, 0.14, 0.12, 0.8))
	_villa_outline.draw_rect(Rect2(bar.position + Vector2.ONE, Vector2(roundf(30.0 * fill), 1)), Color(0.98, 0.84, 0.4))


## Where the farmhouse's ladders stand, in pixels from its left edge; they are set as shares of its width, since each
## stage of the farmhouse is drawn a different size.
func _villa_ladders() -> Array:
	var width := _villa_rect().size.x
	return Balance.get_value("villa.ladders", []).map(func(share): return roundf(width * float(share)))


func _place_villa() -> void:
	var tex := _villa_texture()
	_villa.texture = tex
	var used := tex.get_image().get_used_rect()
	_villa.region_rect = used
	_villa.position = Vector2(round(VILLA_BASE.x - used.size.x / 2.0), VILLA_BASE.y - used.size.y + 1)
	_villa_shadow.texture = Lighting.ellipse_texture(used.size.x + 12, 7, SHADOW)
	_villa_shadow.position = Vector2(_villa.position.x - 6, VILLA_BASE.y - 5)
	_make_windows(tex, used)
	_hang_wreath(tex, used)
	if _villa_scaffold:
		_villa_scaffold.rect = _villa_rect()
		_villa_scaffold.ladders = _villa_ladders()
		_villa_scaffold.visible = Game.villa_build["active"] or _villa_scaffold.share > 0.0 and _villa_scaffold.visible
		_villa_scaffold.queue_redraw()
	# Storks only nest on a well-kept roof, so they arrive with the peristyle garden.
	_stork.visible = _stork.texture != null and Game.villa_stage >= 5 and not Game.villa_build["active"]
	if _stork.texture:
		_stork.position = Vector2(_villa.position.x + used.size.x * 0.68, _villa.position.y - _stork.texture.get_height() + 12)


## Once the Triumph is earned, a golden laurel wreath hangs over the villa's front door, found as the top of the
## door's dark wood in the middle of the house.
func _hang_wreath(tex: Texture2D, used: Rect2i) -> void:
	if _wreath == null:
		_wreath = _add_texture(load("res://assets/sprites/decorations/laurel_wreath.png"), Vector2.ZERO)
		world.move_child(_wreath, _villa.get_index() + 1)
		Game.achievement_unlocked.connect(func(a): if a["id"] == "triumph": _place_villa())
	_wreath.visible = Game.journal.achievements.has("triumph") and Game.villa_stage > 1
	if not _wreath.visible:
		return
	var img := tex.get_image()
	var mid := used.position.x + used.size.x / 2
	var door := func(y: int) -> bool:
		var c := img.get_pixel(mid, y)
		return c.a > 0.5 and c.v < 0.42 and c.s > 0.3
	var top := used.end.y - 1
	while top > used.position.y and not door.call(top):
		top -= 1
	while top > used.position.y and door.call(top - 1):
		top -= 1
	var size := _wreath.texture.get_size()
	_wreath.position = _villa.position + Vector2(mid - used.position.x, top - used.position.y) - Vector2(roundf(size.x / 2.0), size.y + 1)


## Finds the villa's windows (its glass-blue pixels, grouped into panes, and panes close together into one window) and
## gives each window a lamp inside that lights all its panes and spills out onto the wall and the ground.
func _make_windows(tex: Texture2D, used: Rect2i) -> void:
	for w in _windows:
		for pane in w["panes"]:
			pane.queue_free()
		w["lamp"].queue_free()
	_windows = []
	_windows_night = -1
	# The ruin has no glass, only dark holes, so it stays dark.
	if Game.villa_stage <= 1:
		return
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var glass := {}
	var boxes: Array[Rect2i] = []
	var panes: Array[Sprite2D] = []
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.b > c.r + 0.08 and c.b > c.g + 0.02:
				glass[Vector2i(x, y)] = true
	while not glass.is_empty():
		var pane: Array = [glass.keys()[0]]
		glass.erase(pane[0])
		var k := 0
		while k < pane.size():
			var p: Vector2i = pane[k]
			k += 1
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				if glass.has(p + d):
					glass.erase(p + d)
					pane.append(p + d)
		if pane.size() < 4:
			continue
		var box := Rect2i(pane[0], Vector2i.ONE)
		for p in pane:
			box = box.expand(p).expand(p + Vector2i.ONE)
		var light := Image.create(box.size.x, box.size.y, false, Image.FORMAT_RGBA8)
		for p in pane:
			light.set_pixelv(p - box.position, Color(1.0, 0.8, 0.42, 0.95))
		var sprite := _add_texture(ImageTexture.create_from_image(light), _villa.position + Vector2(box.position - used.position), _glow_layer)
		sprite.modulate.a = 0.0
		boxes.append(box)
		panes.append(sprite)
	# Panes a few pixels apart, split only by glazing bars or a frame, belong to the same window.
	var group := range(boxes.size())
	var changed := true
	while changed:
		changed = false
		for i in boxes.size():
			for j in boxes.size():
				if group[i] != group[j] and boxes[i].grow(3).intersects(boxes[j]):
					var keep := mini(group[i], group[j])
					var drop := maxi(group[i], group[j])
					for k in group.size():
						if group[k] == drop:
							group[k] = keep
					changed = true
	for g in range(boxes.size()):
		var members := range(boxes.size()).filter(func(k): return group[k] == g)
		if members.is_empty():
			continue
		var outline := boxes[members[0]]
		for k in members:
			outline = outline.merge(boxes[k])
		var lamp := Lamp.new()
		lamp.position = _villa.position + Vector2(outline.position - used.position) + Vector2(outline.size) / 2.0 + Vector2(0, 3)
		lamp.radius = clampf(outline.size.x * 2.2, 18.0, 34.0)
		lamp.power = 0.9
		world.add_child(lamp)
		_windows.append({"panes": members.map(func(k): return panes[k]), "lamp": lamp, "phase": randf() * TAU, "speed": randf_range(0.8, 1.3)})


## Each evening some windows are lit, one after another as dusk falls, and go out at different hours; a few light again before dawn.
## A lit window flickers gently, like a candle or an oil lamp.
func _light_windows(night: float) -> void:
	if _windows.is_empty():
		return
	if _windows_night != Game.calendar.day:
		_windows_night = Game.calendar.day
		var rng := RandomNumberGenerator.new()
		rng.seed = Game.calendar.day * 7919 + _windows.size()
		for w in _windows:
			w["lit"] = rng.randf() < 0.75
			w["on"] = rng.randf_range(18.6, 20.2)
			w["off"] = rng.randf_range(21.5, 25.5)
			w["dawn"] = rng.randf() < 0.3
	var hour := Game.day_time
	var t := Time.get_ticks_msec() / 1000.0
	for w in _windows:
		var since := fposmod(hour - 12.0, 24.0)
		var evening := smoothstep(float(w["on"]) - 12.0, float(w["on"]) - 11.7, since) * (1.0 - smoothstep(float(w["off"]) - 12.0, float(w["off"]) - 11.8, since))
		var morning := (smoothstep(5.0, 5.3, hour) * (1.0 - smoothstep(6.8, 7.2, hour))) if w["dawn"] else 0.0
		var on := maxf(evening if w["lit"] else 0.0, morning)
		var flicker := 1.0 if Settings.reduced_motion else 0.84 + 0.09 * sin(t * 5.1 * float(w["speed"]) + float(w["phase"])) + 0.07 * sin(t * 11.7 * float(w["speed"]) + float(w["phase"]) * 1.7)
		var glow := clampf(on * flicker * maxf(night, 0.35), 0.0, 1.0)
		for pane in w["panes"]:
			pane.modulate.a = glow
		w["lamp"].shine(glow * night)


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


## The cat keeps to the open ground in front of the villa, where no crops stand in front of it; the dog roams the farm.
func _spawn_pets() -> void:
	if cat:
		cat.queue_free()
	if dog:
		dog.queue_free()
	cat = Cat.new()
	cat.coat = String(Game.pets.get("cat", {}).get("coat", ""))
	cat.dir = Coats.breed_dir("cat", String(Game.pets.get("cat", {}).get("breed", "")))
	cat.min_x = HOME + 385
	cat.max_x = HOME + 452
	cat.position = Vector2(HOME + 420, 246)
	cat.petted.connect(func(): _hearts(cat.position + Vector2(0, -18)); Sfx.play("cat", -4.0, 0.08); Game.add_stat("pets", 1))
	world.add_child(cat)
	dog = Dog.new()
	dog.coat = String(Game.pets.get("dog", {}).get("coat", ""))
	dog.dir = Coats.breed_dir("dog", String(Game.pets.get("dog", {}).get("breed", "")))
	dog.position = Vector2(HOME + 345, 268)
	dog.min_x = HOME + 10
	dog.max_x = HOME + 456
	dog.petted.connect(_on_dog_petted)
	world.add_child(dog)
	# Both stand behind the cart, which parks on the road in front of them.
	if _cart_load:
		world.move_child(cat, _cart_load.get_index())
		world.move_child(dog, _cart_load.get_index())

