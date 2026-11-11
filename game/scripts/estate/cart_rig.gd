extends Node
## The donkey and the market cart: harnessing, driving to town and back, the goods piled on the bed, the bigger carts
## as it is upgraded, and the donkey's evenings in the barn.

## The estate scene this works for.
var m: Estate
## How many pixels longer and taller than the first cart the current one is.
var _cart_grow := Vector2i.ZERO
var _donkey_first_look := true
## How far the trader's cart has tipped forward, in radians, with no donkey in its shafts.
var _cart_tilt := 0.0
## How fast the donkeys' walk cycle travels, worked out once since measuring it reads every picture back.
var _donkey_pace := NAN
## The lowest visible row of each good's icon on the cart, by picture, measured once for the same reason.
var _icon_bottoms := {}


## Parks the cart with the donkey standing at its handles, both facing right towards the road to market.
func park_rig() -> void:
	face_rig(false)
	m._cart.position.x = Estate.CART_HOME_X
	# A donkey walking to or from the barn, or stabled for the night, keeps to what it is doing.
	if m._donkey_night != "":
		return
	m._donkey.position = Vector2(harness_x(Estate.CART_HOME_X, false), Estate.RIG_BASE)
	m._donkey.play("stand")


## At nightfall, once the cart is home, the donkey is unhitched and walks down the road to the barn in the pasture,
## turns in at its door and goes inside; at daybreak it comes out, walks back and is put in the shafts again.
func stable_donkey() -> void:
	var night := Game.is_night()
	var with_cart: bool = Game.cart["away"] or m._cart_returning or m._riding
	if m._donkey_night == "" and night and not with_cart:
		# A farm opened at night finds the donkey already stabled rather than watching it walk the whole way.
		if _donkey_first_look:
			m._donkey_night = "barn"
			m._donkey.visible = false
			m._harness.visible = false
		else:
			donkey_walk_to_barn()
	elif m._donkey_night == "barn" and not night:
		donkey_walk_home()
	_donkey_first_look = false


func donkey_walk_to_barn() -> void:
	m._donkey_night = "out"
	m._harness.visible = false
	m._dust(Vector2(m._donkey.position.x, Estate.RIG_BASE), 6)
	var door := Vector2((Estate.Pasture.BARN_LEFT + Estate.Pasture.BARN_RIGHT) / 2.0, 252.0)
	m._donkey.flip_h = door.x < m._donkey.position.x
	donkey_stroll(true)
	m._donkey_tween = create_tween()
	m._donkey_tween.tween_property(m._donkey, "position:x", door.x, absf(door.x - m._donkey.position.x) / 26.0)
	m._donkey_tween.tween_property(m._donkey, "position:y", door.y, (Estate.RIG_BASE - door.y) / 14.0)
	m._donkey_tween.tween_callback(m._donkey.play.bind("stand"))
	m._donkey_tween.tween_property(m._donkey, "modulate:a", 0.0, 0.8)
	m._donkey_tween.tween_callback(func():
		m._donkey_night = "barn"
		m._donkey.visible = false)


func donkey_walk_home() -> void:
	m._donkey_night = "back"
	m._donkey.position = Vector2((Estate.Pasture.BARN_LEFT + Estate.Pasture.BARN_RIGHT) / 2.0, 252.0)
	m._donkey.modulate.a = 0.0
	m._donkey.visible = true
	m._donkey.play("stand")
	donkey_head_home()


## Walks the donkey on from wherever it has got to on its way home, to the shafts of the cart as it is sized now.
func donkey_head_home() -> void:
	var home := Vector2(harness_x(Estate.CART_HOME_X, false), Estate.RIG_BASE)
	m._donkey.flip_h = home.x < m._donkey.position.x
	if m._donkey_tween:
		m._donkey_tween.kill()
	m._donkey_tween = create_tween()
	m._donkey_tween.tween_property(m._donkey, "modulate:a", 1.0, 0.8 * (1.0 - m._donkey.modulate.a))
	m._donkey_tween.tween_callback(donkey_stroll.bind(true))
	m._donkey_tween.tween_property(m._donkey, "position:y", float(Estate.RIG_BASE), (Estate.RIG_BASE - m._donkey.position.y) / 14.0)
	m._donkey_tween.tween_property(m._donkey, "position:x", home.x, absf(m._donkey.position.x - home.x) / 26.0)
	# Back at the cart it turns round to face the road, and the harness goes on again.
	m._donkey_tween.tween_callback(func():
		donkey_stroll(false)
		m._donkey_night = ""
		m._harness.visible = true
		if not Game.cart["away"] and not m._cart_returning:
			park_rig())


## A two-wheeled cart with no donkey between its shafts tips forward until the shaft ends rest on the ground, about
## its axle, and comes level again when the donkey is put back in.
func tip_cart(delta: float) -> void:
	var axle := m._wheel.position
	# The four-wheeled wagon stands on its own wheels, so only the two-wheeled carts tip.
	var target := rest_angle(44.0 + _cart_grow.x) if m._donkey_night != "" and not m._front_wheel.visible else 0.0
	_cart_tilt = move_toward(_cart_tilt, target, delta * 0.25)
	for sprite in [m._cart, m._cart_back]:
		sprite.rotation = _cart_tilt
		sprite.offset = axle.rotated(-_cart_tilt) - axle
	m._cart_load.rotation = _cart_tilt
	m._cart_load.position = m._cart.position + axle - axle.rotated(_cart_tilt)
	if not m._stone_parts.is_empty():
		var rest: Vector2 = m._stone_parts[0].get_meta("rest")
		tip_parts(m._stone_parts, rest + Vector2(15, 23), rest_angle(44.0) if m._stone_night != "" else 0.0, delta)


## How far a cart tips forward before its shaft ends touch the ground: the shaft ends are reach pixels ahead of the
## axle and 4 above it, and the ground is 12 below the axle, where the wheel stands.
func rest_angle(reach: float) -> float:
	var tip := Vector2(reach, -4.0)
	return asin(12.0 / tip.length()) - tip.angle()


## Tips a cart made of separate pictures about its axle, easing towards the angle; each part turns about the axle from
## where it rests.
func tip_parts(parts: Array, axle: Vector2, target: float, delta: float) -> void:
	var angle := move_toward(float(parts[0].rotation), target, delta * 0.25)
	for part in parts:
		var rest: Vector2 = part.get_meta("rest")
		part.rotation = angle
		part.position = axle + (rest - axle).rotated(angle)


## Walks the donkey at an amble on its own, its legs slowed to match, or puts it back to the cart's pace.
func donkey_stroll(walking: bool) -> void:
	m._donkey.play("walk" if walking else "stand")
	var pace := donkey_pace()
	m._donkey.speed_scale = 26.0 / pace if walking and pace > 0.0 else 1.0


## How many pixels a second the donkeys' walk carries them at its own frame rate; both donkeys share the pictures.
func donkey_pace() -> float:
	if is_nan(_donkey_pace):
		_donkey_pace = Estate.Walker.natural_pace(m._donkey.sprite_frames, "walk")
	return _donkey_pace


## Where the donkey stands so the shaft tips reach its harness: going out the shafts point right, coming home the cart is turned round.
func harness_x(cart_x: float, homeward: bool) -> float:
	return cart_x + 2.0 if homeward else cart_x + 58.0 + _cart_grow.x


## Each bigger cart is its own picture: stakes, then a wicker rail, then a four-wheeled wagon, each a little longer and
## taller than the last; the wheel and shafts stay at the same height.
func size_cart() -> void:
	var level := clampi(int(Game.levels.get("cart_capacity", 0)), 0, Estate.CART_GROW.size() - 1)
	_cart_grow = Estate.CART_GROW[level]
	var used := Hit.used_rect(load("res://assets/sprites/farm/cart.png")) as Rect2i
	for pair in [[m._cart_back, "cart_back"], [m._cart, "cart_front"]]:
		var s: Sprite2D = pair[0]
		var path := "res://assets/sprites/farm/%s_%d.png" % [pair[1], level]
		s.texture = load(path if level > 0 and ResourceLoader.exists(path) else "res://assets/sprites/farm/%s.png" % pair[1])
		s.region_rect = Rect2(used.position, used.size + _cart_grow)
		s.position.y = Estate.RIG_BASE - s.region_rect.size.y
	m._front_wheel.visible = level >= 3
	face_rig(m._cart.flip_h)
	m._harness.queue_redraw()
	if m._donkey_night == "back":
		donkey_head_home()
	if not Game.cart["away"] and not m._cart_returning:
		park_rig()


func face_rig(homeward: bool) -> void:
	m._cart.flip_h = homeward
	# A donkey out of the shafts, on its way to or from the barn, faces the way it walks.
	if m._donkey_night == "":
		m._donkey.flip_h = homeward
	m._wheel.position = Vector2(45.0 + _cart_grow.x if homeward else 15.0, 23.0 + _cart_grow.y)
	var front := 21.0 + _cart_grow.x
	m._front_wheel.position = Vector2(60.0 + _cart_grow.x - front if homeward else front, 23.0 + _cart_grow.y)
	update_cart_load()


## The near shaft runs from the front of the cart along the donkey's side to the collar at its shoulder,
## with a strap over its back holding the shaft up; the painted shafts on the cart are the far side's.
func draw_harness() -> void:
	var home := m._cart.flip_h
	var dir := -1.0 if home else 1.0
	var a := Vector2(m._cart.position.x + (26.0 if home else 34.0 + _cart_grow.x), m._cart.position.y + 17.0 + _cart_grow.y).round()
	var b := Vector2(m._donkey.position.x + 12.0 * dir, float(Estate.RIG_BASE) - 20.0).round()
	var leather := Color(0.3, 0.17, 0.11)
	var steps := int(absf(b.x - a.x))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / maxf(1.0, steps)).round()
		m._harness.draw_rect(Rect2(p, Vector2.ONE), Color(0.62, 0.4, 0.23))
		m._harness.draw_rect(Rect2(p + Vector2(0, 1), Vector2.ONE), Color(0.4, 0.24, 0.14))
	# The back strap rises from the shaft over the saddle; the collar strap wraps the chest at the shaft's end.
	var saddle_x := roundf(m._donkey.position.x + 2.0 * dir)
	var on_shaft := roundf(lerpf(a.y, b.y, (saddle_x - a.x) / (b.x - a.x))) if b.x != a.x else a.y
	m._harness.draw_rect(Rect2(saddle_x, float(Estate.RIG_BASE) - 27.0, 1, on_shaft - (float(Estate.RIG_BASE) - 27.0)), leather)
	m._harness.draw_rect(Rect2(b.x, b.y - 5, 1, 7), leather)


## What the cart carries: the goods waiting to go while it is home, its load on the road, and a purse of coins coming back.
func update_cart_load() -> void:
	var keys: Array = []
	if m._cart_returning:
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
	while m._cart_load.get_child_count() < paths.size():
		var icon := Sprite2D.new()
		icon.centered = false
		m._cart_load.add_child(icon)
	for k in m._cart_load.get_child_count():
		var icon: Sprite2D = m._cart_load.get_child(k)
		icon.visible = k < paths.size()
		if icon.visible:
			icon.texture = load(paths[k])
			var x := 4.0 + k * 8.0
			# Each good sits down in the bed: its visible bottom is placed below the cart's rim, which hides it.
			if not _icon_bottoms.has(paths[k]):
				_icon_bottoms[paths[k]] = Hit.used_rect(icon.texture).end.y
			var bottom: int = _icon_bottoms[paths[k]]
			icon.position = Vector2(x if not m._cart.flip_h else 60.0 + _cart_grow.x - x - 16.0, 9 - bottom - rail)


## Moves cart and donkey together; when returning, the donkey walks in front on the left.
func move_rig(cart_x: float, seconds: float, returning := false) -> void:
	if m._rig_tween:
		m._rig_tween.kill()
	var donkey_x := harness_x(cart_x, returning)
	m._rig_tween = create_tween().set_parallel()
	m._rig_tween.tween_property(m._cart, "position:x", cart_x, seconds)
	m._rig_tween.tween_property(m._donkey, "position:x", donkey_x, seconds)


func donkey_frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	# The walk's first picture is its standing pose, so the cycle starts from the second.
	Frames.add_folder(f, "walk", "res://assets/sprites/donkey/walk_east/", 9.0, true, Callable(), 1)
	# Standing, the donkey breathes, flicks an ear and swishes its tail, slowly, rather than freezing.
	Frames.add_folder(f, "stand", "res://assets/sprites/donkey/idle_east/", 4.0)
	Frames.add_folder(f, "bray", "res://assets/sprites/donkey/bray_east/", 8.0, false)
	return f
