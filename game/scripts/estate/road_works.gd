extends Node
## The road along the front of the estate as it is improved: the paving, the kerb and milestones, the footpath, and
## the stone cart and its donkey that carry the work along.

## The estate scene this works for.
var m: Estate
## How far along the road the milestones have been set.
var _milestone_reach := -40.0
## How far the gravel footpath along the verge has been laid.
var _footpath_reach := -40.0
## The cart that brings paving stones up to the work, with its donkey and its load.
var _stone_cart: Node2D
## Where the stone cart stands on the road, and its wheel.
var _stone_x := 0.0
var _stone_wheel: Sprite2D
## True on the frame the stone cart comes into view.
var _stone_first_look := false
## The road's level and whether work on it was under way when it was last drawn.
var _drawn := []


## Each improvement to the road is worked along its whole length: first the paving, then a kerb of raised stones along
## its far edge with milestones beside it, then a gravel footpath along the verge. While one is under way it reaches as
## far as the work has come.
func pave_road() -> void:
	var level := int(Game.levels.get("cart_speed", 0))
	var front := 2440.0
	if Game.projects.has("cart_speed"):
		var done := clampf(1.0 - float(Game.projects["cart_speed"]) / maxf(1.0, Game.upgrade_seconds("cart_speed")), 0.0, 1.0)
		front = roundf(lerpf(-40.0, 2440.0, done))
	var reach := func(stage: int) -> float:
		if level > stage:
			return 2440.0
		return front if level == stage and Game.projects.has("cart_speed") else -40.0
	m._paving_front = front
	var paved: float = reach.call(0)
	m._paved_reach = paved
	m._road.visible = paved > -40.0
	# The paving's own far kerb is only shown once the kerbstones have been laid.
	m._road.region_rect = Rect2(0, 3, paved + 40.0, 17)
	m._road.position = Vector2(-40.0, 273.0)
	m._kerb.visible = float(reach.call(1)) > -40.0
	m._kerb.region_rect = Rect2(0, 0, float(reach.call(1)) + 40.0, 3)
	m._kerb.position = Vector2(-40.0, 270.0)
	_milestone_reach = reach.call(1)
	_footpath_reach = reach.call(2)
	_drawn = [level, Game.projects.has("cart_speed")]
	m._road_works.queue_redraw()


## Ahead of the paving, a strip of levelled gravel waits for the stones, with a heap of them at the working edge; the
## milestones stand at the road's far side as far as they have been set.
func draw_road_works() -> void:
	# The footpath: a strip of pale packed gravel along the verge, flecked with darker stones.
	if _footpath_reach > -40.0:
		m._road_works.draw_rect(Rect2(-40, 266, _footpath_reach + 40.0, 4), Color8(196, 178, 140))
		m._road_works.draw_rect(Rect2(-40, 266, _footpath_reach + 40.0, 1), Color8(214, 198, 160))
		for x in range(-40, int(_footpath_reach), 5):
			m._road_works.draw_rect(Rect2(x + (x * 7) % 3, 267 + (x * 13) % 3, 1, 1), Color8(150, 134, 108))
	for at in Estate.MILESTONES:
		if at <= _milestone_reach:
			draw_milestone(float(at))
	if not Game.projects.has("cart_speed") or int(Game.levels.get("cart_speed", 0)) > 0:
		return
	var x := m._paving_front
	var gravel := Color8(150, 138, 118)
	for i in 40:
		var shade := gravel.darkened(0.08 * ((i * 7) % 3))
		m._road_works.draw_rect(Rect2(x + i, 272, 1, 18), shade)
	for k in 14:
		var at := Vector2(x + (k * 13) % 38, 273 + (k * 5) % 15)
		m._road_works.draw_rect(Rect2(at, Vector2(1, 1)), gravel.darkened(0.25))
	var stone := Color8(128, 122, 116)
	for row in 4:
		var w := 8 - row * 2
		m._road_works.draw_rect(Rect2(x + 2 + row, 270 - row * 2, w, 2), stone.lightened(0.08 * row))
		m._road_works.draw_rect(Rect2(x + 2 + row, 271 - row * 2, w, 1), stone.darkened(0.2))
	for k in 5:
		m._road_works.draw_rect(Rect2(x + 12 + k * 5, 278 + (k % 2) * 5, 3, 2), stone)


## A Roman milestone: a short round column on a square foot, lit on its left, with its lettering as a dark band.
func draw_milestone(x: float) -> void:
	var stone := Color8(196, 188, 170)
	var shade := Color8(150, 142, 128)
	m._road_works.draw_rect(Rect2(x - 3, 266, 7, 3), shade)
	m._road_works.draw_rect(Rect2(x - 3, 266, 7, 1), stone)
	for row in 12:
		var y := 254 + row
		m._road_works.draw_rect(Rect2(x - 2, y, 2, 1), stone.lightened(0.08) if row < 2 else stone)
		m._road_works.draw_rect(Rect2(x, y, 2, 1), shade)
		m._road_works.draw_rect(Rect2(x + 2, y, 1, 1), shade.darkened(0.2))
	m._road_works.draw_rect(Rect2(x - 2, 253, 4, 1), stone.lightened(0.12))
	m._road_works.draw_rect(Rect2(x - 2, 258, 4, 1), shade.darkened(0.35))
	m._road_works.draw_rect(Rect2(x - 1, 260, 3, 1), shade.darkened(0.3))
	m._road_works.draw_rect(Rect2(x - 4, 269, 9, 1), Color(0.18, 0.14, 0.08, 0.3))


## A donkey cart heaped with paving stones stands on the new road just behind the work and moves up as the paving
## advances, so the builders always have stones to hand.
func update_road_cart(delta: float) -> void:
	var paving := Game.projects.has("cart_speed")
	if not paving:
		if _stone_cart.visible:
			_stone_cart.visible = false
		# Work finished during a quiet catch-up sends no signal, so the road is redrawn whenever it differs from the game.
		if _drawn != [int(Game.levels.get("cart_speed", 0)), false]:
			pave_road()
		return
	pave_road()
	var target := maxf(0.0, m._paving_front - 96.0)
	if not _stone_cart.visible:
		_stone_cart.visible = true
		_stone_x = target
		_stone_first_look = true
	var before := _stone_x
	stable_stone_donkey()
	# It waits until the work has moved on a few steps, then walks up to it at an amble, rather than inching along; only
	# if the work has got well ahead does it hurry.
	if m._stone_night != "":
		pass
	elif target - _stone_x > 8.0 or (m._stone_donkey.animation == "walk" and target > _stone_x):
		var pace := 14.0 if target - _stone_x < 60.0 else 26.0
		_stone_x = move_toward(_stone_x, target, pace * delta)
		m._stone_donkey.play("walk")
		m._stone_donkey.speed_scale = pace / maxf(1.0, m.rig.donkey_pace())
	elif m._stone_donkey.animation != "bray" or not m._stone_donkey.is_playing():
		m._stone_donkey.play("stand")
		m._stone_donkey.speed_scale = 1.0
	_stone_wheel.rotation += (_stone_x - before) / 11.0
	_stone_cart.position = Vector2(roundf(_stone_x), 0)


## The paving cart's donkey keeps the same hours as the trader's: unhitched at dusk and walked to the barn, and back to
## its cart at daybreak.
func stable_stone_donkey() -> void:
	var night: bool = Game.is_night()
	var barn := Vector2((Estate.Pasture.BARN_LEFT + Estate.Pasture.BARN_RIGHT) / 2.0 - _stone_cart.position.x, 252.0)
	var home := Vector2(58, Estate.RIG_BASE)
	if m._stone_night == "" and night and _stone_first_look:
		# A cart first seen at night has its donkey already stabled rather than walking the whole way to the barn.
		m._stone_night = "barn"
		m._stone_donkey.position = barn
		m._stone_donkey.modulate.a = 0.0
	elif m._stone_night == "" and night:
		m._stone_night = "out"
		m._stone_donkey.flip_h = barn.x < m._stone_donkey.position.x
		m._stone_donkey.play("walk")
		var walk := create_tween()
		walk.tween_property(m._stone_donkey, "position:x", barn.x, absf(barn.x - home.x) / 26.0)
		walk.tween_property(m._stone_donkey, "position:y", barn.y, (Estate.RIG_BASE - barn.y) / 14.0)
		walk.tween_property(m._stone_donkey, "modulate:a", 0.0, 0.8)
		walk.tween_callback(func(): m._stone_night = "barn")
	elif m._stone_night == "barn" and not night:
		m._stone_night = "back"
		m._stone_donkey.position = barn
		m._stone_donkey.flip_h = home.x < barn.x
		m._stone_donkey.play("walk")
		var walk := create_tween()
		walk.tween_property(m._stone_donkey, "modulate:a", 1.0, 0.8)
		walk.tween_property(m._stone_donkey, "position:y", float(Estate.RIG_BASE), (Estate.RIG_BASE - barn.y) / 14.0)
		walk.tween_property(m._stone_donkey, "position:x", home.x, absf(barn.x - home.x) / 26.0)
		walk.tween_callback(func():
			m._stone_donkey.flip_h = false
			m._stone_donkey.play("stand")
			m._stone_night = "")
	_stone_first_look = false


## A paving cart in three layers like the trader's: the back rim, the heap of stones, and the front wall with its
## wheel, so the stones sit down inside the bed.
func build_stone_cart() -> void:
	_stone_cart = Node2D.new()
	_stone_cart.visible = false
	m.world.add_child(_stone_cart)
	var used := Rect2(Hit.used_rect(load("res://assets/sprites/farm/cart.png")))
	var top := Estate.RIG_BASE - used.size.y
	for part in ["cart_back", "heap", "cart_front"]:
		if part == "heap":
			var heap := Node2D.new()
			heap.position = Vector2(0, top)
			heap.set_meta("rest", heap.position)
			heap.draw.connect(draw_stone_heap.bind(heap))
			_stone_cart.add_child(heap)
			m._stone_parts.append(heap)
			continue
		var s := Sprite2D.new()
		s.texture = load("res://assets/sprites/farm/%s.png" % part)
		s.centered = false
		s.region_enabled = true
		s.region_rect = used
		s.position = Vector2(0, top)
		s.set_meta("rest", s.position)
		_stone_cart.add_child(s)
		m._stone_parts.append(s)
		if part == "cart_front":
			_stone_wheel = Sprite2D.new()
			_stone_wheel.texture = load("res://assets/sprites/farm/cart_wheel.png")
			_stone_wheel.position = Vector2(15, 23)
			s.add_child(_stone_wheel)
	m._stone_donkey = AnimatedSprite2D.new()
	m._stone_donkey.sprite_frames = m.rig.donkey_frames()
	m._stone_donkey.centered = false
	m._stone_donkey.offset = Vector2(-32, -Frames.feet_line(load("res://assets/sprites/donkey/walk_east/frame_00.png")))
	m._stone_donkey.position = Vector2(58, Estate.RIG_BASE)
	m._stone_donkey.play("stand")
	_stone_cart.add_child(m._stone_donkey)


## A mound of flat grey paving stones piled in the bed, highest in the middle; the front wall hides its bottom.
func draw_stone_heap(heap: Node2D) -> void:
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
