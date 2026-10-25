extends Node2D
## Builds the home farm scene from its layers and turns clicks into farm actions.

const PlotView := preload("res://scripts/plot_view.gd")
const Hud := preload("res://scripts/ui/hud.gd")
const BG := "res://assets/backgrounds/home_farm/"
## Bottom centre of the villa, where the path in the field meets its steps.
const VILLA_BASE := Vector2(371, 234)
const FRONT_ROW := 263
const BACK_ROW := 246

var plot_views: Array = []
var hud: CanvasLayer
var _villa: Sprite2D
var _cart: Sprite2D
var _cart_home := Vector2.ZERO
var _cart_tween: Tween


func _ready() -> void:
	if "--demo" in OS.get_cmdline_user_args():
		_load_demo_state()
	# The background layers are wider than the screen; the extra width is for camera panning later.
	_add_texture(load(BG + "layer_sky.png"), Vector2(-16, 0))
	_add_texture(load(BG + "layer_mountains.png"), Vector2(-16, 0))
	_add_texture(load(BG + "layer_land.png"), Vector2(-16, 0))
	_villa = _add_trimmed(_villa_texture(), Vector2.ZERO)
	_place_villa()
	_add_trimmed(load("res://assets/sprites/trees/umbrella_pine_1.png"), Vector2(-16, 0), true, 240)
	_add_texture(load(BG + "field.png"), Vector2(-40, 0))
	_build_plots()
	_add_trimmed(load("res://assets/sprites/dog/east.png"), Vector2(330, 0), true, 268)
	_cart = _add_trimmed(load("res://assets/sprites/farm/cart.png"), Vector2(414, 0), true, 266)
	_cart_home = _cart.position

	hud = Hud.new()
	add_child(hud)
	Game.harvested.connect(_on_harvested)
	Game.villa_upgraded.connect(func(_stage): _place_villa(true))
	Game.cart_left.connect(_on_cart_left)
	Game.cart_returned.connect(_on_cart_returned)
	if Game.cart["away"]:
		_cart.position.x = 500


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
		var view := _plot_at(point)
		if view:
			_click_plot(view.index)
			get_viewport().set_input_as_handled()
		elif Rect2(_cart.position, _cart.region_rect.size).has_point(point):
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
		hud.set_info("Click the cart to sell" if Rect2(_cart.position, _cart.region_rect.size).has_point(point) else "")
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


func _on_harvested(plot_index: int, amount: int) -> void:
	for v in plot_views:
		if v.index == plot_index:
			hud.float_text(v.position + Vector2(10, -34), "+%d" % amount)


func _on_cart_left(_items: int, value: int) -> void:
	hud.toast("The cart heads to market with %d sestertii of goods" % value)
	_move_cart(500, 1.2)


func _on_cart_returned(coins: int) -> void:
	hud.toast("The cart is back: +%d sestertii" % coins)
	_cart.position.x = 500
	_move_cart(_cart_home.x, 1.2)


func _move_cart(x: float, seconds: float) -> void:
	if _cart_tween:
		_cart_tween.kill()
	_cart_tween = create_tween()
	_cart_tween.tween_property(_cart, "position:x", x, seconds).set_trans(Tween.TRANS_SINE)


func _villa_texture() -> Texture2D:
	var stages := Game.villa_stages()
	var stage: Dictionary = stages[clampi(Game.villa_stage - 1, 0, stages.size() - 1)]
	return load("res://assets/sprites/villa/%s.png" % stage.get("sprite", "stage1"))


func _place_villa(with_effect := false) -> void:
	var tex := _villa_texture()
	_villa.texture = tex
	var used := tex.get_image().get_used_rect()
	_villa.region_rect = used
	_villa.position = Vector2(round(VILLA_BASE.x - used.size.x / 2.0), VILLA_BASE.y - used.size.y + 1)
	if with_effect:
		hud.toast("The villa has been restored!")
		var flash := create_tween()
		_villa.modulate = Color(1.6, 1.5, 1.3)
		flash.tween_property(_villa, "modulate", Color.WHITE, 0.8)


func _add_texture(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	add_child(s)
	return s


## Adds a sprite cropped to its visible pixels; with from_bottom, pos.y is ignored and the sprite stands on base_y.
func _add_trimmed(tex: Texture2D, pos: Vector2, from_bottom := false, base_y := 0) -> Sprite2D:
	var s := _add_texture(tex, pos)
	var used := tex.get_image().get_used_rect()
	s.region_enabled = true
	s.region_rect = used
	if from_bottom:
		s.position.y = base_y - used.size.y
	return s
