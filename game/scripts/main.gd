class_name Estate
extends Node2D
## Builds the estate from its layers and buildings, pans across it, and turns clicks into farm actions. The road, the
## cart and donkey, the villa, the wild growth and the development tools each live in their own script under estate/.

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
const InteriorView := preload("res://scripts/ui/interior_view.gd")
const Scenery := preload("res://scripts/estate/scenery.gd")
const RoadWorks := preload("res://scripts/estate/road_works.gd")
const CartRig := preload("res://scripts/estate/cart_rig.gd")
const VillaView := preload("res://scripts/estate/villa_view.gd")
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
## Helpers whose carrying animation draws the load itself.
const DRAWN_LOADS := ["miller"]
## How far in front of their feet a helper's hands are while picking; the farmhand stoops to the ground to pick.
const PICK_REACH := {"farmhand": 12.0}
## Where each helper spends their day, in estate pixels.
## Workshops with no door to go into at night: the hives and the open-sided presses and shed.
const OPEN_SIDED := ["beehives", "olive_press", "wine_press", "drying_shed"]
const HELPER_GROUNDS := {
	"farmhand": [490.0, 930.0], "miller": [1130.0, 1400.0], "beekeeper": [150.0, 300.0], "perfumer": [990.0, 1610.0],
	"presser": [360.0, 1900.0], "stablehand": [1940.0, 2380.0], "trader": [1080.0, 1120.0],
}
## Seasons tint the whole scene a little: fresh in spring, golden in autumn, cool and pale in winter.
const SEASON_TINT := {"spring": Color(0.98, 1.02, 0.98), "summer": Color(1.03, 1.0, 0.94), "autumn": Color(1.04, 0.95, 0.86), "winter": Color(0.9, 0.94, 1.02)}

var estate_width := 2400.0
var plot_views: Array = []
var building_views: Array = []
## Goods each helper is on their way to fetch, by helper: the item and the workshop door it goes to.
var _fetches := {}
## The plot each helper is on their way to pick, by helper.
var _picks := {}
var signs: Array = []
var hud: CanvasLayer
var scenery: Scenery
var road: RoadWorks
var rig: CartRig
var villa: VillaView
var market: CanvasLayer
var interior: CanvasLayer
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
## Holds the far mountains and fields, at screen resolution outside the estate's picture.
var _far_view: Node2D
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
## Where the paving has reached while a stretch is being laid.
var _paving_front := -40.0
## How far the paving itself reaches along the road.
var _paved_reach := -40.0
## The water channel along the front of the home farm.
var _channels: Node2D
var _stone_donkey: AnimatedSprite2D
## Scaffolding stood in front of the farmhouse while it is being restored.
var _villa_scaffold: Node2D
var _villa_bar_up := false
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
## The goods heaped in the cart, drawn behind its side boards so they sit inside it.
var _cart_load: Node2D
var _cart_x := 0.0
## The near shaft and the harness straps, drawn over the donkey so the cart is visibly hitched to it.
var _harness: Node2D
## Where the cart and donkey stood when the harness was last drawn, and which way the cart faced.
var _harness_drawn := Vector4.INF
var _cart_returning := false
## What the cart is bringing home, told when it parks, or when it turns round if it is sent off again first.
var _coins_coming := 0
var _donkey: AnimatedSprite2D
## Where the donkey is on its own between dusk and dawn: "" while it is hitched to the cart, "out" while it walks to
## the barn, "barn" for the night, and "back" while it comes home in the morning.
var _donkey_night := ""
var _donkey_tween: Tween
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
var _hammer_timer := 0.0
var _camera: Camera2D
var _sky_layer: CanvasLayer
var _helpers := {}
## Builders at work, by the site they are working on.
var _builders := {}
var _traveller_timer := 40.0
var _dog_dig_check := 5.0
var _follow_timer := 0.0
## Painted scenery that is hidden in the transparent desktop strip, so only the farm floats over the desktop.
var _scenery: Array = []
var _click_area_timer := 0.0
var _strip_bars: Array[Rect2] = []
## The spot chosen with the keyboard or a gamepad, or Vector2.INF when the mouse is in use.
var _pad_point := Vector2.INF
## True once the hover has been cleared for a pointer resting on the interface, so it is cleared only once.
var _hover_cleared := false
var _drag_from := Vector2.ZERO
var _drag_start_cam := 0.0
var _dragging := false
var _pressed := false
var _pan_tween: Tween
var _last_view_width := 480.0
var _centre := HOME + 240.0


func _ready() -> void:
	# The tests and bots build their own estate, so the one the game opens on is put away.
	if Dev.checking() and not Dev.running:
		process_mode = Node.PROCESS_MODE_DISABLED
		queue_free.call_deferred()
		return
	Dev.m = self
	scenery = _part(Scenery) as Scenery
	road = _part(RoadWorks) as RoadWorks
	rig = _part(CartRig) as CartRig
	villa = _part(VillaView) as VillaView
	estate_width = float(Data.get_value("estate.width", 2400))
	if Dev.state() != "":
		Dev.load_demo_state()
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
	# The far mountains and fields are drawn at screen resolution behind the estate, like the sky, so their slower
	# parallax pans smoothly instead of sliding with the estate's picture and stepping back a pixel at a time.
	var far_layer := CanvasLayer.new()
	far_layer.layer = -1
	add_child(far_layer)
	_far_view = Node2D.new()
	far_layer.add_child(_far_view)
	_mountains = _add_texture(load(BG + "layer_mountains.png"), Vector2.ZERO, _far_view)
	_mountains_far = _add_texture(_mountains.texture, Vector2.ZERO, _far_view)
	_mountains_far.flip_h = true
	_land = _add_texture(load(BG + "layer_land.png"), Vector2.ZERO, _far_view)
	# Wide views run past the painting's end. The mountains carry on mirrored, which joins their ridge smoothly, but the
	# hills repeat unmirrored: mirrored they show a hill and its reflection, and repeated the cypresses at the
	# painting's left edge stand over the join.
	_land_far = _add_texture(_land.texture, Vector2.ZERO, _far_view)
	_scenery.append_array([_mountains, _land, _mountains_far, _land_far])

	var pine := _add_trimmed(load("res://assets/sprites/trees/umbrella_pine_1.png"), Vector2(HOME - 60, 0), true, 240)
	_sway(pine)
	_scenery.append(pine)
	_scenery.append(_add_texture(Lighting.ellipse_texture(64, 7, SHADOW), Vector2(pine.position.x + pine.region_rect.size.x / 2 - 32, 236)))
	_villa_shadow = _add_texture(null, Vector2.ZERO)
	_villa = _add_trimmed(villa.villa_texture(), Vector2.ZERO)
	_villa_scaffold = Scaffold.new()
	_villa_scaffold.storeys = 2
	_villa_scaffold.visible = false
	world.add_child(_villa_scaffold)
	_stork = _add_texture(load("res://assets/sprites/animals/stork/nest.png") if ResourceLoader.exists("res://assets/sprites/animals/stork/nest.png") else null, Vector2.ZERO)
	_villa_outline = Node2D.new()
	_villa_outline.draw.connect(villa.draw_villa_overlay)
	world.add_child(_villa_outline)
	villa.place_villa()
	_add_texture(Lighting.ellipse_texture(70, 7, SHADOW), Vector2(HOME + 194, 230))
	_storehouse = _add_trimmed(load("res://assets/sprites/farm/storehouse.png"), Vector2(HOME + 198, 0), true, 236)
	_dress_storehouse()
	_build_buildings()
	scenery.scatter_meadow.call_deferred()
	scenery.flowers_by_hives.call_deferred()
	scenery.root_in_ground.call_deferred(villa.villa_rect().grow_individual(-12, 0, -12, 0), 851, _villa)
	scenery.root_in_ground.call_deferred(Rect2(_storehouse.position, _storehouse.region_rect.size), 678, _storehouse)
	scenery.sync_overgrowth.call_deferred()
	var decor := DecorView.new()
	decor.glow_layer = _glow_layer
	world.add_child(decor)
	_add_texture(load(BG + "ground.png"), Vector2(-40, 0))
	_road = _add_texture(load(BG + "road_paved.png"), Vector2(-40, 270))
	_road.region_enabled = true
	_kerb = _add_texture(_road.texture, Vector2(-40, 270))
	_kerb.region_enabled = true
	_road_works = Node2D.new()
	_road_works.draw.connect(road.draw_road_works)
	world.add_child(_road_works)
	road.pave_road()
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
	_donkey.sprite_frames = rig.donkey_frames()
	_donkey.centered = false
	_donkey.offset = Vector2(-32, -Frames.feet_line(load("res://assets/sprites/donkey/walk_east/frame_00.png")))
	_donkey.play("stand")
	world.add_child(_donkey)
	_harness = Node2D.new()
	_harness.draw.connect(rig.draw_harness)
	world.add_child(_harness)
	rig.size_cart()
	Game.upgrade_bought.connect(_on_upgrade_bought)
	Game.upgrade_started.connect(_on_upgrade_started)
	_store_scaffold = Scaffold.new()
	_store_scaffold.rect = Rect2(_storehouse.position, _storehouse.region_rect.size)
	_store_scaffold.visible = Game.projects.has("storage")
	world.add_child(_store_scaffold)
	rig.park_rig()
	road.build_stone_cart()
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
	hud.strip_pan_requested.connect(_step_zone)
	hud.town_requested.connect(go_to_town)
	add_child(hud)
	market = MarketView.new()
	market.left_town.connect(_back_from_market)
	add_child(market)
	interior = InteriorView.new()
	interior.left_house.connect(func(): hud.visible = true)
	add_child(interior)
	market.visibility_changed.connect(_cover)
	interior.visibility_changed.connect(_cover)
	hud.house_requested.connect(go_inside)

	Game.planted.connect(func(i): Audio.play("plant"); _view(i).bounce())
	Game.dug_up.connect(func(i): Audio.play("plant", -4.0); _dust(_view(i).position + Vector2(15, -2), 10))
	# A handler that never touches the scene is a method rather than a lambda, so it is disconnected when the scene is rebuilt.
	Game.unlocked.connect(_on_unlocked)
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
	Game.animal_added.connect(_on_animal_added)
	Game.helper_hired.connect(_on_helper_arrived)
	Game.decoration_bought.connect(_on_decoration_bought)
	Game.pets_changed.connect(_spawn_pets)
	Game.caught_up.connect(_on_caught_up)
	if Game.cart["away"]:
		_cart.position.x = estate_width + 60
		_donkey.position.x = rig.harness_x(_cart.position.x, false)
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
			Dev.open_panel.call_deferred(arg.trim_prefix("--panel="))
	match Dev.get_arg("screen"):
		"town":
			go_to_town.call_deferred()
		"inside":
			(func() -> void:
				hud.visible = false
				interior.enter()).call_deferred()


## The market town and the farmhouse fill the window, so the estate behind them is not drawn while either is open.
func _cover() -> void:
	var shown := not (market.visible or interior.visible)
	_container.visible = shown
	_sky_view.visible = shown
	_far_view.visible = shown


## The donkey sets off down the road with the cart before the market town comes into view.
func _ride_to_market() -> void:
	# The trip counts as over before the cart has driven back into view and parked, so a ride waits until it has.
	if _riding or _cart_returning:
		return
	if Settings.reduced_motion or Windowing.strip or _donkey_night != "":
		go_to_town()
		return
	_riding = true
	var wheels := Audio.play("cart_stone" if _paved_reach > _cart.position.x + 60.0 else "cart_dirt")
	rig.face_rig(false)
	_donkey.play("walk")
	rig.move_rig(_cart.position.x + 220.0, 220.0 / 90.0)
	await get_tree().create_timer(2.1).timeout
	Audio.fade_out(wheels, 1.2)
	_riding = false
	# A player who switched to the strip or went indoors on the way stays at home, and the cart comes back.
	if Windowing.strip or interior.visible:
		_park_cart()
		return
	go_to_town()


func _unhandled_input(event: InputEvent) -> void:
	# The strip shows only the estate, so it waits until the player has left the market or the farmhouse.
	if event.is_action_pressed("toggle_strip") and (market.visible or interior.visible):
		get_viewport().set_input_as_handled()


func _back_from_market() -> void:
	hud.visible = true
	_park_cart()


## Puts the cart back in its place at home, unless it is out on a trip of its own.
func _park_cart() -> void:
	if not Game.cart["away"] and not _cart_returning:
		if _rig_tween:
			_rig_tween.kill()
		rig.park_rig()


func go_inside() -> void:
	if Windowing.strip or market.visible or interior.visible:
		return
	Dissolve.play(self, func() -> void:
		hud.close_windows()
		hud.visible = false
		interior.enter())


func go_to_town() -> void:
	# A ride under way enters the town itself when it gets there.
	if Windowing.strip or _riding or market.visible or interior.visible:
		return
	Dissolve.play(self, func() -> void:
		hud.close_windows()
		hud.visible = false
		market.enter())


func _process(delta: float) -> void:
	# A window takes the pointer's movement before the estate sees it, so the estate's hover text and highlight are
	# cleared here once the pointer moves onto any part of the interface.
	# The estate itself is drawn in a container that also counts as under the pointer, so it is left out.
	var over := get_viewport().gui_get_hovered_control()
	if over != null and over != _container:
		if not _hover_cleared:
			_update_hover(Vector2(-INF, -INF))
			_hover_cleared = true
	else:
		_hover_cleared = false
	# Time skipped all at once finishes the work quietly, so the finish is shown here: scaffold down, word of it.
	if Game.villa_stage != villa.shown_stage and villa.shown_stage > 0:
		_on_villa_finished()
	# The progress bar is redrawn while the builders work, and once more when they finish, so it is taken away.
	if Game.villa_build["active"] or _villa_bar_up:
		_villa_outline.queue_redraw()
	_villa_bar_up = Game.villa_build["active"]
	var night := Lighting.night_amount(Game.day_time)
	var light: Color = Lighting.color_at(Game.day_time) * SEASON_TINT.get(Game.calendar.season_id(), Color.WHITE)
	if Game.calendar.weather in ["cloudy", "rain"]:
		light = light.darkened(0.12)
	_daylight.color = Color(light, 1.0)
	# The far scenery is outside the estate's picture, so the daylight tint is given to it directly.
	_far_view.modulate = _daylight.color
	# At night the far mountains become dark shapes against the starry sky instead of glowing blue.
	var far := Color.WHITE.lerp(Color(0.62, 0.6, 0.7), night)
	_mountains.modulate = far
	_mountains_far.modulate = far
	villa.light_windows(night)
	var windy := 1.6 if Game.calendar.weather in ["rain", "cloudy"] else 1.0
	if PlotView.wind:
		PlotView.wind.set_shader_parameter("strength", 0.0 if Settings.reduced_motion else windy)
	var typing := get_viewport().gui_get_focus_owner() is LineEdit
	var keys := 0.0 if typing else Input.get_axis("pan_left", "pan_right") + Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) * float(absf(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)) > 0.2)
	if keys != 0.0 and not market.visible and not interior.visible:
		_pan_by(keys * PAN_SPEED * delta)
	# Behind the title screen the view drifts slowly along the estate and back.
	if hud.title_open() and not Settings.reduced_motion:
		var edge := maxf(0.0, estate_width - _view_size().x)
		if cam_x >= edge - 1.0 or cam_x <= 1.0:
			_title_drift = -1.0 if cam_x >= edge - 1.0 else 1.0
		_pan_by(_title_drift * 9.0 * delta)
	rig.stable_donkey()
	_idle_stork(delta)
	_cart_shadow.position = Vector2(_cart.position.x - 2, RIG_BASE - 5)
	_cart_load.position = _cart.position
	_cart_back.position = _cart.position
	_cart_back.flip_h = _cart.flip_h
	rig.tip_cart(delta)
	var hitch := Vector4(_cart.position.x, _cart.position.y, _donkey.position.x, float(_cart.flip_h))
	if hitch != _harness_drawn:
		_harness_drawn = hitch
		_harness.queue_redraw()
	# The wheel turns by the distance travelled over its radius, in steps fine enough to look smooth at this size.
	var rolled := _cart.position.x - _cart_x
	_cart_x = _cart.position.x
	if rolled != 0.0:
		_wheel.rotation = snappedf(_wheel.rotation + rolled / 12.0, PI / 24.0)
		_front_wheel.rotation = _wheel.rotation
	if Engine.get_process_frames() % 20 == 0:
		rig.update_cart_load()
	if Windowing.strip and Windowing.transparent:
		# On Windows the outline also clips what the strip draws, so it follows the bars the moment they change.
		var bars: Array[Rect2] = hud.strip_bar_rects()
		if bars != _strip_bars:
			_strip_bars = bars
			_click_area_timer = 0.0
		_click_area_timer -= delta
		if _click_area_timer <= 0.0:
			_click_area_timer = 0.5
			Windowing.set_click_area(_click_area())
	if Game.villa_build["active"] and not Game.is_night():
		_hammer_timer -= delta
		if _hammer_timer <= 0.0:
			_hammer_timer = randf_range(1.2, 2.6)
			Audio.play("hammer", -10.0, 0.15)
			_dust(_villa.position + Vector2(randf_range(10, _villa.region_rect.size.x - 10), _villa.region_rect.size.y - 4), 6)
	for v in building_views:
		if Game.buildings[v.id]["state"] in ["repairing", "upgrading"] and not Game.is_night() and randf() < delta * 0.5:
			Audio.play("hammer", -14.0, 0.2)
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
	road.update_road_cart(delta)
	if Engine.get_process_frames() % 30 == 0:
		_sync_builders()
		scenery.sync_overgrowth()
	_dog_dig_check -= delta
	if _dog_dig_check <= 0.0:
		_dog_dig_check = 5.0
		if Game.dog_timer <= 0.0 and Lighting.night_amount(Game.day_time) < 0.5:
			_dust(dog.position + Vector2(8, -2), 8)
			Audio.play("plant", -6.0)
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
			w.sayings = who
			world.add_child(w)
			_passers.append(w)
	if cat and dog and dog.is_asleep() and cat.is_asleep() and absf(cat.position.x - dog.position.x) < 60.0:
		var view := Rect2(_camera.position, _view_size())
		if view.has_point(cat.position):
			Game.discover("sighting:cat_and_dog")
	var view_rect := Rect2(_camera.position, _view_size())
	if cat and cat.modulate.a > 0.5 and view_rect.has_point(cat.position):
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
		var r := villa.villa_rect()
		var ladders: Array = villa.villa_ladders().map(func(x): return r.position.x + x)
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
	w.rests_at_night = true
	var door := _home_door(id, (w.min_x + w.max_x) / 2.0)
	w.home_x = door.x
	w.door_y = door.y
	var info := Game.helper_info(id)
	w.react_folder = "greet"
	w.display_name = "%s, %s" % [tr(String(info.get("name", ""))), Ui.mid(tr(String(info.get("role", ""))))]
	w.voice = "salve_woman" if id in WOMEN else "salve_man"
	w.sayings = id
	var harvests := info.has("zones") or info.has("crops")
	var runs_workshops := Game.buildings.keys().any(func(b): return Game.building_info(b).get("helper", "") == id)
	if harvests or runs_workshops:
		w.find_work = func() -> float: return _helper_job(id, w)
		w.work_done = func(_x: float) -> String: return String(_fetches[id]["item"]) if _fetches.has(id) else Game.helper_harvest(id, _picked(id))
		w.carry_to = func(item: String, from_x: float) -> float: return float(_fetches[id]["to"]) if _fetches.has(id) else _drop_spot(item, from_x)
		w.can_drop = _can_drop
		w.dropped = func(at: float) -> void: _delivered(id, at)
		w.into_field = func(inside: bool) -> void: _into_field(w, inside)
		w.work_seconds = clampf(Game.helper_interval(id) * 0.6, 0.8, 4.0) if harvests else 1.0
		w.carry_drawn = id in DRAWN_LOADS
		Game.live_helpers[id] = true
	world.add_child(w)
	# Helpers walk the path behind the parked cart and its donkey, so they are drawn before them.
	world.move_child(w, _cart_back.get_index())
	_helpers[id] = w


## Where a helper goes indoors at night: the door of the workshop they run nearest their patch, or the villa's.
func _home_door(id: String, near: float) -> Vector2:
	var best: BuildingView = null
	for v in building_views:
		if v.id in OPEN_SIDED or Game.building_info(v.id).get("helper", "") != id:
			continue
		if best == null or absf(_door_x(v) - near) < absf(_door_x(best) - near):
			best = v
	if best:
		return Vector2(_door_x(best), best.world_rect().end.y + 1.0)
	return Vector2(VILLA_BASE.x, VILLA_BASE.y + 4.0)


## A helper's next job: a ripe plant to pick or, by day, goods to fetch for one of their workshops. NAN when idle.
func _helper_job(id: String, w: Walker) -> float:
	_fetches.erase(id)
	_picks.erase(id)
	w.work_anim = "work"
	w.work_facing = NAN
	w.work_depth = 0.0
	var info := Game.helper_info(id)
	var plot := _ready_plot(info) if info.has("zones") or info.has("crops") else null
	if plot:
		# The helper stops short of the plant on the side they come from, so their hands, not their feet, are on it.
		var plant: float = plot.position.x + 15.0
		var reach: float = PICK_REACH.get(id, 8.0)
		_picks[id] = plot.index
		w.work_facing = plant
		# They step up from the path until their feet are just in front of the plant: clear of the water channel for
		# the front row, and in among the beds for the back row.
		w.work_depth = maxf(0.0, w.position.y - (plot.position.y + 3.0))
		return plant - reach if w.position.x < plant else plant + reach
	if Game.is_night():
		return NAN
	for v in building_views:
		if Game.building_info(v.id).get("helper", "") != id:
			continue
		var item := Game.load_need(v.id)
		if item != "":
			_fetches[id] = {"item": item, "to": _door_x(v)}
			w.work_anim = "lift"
			return _fetch_spot(id, item, v)
	return NAN


## Where a helper picks up goods for a workshop: at their own workshop that makes them, such as flour at the mill,
## else from the cart while it stands at home and is the nearer, else from the storehouse.
func _fetch_spot(id: String, item: String, target: BuildingView) -> float:
	for v in building_views:
		if v != target and Game.building_info(v.id).get("helper", "") == id and Game.current_recipe(v.id).get("out", {}).has(item):
			return _door_x(v)
	var store := _storehouse.position.x + _storehouse.region_rect.size.x / 2.0
	if _can_drop(_cart_side()) and absf(_cart_side() - _door_x(target)) < absf(store - _door_x(target)):
		return _cart_side()
	return store


func _door_x(v: BuildingView) -> float:
	return roundf(v.world_rect().get_center().x)


## Goods set down at a workshop go straight into it when the workshop has its helper.
func _delivered(id: String, at: float) -> void:
	_fetches.erase(id)
	for v in building_views:
		var helper := String(Game.building_info(v.id).get("helper", ""))
		if (at == _door_x(v) or at == v.position.x) and Game.helpers.has(helper):
			Game.load_building(v.id)


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


## The plot a helper has reached to pick, or -1 when it was picked or dug up in the meantime.
func _picked(id: String) -> int:
	var i: int = _picks.get(id, -1)
	_picks.erase(id)
	return i if i >= 0 and Game.is_ready(i) else -1


## One of the estate's parts, given this scene to work on.
func _part(script: GDScript) -> Node:
	var part: Node = script.new()
	part.m = self
	add_child(part)
	return part


## A helper picking in the back row is drawn behind the front row's plants, so they stand among the beds.
func _into_field(w: Walker, inside: bool) -> void:
	if inside and w.work_depth > (FRONT_ROW - BACK_ROW) / 2.0:
		var front: Array = plot_views.filter(func(v): return v.position.y > (FRONT_ROW + BACK_ROW) / 2.0)
		w.set_meta("path_index", w.get_index())
		world.move_child(w, front.map(func(v): return v.get_index()).min())
	elif not inside and w.has_meta("path_index"):
		world.move_child(w, mini(int(w.get_meta("path_index")), world.get_child_count() - 1))
		w.remove_meta("path_index")


## A ripe plant a helper looks after, or null when there is none.
func _ready_plot(info: Dictionary) -> PlotView:
	for v in plot_views:
		var p: Dictionary = Game.plots[v.index]
		if Game.is_ready(v.index) and Game.harvest_fits(v.index) and ((info.has("zones") and p["zone"] in info["zones"]) or (info.has("crops") and p["crop"] in info["crops"])):
			return v
	return null


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
		scenery.root_in_ground.call_deferred(v.world_rect(), hash(id), v)


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
	_camera.position = Vector2(floorf(cam_x), BOTTOM - view.y)
	var left := floorf(cam_x)
	var s := float(Windowing.scale)
	# The estate is drawn in whole pixels of its own, so the rest of the pan slides its picture by whole screen pixels
	# and a slow pan glides instead of stepping a full estate pixel at a time.
	_container.position.x = -roundf((cam_x - left) * s)
	# The sky is drawn at screen resolution, so it follows the unrounded pan and slides smoothly.
	_sky_view.scale = Vector2(s, s)
	_sky_view.position = Vector2(-cam_x * PARALLAX["sky"] * s, -(BOTTOM - view.y) * s)
	_far_view.scale = Vector2(s, s)
	_far_view.position = Vector2(0, -(BOTTOM - view.y) * s)
	_mountains.position.x = roundf(-cam_x * PARALLAX["mountains"] * s) / s
	_land.position.x = roundf(-cam_x * PARALLAX["land"] * s) / s
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
	# One estate pixel wider than the window, so the picture still fills it while slid part of a pixel to the left.
	_container.size = ((window / Windowing.scale).ceil() + Vector2(1, 0)) * Windowing.scale
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


## The outline of everything visible in the transparent strip, so clicks anywhere else fall through to the desktop: the
## farm along the bottom, every building, sign and bar rising above it, as one skyline across the strip.
func _click_area() -> PackedVector2Array:
	var view := _view_size()
	var top := view.y - (BOTTOM - 214.0)
	var tall := [Rect2(_villa.position, _villa.region_rect.size), Rect2(_storehouse.position, _storehouse.region_rect.size)]
	for v in building_views:
		tall.append(v.world_rect())
	for s in signs:
		if s.visible:
			tall.append(s.world_rect())
	var rects := tall.map(func(r: Rect2) -> Rect2: return Rect2(r.position - _camera.position, r.size))
	for bar in hud.strip_bar_rects():
		rects.append(Rect2(bar.position * Windowing.ui_scale / Windowing.scale, bar.size * Windowing.ui_scale / Windowing.scale))
	# The skyline's height in each column of the view: the farm's top line, raised wherever something stands over it.
	var width := int(ceilf(view.x))
	var heights := PackedFloat32Array()
	heights.resize(width)
	heights.fill(top)
	for r in rects:
		for x in range(maxi(0, int(floorf(r.position.x))), mini(width, int(ceilf(r.end.x)))):
			heights[x] = minf(heights[x], r.position.y)
	var points := PackedVector2Array([Vector2(0, view.y)])
	var x := 0
	while x < width:
		var end := x
		while end < width and heights[end] == heights[x]:
			end += 1
		points.append_array([Vector2(x, heights[x]), Vector2(end, heights[x])])
		x = end
	points.append(Vector2(view.x, view.y))
	return points


func _world_input(event: InputEvent) -> void:
	# Letters typed into a name field are not commands for the estate.
	if market.visible or interior.visible or hud.modal_open() or (event is InputEventKey and get_viewport().gui_get_focus_owner() is LineEdit):
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
						Audio.play("click", -10.0)
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
	if _stork.visible and Hit.texture_has_pixel(_stork.texture, _stork.position, point):
		return "stork"
	if _donkey_at(point):
		return "donkey"
	if not _wildlife.rabbit_at(point).is_empty():
		return "rabbit"
	if _wildlife.fox_at(point):
		return "fox"
	if _wildlife.hoopoe_at(point):
		return "hoopoe"
	return ""


## The trader's donkey or the paving cart's under the pointer, or null.
func _donkey_at(point: Vector2) -> AnimatedSprite2D:
	for d in [_donkey, _stone_donkey]:
		# The paving cart's donkey is drawn inside the cart, so its place is counted from the cart's.
		var host: Node2D = road._stone_cart if d == _stone_donkey else d
		if d and d.is_visible_in_tree() and d.modulate.a > 0.5 and Hit.frame_has_pixel(host, d, point):
			return d
	return null


func _call_out(animal: String, point: Vector2) -> void:
	var grazing: Node2D = _pasture.animal_at(point)
	var donkey: AnimatedSprite2D = _donkey_at(point) if animal == "donkey" else null
	if animal == "rabbit":
		_wildlife.startle(_wildlife.rabbit_at(point), point)
		return
	if animal == "fox":
		_wildlife.startle_fox(point)
		return
	if animal == "hoopoe":
		_wildlife.call_hoopoe(point)
		return
	if grazing:
		grazing.react()
	elif donkey and donkey.animation == "stand" and not (donkey == _donkey and _riding):
		donkey.play("bray")
		donkey.animation_finished.connect(func(): donkey.play("stand"), CONNECT_ONE_SHOT)
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
	Audio.play(sound, -4.0, 0.1)
	_hearts(point + Vector2(0, -6))


## The dog or cat under the pointer, if it stands in front of the plant there (or there is no plant).
func _pet_at(point: Vector2, plant: Node2D) -> Node2D:
	var under := ([cat, dog] + _people()).filter(func(p): return p and p.visible and p.contains(point) and (plant == null or p.position.y >= plant.position.y))
	return Hit.front_most(under, point)


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
			hud.say(func() -> Vector2: return (pet.position if is_instance_valid(pet) else Vector2.INF) + Vector2(0, -46) - _camera.position, pet.saying())
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
	if villa.villa_rect().has_point(point):
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
	points.append(villa.villa_rect().position + Vector2(villa.villa_rect().size.x / 2.0, 10))
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
			hud.toast(tr("In the full game") if Game.zone_in_full_game(String(Game.plots[i]["zone"])) else tr("Buy this land first"))
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
	var on_villa := not view and not sign_hit and not pet and animal == "" and not building and not _cart_rect().has_point(point) and villa.villa_rect().has_point(point)
	if on_villa != _villa_hovered:
		_villa_hovered = on_villa
		_villa_outline.queue_redraw()
	if view:
		_describe_plot(view.index)
	elif sign_hit:
		var z := Game.zone_info(sign_hit.zone_id)
		var block := Game.zone_block(sign_hit.zone_id)
		hud.set_info(tr(block) if block != "" else tr("Buy the %s deed: %d sestertii") % [Ui.mid(tr(String(z.get("name", "")))), int(z.get("deed", 0))])
	elif pet:
		hud.set_info(tr("Pet %s") % Game.pet_name("dog" if pet_hit == dog else "cat") if pet_hit in [cat, dog] else pet_hit.display_name)
	elif animal != "":
		hud.set_info(tr({"hen": "A hen", "goat": "A goat", "stork": "The stork on its nest", "donkey": "The donkey", "rabbit": "A rabbit", "hoopoe": "The hoopoe"}.get(animal, "")))
	elif building:
		hud.set_info(tr("%s: click for details") % tr(String(Game.building_info(building.id).get("name", ""))))
	elif _villa_hovered:
		hud.set_info(tr("%s: click for details") % tr(String(Game.villa_stages()[clampi(Game.villa_stage - 1, 0, Game.villa_stages().size() - 1)].get("name", "Farmhouse"))))
	elif Rect2(_storehouse.position, _storehouse.region_rect.size).has_point(point):
		hud.set_info(tr("Storehouse: %d / %d") % [Game.in_storehouse(), Game.storage_capacity()])
	elif _cart_rect().has_point(point):
		hud.set_info(tr("The trader is away at market") if Game.cart["away"] else (tr("The cart is on its way home") if _cart_returning else tr("Ride the cart to market")))
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
				hud.set_info(tr("Plant %s: %d sestertii") % [Ui.mid(tr(String(seed.get("name", "")))), int(seed.get("plant_cost", 0))])
		"bloom":
			hud.set_info(tr("Dig up the %s") % Ui.mid(crop_name) if hud.tool == "dig" else tr("%s is ready: click to harvest") % crop_name)
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
	Audio.play("harvest")
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
	Audio.play({"aged_wine": "cork", "bread": "oven", "herb_bread": "oven"}.get(item, "made"), -4.0)
	for v in building_views:
		if v.id == id:
			hud.float_text(v.position + Vector2(-16, -v.local_rect().size.y - 14) - _camera.position, "+%d %s" % [amount, Ui.mid(tr(String(Data.get_value("items.%s.name" % item, item))))])
			_burst(v.position + Vector2(0, -v.local_rect().size.y / 2), [Color(1, 0.9, 0.6), Color(0.95, 0.8, 0.5)], 6)


func _on_building_changed(id: String) -> void:
	var state := String(Game.buildings[id]["state"])
	call_deferred("_note_state", id, state)
	var name := Ui.mid(tr(String(Game.building_info(id).get("name", ""))))
	for v in building_views:
		if v.id != id:
			continue
		match state:
			"owned":
				Audio.play("coins")
				hud.toast(tr("You own the %s. Repair it to put it to work.") % name)
			"repairing":
				Audio.play("hammer")
				_dust(v.position, 14)
				hud.toast(tr("Repairs have begun"))
			"upgrading":
				Audio.play("hammer")
				_dust(v.position, 14)
				hud.toast(tr("Builders are improving the %s") % name)
			"working":
				if _building_states.get(id, "") == "upgrading":
					Audio.play("built")
					_dust(v.position, 24)
					hud.toast(tr("The %s is now level %d") % [name, int(Game.buildings[id]["level"]) + 1])
				elif int(Game.buildings[id]["level"]) == 0 and not Game.buildings[id]["busy"] and Game.buildings[id]["queue"].is_empty():
					Audio.play("built")
					_dust(v.position, 24)
					hud.toast(tr("The %s is working again!") % name)


## Remembers each building's state, so a building coming back to work can tell an upgrade from a repair.
func _note_state(id: String, state: String) -> void:
	_building_states[id] = state


func _on_zone_bought(zone_id: String) -> void:
	Audio.play("flourish")
	var z := Game.zone_info(zone_id)
	_dust(Vector2(float(z["x"]) + 240, 250), 30)
	hud.toast(tr("The %s is yours!") % Ui.mid(tr(String(z.get("name", "")))))


func _on_weather_changed(weather: String, before: String) -> void:
	if weather == "rain":
		Audio.play("rain_start")
		hud.toast(tr("Rain is falling: the fields are watered"))
	elif weather == "mist" and Lighting.night_amount(Game.day_time) < 0.6:
		Game.discover("sighting:mist")


func _on_unlocked(_plot_index: int) -> void:
	Audio.play("unlock")


## A new animal announces itself in its own voice.
func _on_animal_added(kind: String) -> void:
	Audio.play({"hen": "cluck", "goat": "goat"}.get(kind, "unlock"))


## A new helper arrives with a greeting.
func _on_helper_arrived(id: String) -> void:
	Audio.play("rustle", -6.0)
	Audio.play("salve_woman" if id in WOMEN else "salve_man", -4.0)


## A new decoration is knocked into place.
func _on_decoration_bought(_id: String) -> void:
	Audio.play("made", -4.0)


## A cart sent off while the donkey is stabled has the donkey fetched and put in the shafts straight away.
func _hitch_donkey() -> void:
	if _donkey_night == "":
		return
	if _donkey_tween:
		_donkey_tween.kill()
	_donkey_night = ""
	_donkey.visible = true
	_donkey.modulate.a = 1.0
	_donkey.position.y = RIG_BASE
	_donkey.speed_scale = 1.0
	_harness.visible = true


func _on_cart_left(_items: int, value: int) -> void:
	# Trips made while time is caught up all at once would each queue their own messages, so the cart is simply sent away.
	if Game.quiet:
		_show_cart_away()
		return
	_hitch_donkey()
	Audio.play("cart")
	# A trader can send the cart off again while it is still driving home; it turns round, and is no longer returning.
	if _cart_returning:
		hud.toast(tr("The cart is back: +%d sestertii") % _coins_coming)
	hud.toast(tr("The cart heads to market with %d sestertii of goods") % value)
	_cart_returning = false
	rig.face_rig(false)
	_donkey.position.x = rig.harness_x(_cart.position.x, false)
	_donkey.play("walk")
	# The road to town runs off the right edge of the estate, so the cart travels the whole way there.
	rig.move_rig(estate_width + 60, (estate_width + 60 - _cart.position.x) / 90.0)


func _on_cart_returned(coins: int) -> void:
	Audio.play("cart")
	# Coming home the donkey leads from the right, so the rig is mirrored with the donkey in front.
	rig.face_rig(true)
	_cart_returning = true
	_cart.position.x = estate_width + 60
	_donkey.position.x = rig.harness_x(_cart.position.x, true)
	_donkey.play("walk")
	rig.move_rig(CART_HOME_X, (estate_width + 60 - CART_HOME_X) / 90.0, true)
	_coins_coming = coins
	# The arrival is part of the drive, so a drive cut short by the next trip never leaves it waiting.
	_rig_tween.chain().tween_callback(_on_cart_home.bind(coins))


func _on_cart_home(coins: int) -> void:
	_dust(Vector2(CART_HOME_X + 40, RIG_BASE), 10)
	_cart_returning = false
	rig.park_rig()
	Audio.play("coins")
	hud.float_text(Vector2(CART_HOME_X + 24, RIG_BASE - 46) - _camera.position, "+%d" % coins)
	_burst(Vector2(CART_HOME_X + 30, RIG_BASE - 20), [Color(1, 0.86, 0.35), Color(0.96, 0.72, 0.25)], 12)
	hud.toast(tr("The cart is back: +%d sestertii") % coins)


## Time caught up all at once moves the farm on without the signals the scene follows, so the scene is set from the state.
func _on_caught_up(_summary: Dictionary) -> void:
	_dress_storehouse()
	_store_scaffold.visible = Game.projects.has("storage")
	for id in Game.buildings:
		_building_states[id] = String(Game.buildings[id]["state"])
	# A cart driving out may carry on out of sight, but one that came home is parked where helpers can load it.
	var heading_out := _rig_tween != null and _rig_tween.is_running() and not _cart_returning
	if Game.cart["away"] and not heading_out:
		_show_cart_away()
	elif not Game.cart["away"] and not _riding:
		_park_cart()


## Puts the cart on the road to town out of sight, as a farm opened with the cart away shows it.
func _show_cart_away() -> void:
	if _rig_tween:
		_rig_tween.kill()
	_cart_returning = false
	_hitch_donkey()
	rig.face_rig(false)
	_cart.position.x = estate_width + 60
	_donkey.position.x = rig.harness_x(_cart.position.x, false)


func _on_dog_petted(sleepy := false) -> void:
	if sleepy:
		Audio.tail_thumps()
	else:
		Audio.play("dog", -9.0, 0.06)
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
	Audio.play("hammer")
	villa.place_villa()
	_villa_scaffold.visible = true
	if not Settings.reduced_motion:
		_villa_scaffold.rise()
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 16)
	hud.toast(tr("Work on the villa has begun"))


func _on_villa_finished() -> void:
	villa.place_villa()
	if Settings.reduced_motion:
		_villa_scaffold.visible = false
	else:
		_villa_scaffold.sink().tween_callback(func(): _villa_scaffold.visible = Game.villa_build["active"])
	Audio.play("built")
	hud.toast(tr("The villa has been restored: %s!") % Ui.mid(tr(String(Game.villa_stages()[Game.villa_stage - 1]["name"]))))
	_dust(_villa.position + Vector2(_villa.region_rect.size.x / 2, _villa.region_rect.size.y - 4), 40)
	_villa.modulate = Color(1.6, 1.5, 1.3)
	create_tween().tween_property(_villa, "modulate", Color.WHITE, 0.9)


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


## Where builders work on a farm improvement: at the storehouse, along the water channel, or on the next stretch of road.
func _project_site(id: String) -> Rect2:
	match id:
		"storage":
			return Rect2(_storehouse.position, _storehouse.region_rect.size)
		"channels":
			return Rect2(_channels.front() - 30.0, 236, 50, 31)
	return Rect2(_paving_front - 30.0, 250, 50, 31)


func _on_upgrade_started(id: String) -> void:
	Audio.play("hammer")
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
	var used := Hit.used_rect(tex)
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
		Audio.play("built")
		hud.toast(tr("The work is finished"))
	if id == "cart_speed":
		road.pave_road()
		_dust(Vector2(cam_x + _view_size().x / 2.0, 280), 24)
	if id == "cart_capacity":
		# The new cart is knocked together on the spot and rolled out.
		Audio.play("made", -4.0)
		Audio.play("cart", -6.0)
		rig.size_cart()
		_dust(Vector2(_cart.position.x + 30, RIG_BASE), 14)


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
	var used := Hit.used_rect(tex)
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
	cat.petted.connect(func(): _hearts(cat.position + Vector2(0, -18)); Audio.play("cat", -4.0, 0.08); Game.add_stat("pets", 1))
	world.add_child(cat)
	dog = Dog.new()
	dog.coat = String(Game.pets.get("dog", {}).get("coat", ""))
	dog.breed = String(Game.pets.get("dog", {}).get("breed", ""))
	dog.dir = Coats.breed_dir("dog", dog.breed)
	dog.position = Vector2(HOME + 345, 268)
	dog.min_x = HOME + 10
	dog.max_x = HOME + 456
	dog.petted.connect(_on_dog_petted)
	world.add_child(dog)
	cat.door_x = VILLA_BASE.x
	dog.door_x = VILLA_BASE.x
	# Both stand behind the cart, which parks on the road in front of them.
	if _cart_load:
		world.move_child(cat, _cart_load.get_index())
		world.move_child(dog, _cart_load.get_index())
	# On a new farm the pets come home once the player has chosen them.
	cat.visible = Game.pets_chosen
	dog.visible = Game.pets_chosen

