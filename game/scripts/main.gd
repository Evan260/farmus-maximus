extends Node2D
## Builds the home farm scene from its layers and turns clicks into farm actions.

const PlotView := preload("res://scripts/plot_view.gd")
const Dog := preload("res://scripts/dog.gd")
const Critters := preload("res://scripts/critters.gd")
const Fireflies := preload("res://scripts/fireflies.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const BG := "res://assets/backgrounds/home_farm/"
## Bottom centre of the villa, where the path in the field meets its steps.
const VILLA_BASE := Vector2(371, 234)
const FRONT_ROW := 263
const BACK_ROW := 246
const SHADOW := Color(0.16, 0.11, 0.12, 0.28)

var plot_views: Array = []
var hud: CanvasLayer
var dog: Node2D
var _daylight: CanvasModulate
var _sky_day: Sprite2D
var _sky_night: Sprite2D
var _villa: Sprite2D
var _villa_shadow: Sprite2D
var _cart: Sprite2D
var _cart_shadow: Sprite2D
var _donkey: AnimatedSprite2D
var _rig_tween: Tween
var _storehouse: Sprite2D
var _glow_layer: CanvasLayer
var _window_glow: Sprite2D
var _clouds: Array = []
var _hammer_timer := 0.0
## Where the cart parks, on the soil just right of the path, with the donkey at its handles.
const CART_HOME_X := 380.0
const RIG_BASE := 266


func _ready() -> void:
	if "--demo" in OS.get_cmdline_user_args():
		_load_demo_state()
	_daylight = CanvasModulate.new()
	add_child(_daylight)
	# The sky gets its own layer, outside the night tint, so the night sky's stars and moon keep their own colours.
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -1
	add_child(sky_layer)
	_sky_day = _add_texture(load(BG + "layer_sky.png"), Vector2(-16, 0), sky_layer)
	_sky_night = _add_texture(load(BG + "layer_sky_night.png"), Vector2(-16, 0), sky_layer)
	for i in 3:
		var c := _add_trimmed(load(BG + "cloud_%d.png" % (i + 1)), Vector2([40, 210, 360][i], [18, 52, 30][i]), false, 0, sky_layer)
		_clouds.append({"sprite": c, "speed": [2.2, 1.4, 3.0][i]})
	_glow_layer = CanvasLayer.new()
	_glow_layer.layer = 1
	add_child(_glow_layer)
	# The background layers are wider than the screen; the extra width is for camera panning later.
	_add_texture(load(BG + "layer_mountains.png"), Vector2(-16, 0))
	_add_texture(load(BG + "layer_land.png"), Vector2(-16, 0))
	_villa_shadow = _add_texture(null, Vector2.ZERO)
	_villa = _add_trimmed(_villa_texture(), Vector2.ZERO)
	_window_glow = _add_texture(null, Vector2.ZERO, _glow_layer)
	_window_glow.region_enabled = true
	_place_villa()
	_add_texture(Lighting.ellipse_texture(70, 7, SHADOW), Vector2(194, 230))
	_storehouse = _add_trimmed(load("res://assets/sprites/farm/storehouse.png"), Vector2(198, 0), true, 236)
	var pine := _add_trimmed(load("res://assets/sprites/trees/umbrella_pine_1.png"), Vector2(-16, 0), true, 240)
	_add_texture(Lighting.ellipse_texture(64, 7, SHADOW), Vector2(pine.position.x + pine.region_rect.size.x / 2 - 32, 236))
	_add_texture(load(BG + "field.png"), Vector2(-40, 0))
	_build_plots()

	var critters := Critters.new()
	critters.bloom_points = _bloom_points
	add_child(critters)
	dog = Dog.new()
	dog.position = Vector2(345, 268)
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
	hud = Hud.new()
	add_child(hud)

	Game.planted.connect(func(i): Sfx.play("plant"); _view(i).bounce())
	Game.unlocked.connect(func(_i): Sfx.play("unlock"))
	Game.harvested.connect(_on_harvested)
	Game.villa_build_started.connect(func(_stage): _on_build_started())
	Game.villa_upgraded.connect(func(_stage): _on_villa_finished())
	Game.cart_left.connect(_on_cart_left)
	Game.cart_returned.connect(_on_cart_returned)
	dog.petted.connect(_on_dog_petted)
	if Game.cart["away"]:
		_cart.position.x = 560
		_donkey.position.x = 620


func _process(delta: float) -> void:
	var night := Lighting.night_amount(Game.day_time)
	_daylight.color = Lighting.color_at(Game.day_time)
	_sky_day.modulate = _daylight.color
	_sky_night.modulate.a = night
	_window_glow.modulate.a = night
	for c in _clouds:
		var sprite: Sprite2D = c["sprite"]
		sprite.position.x += c["speed"] * delta
		if sprite.position.x > 500:
			sprite.position.x = -sprite.region_rect.size.x - 10
		# The drifting day clouds fade out at night, when the night sky has clouds of its own.
		sprite.modulate = Color(_daylight.color, 1.0 - night)
	_cart_shadow.position = Vector2(_cart.position.x - 2, RIG_BASE - 5)
	if Game.villa_build["active"]:
		_hammer_timer -= delta
		if _hammer_timer <= 0.0:
			_hammer_timer = randf_range(1.2, 2.6)
			Sfx.play("hammer", -10.0, 0.15)
			_dust(_villa.position + Vector2(randf_range(10, _villa.region_rect.size.x - 10), _villa.region_rect.size.y - 4), 6)


## Fills the farm with plants at every stage, for screenshots and clips; saving is switched off so a real save is never touched.
func _load_demo_state() -> void:
	Saves.enabled = false
	Saves.pending_summary = {}
	Game.new_game()
	Game.coins = 180
	Game.storage = {"lavender": 7}
	var stages := [1.0, 1.0, 0.7, 1.0, 0.4, 1.0, 1.0, 0.1, 1.0, 1.0, 0.8, 1.0, 1.0, 0.3, 1.0, 1.0, 0.0]
	for i in Game.plots.size():
		var p: Dictionary = Game.plots[i]
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


func _build_plots() -> void:
	# The back row sits half a plot to the right of the front row, so every plant shows between the ones in front.
	var spots: Array = []
	for i in 9:
		spots.append(Vector2(8 + i * 36, FRONT_ROW))
	for i in 8:
		spots.append(Vector2(26 + i * 36, BACK_ROW))
	var count := mini(spots.size(), Game.plots.size())
	var order := range(count)
	order.sort_custom(func(a, b): return spots[a].y < spots[b].y)
	for i in order:
		var v := PlotView.new()
		v.index = i
		v.position = spots[i]
		add_child(v)
		plot_views.append(v)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(get_global_mouse_position())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point := get_global_mouse_position()
		if dog.contains(point):
			dog.pet()
			get_viewport().set_input_as_handled()
			return
		var view := _plot_at(point)
		if view:
			_click_plot(view.index)
			get_viewport().set_input_as_handled()
		elif _cart_rect().has_point(point):
			Game.send_cart()
			get_viewport().set_input_as_handled()


func _click_plot(i: int) -> void:
	match Game.plot_visual(i):
		"locked":
			Game.try_unlock(i)
		"empty":
			Game.try_plant(i)
		"bloom":
			Game.try_harvest(i)
		_:
			hud.toast("Still growing")
	_update_hover(get_global_mouse_position())


func _update_hover(point: Vector2) -> void:
	var view := _plot_at(point)
	for v in plot_views:
		v.hovered = v == view
	if view == null:
		if dog.contains(point):
			hud.set_info("Pet the dog")
		elif Rect2(_storehouse.position, _storehouse.region_rect.size).has_point(point):
			hud.set_info("Storeroom: %d / %d" % [Game.stored_total(), Game.storage_capacity()])
		elif _cart_rect().has_point(point):
			hud.set_info("Click the cart to sell")
		else:
			hud.set_info("")
		return
	var i: int = view.index
	match Game.plot_visual(i):
		"locked":
			hud.set_info("Unlock this plot: %d sestertii" % Game.unlock_cost())
		"empty":
			hud.set_info("Plant lavender: %d sestertii" % int(Game.crop_info("lavender").get("plant_cost", 0)))
		"bloom":
			hud.set_info("Lavender in bloom: click to harvest")
		_:
			hud.set_info("Lavender growing: %d%%" % int(Game.growth_fraction(i) * 100))


func _plot_at(point: Vector2) -> Node2D:
	# Front-row plots overlap the back row, so the front row is checked first.
	for k in range(plot_views.size() - 1, -1, -1):
		if plot_views[k].contains(point):
			return plot_views[k]
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
	hud.float_text(v.position + Vector2(10, -34), "+%d" % amount)
	_burst(v.position + Vector2(14, -18), [Color(0.74, 0.57, 0.87), Color(0.57, 0.38, 0.69), Color(0.62, 0.66, 0.52)], 10)


func _on_cart_left(_items: int, value: int) -> void:
	Sfx.play("cart")
	hud.toast("The cart heads to market with %d sestertii of goods" % value)
	_donkey.flip_h = false
	_cart.flip_h = false
	_donkey.play("walk")
	_move_rig(CART_HOME_X + 190, 3.0)


func _on_cart_returned(coins: int) -> void:
	Sfx.play("cart")
	# Coming home the donkey leads from the right, so the rig is mirrored with the donkey in front.
	_cart.flip_h = true
	_donkey.flip_h = true
	_cart.position.x = 520
	_donkey.position.x = 500
	_donkey.play("walk")
	_move_rig(CART_HOME_X + 24, 2.6, true)
	await _rig_tween.finished
	_dust(Vector2(CART_HOME_X + 40, RIG_BASE), 10)
	_park_rig()
	Sfx.play("coins")
	hud.float_text(Vector2(CART_HOME_X + 24, RIG_BASE - 46), "+%d" % coins)
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


func _place_villa() -> void:
	var tex := _villa_texture()
	_villa.texture = tex
	var used := tex.get_image().get_used_rect()
	_villa.region_rect = used
	_villa.position = Vector2(round(VILLA_BASE.x - used.size.x / 2.0), VILLA_BASE.y - used.size.y + 1)
	_villa_shadow.texture = Lighting.ellipse_texture(used.size.x + 12, 9, SHADOW)
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
