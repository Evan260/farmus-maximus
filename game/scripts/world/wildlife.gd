extends Node2D
## The estate's smaller and rarer visitors: swallows at dusk, dragonflies in summer, snails after rain, a lizard on a warm wall,
## rabbits at dawn and dusk, and the rare fox, hoopoe and white butterfly. Each is recorded in the journal the first time it is seen.

const ANIMALS := "res://assets/sprites/animals/"

## Supplied by the scene: a sunny wall where the lizard basks, as a rectangle in estate pixels.
var lizard_wall := Rect2(690, 200, 40, 24)
var _swallows: Array = []
var _dragonflies: Array = []
var _snails: Array = []
var _lizard := {}
var _rabbits: Array = []
var _fox: AnimatedSprite2D
var _fox_dir := 1.0
var _hoopoe: Sprite2D
var _hoopoe_left := 0.0
var _white := {}
var _t := 0.0
var _rare_timer := 90.0
var _rabbit_sit: Texture2D
var _rabbit_hop: Texture2D


func _ready() -> void:
	if ResourceLoader.exists(ANIMALS + "rabbit/sit.png"):
		_rabbit_sit = load(ANIMALS + "rabbit/sit.png")
		_rabbit_hop = load(ANIMALS + "rabbit/hop.png")
	if ResourceLoader.exists(ANIMALS + "fox/walk_east/frame_00.png"):
		_fox = AnimatedSprite2D.new()
		var f := SpriteFrames.new()
		f.set_animation_speed("default", 10.0)
		var i := 0
		while ResourceLoader.exists(ANIMALS + "fox/walk_east/frame_%02d.png" % i):
			f.add_frame("default", load(ANIMALS + "fox/walk_east/frame_%02d.png" % i))
			i += 1
		_fox.sprite_frames = f
		var used := f.get_frame_texture("default", 0).get_image().get_used_rect()
		_fox.offset = Vector2(0, -(used.position.y + used.size.y) + f.get_frame_texture("default", 0).get_height() / 2.0)
		_fox.visible = false
		add_child(_fox)
	if ResourceLoader.exists(ANIMALS + "hoopoe/stand.png"):
		_hoopoe = Sprite2D.new()
		_hoopoe.texture = load(ANIMALS + "hoopoe/stand.png")
		_hoopoe.offset = Vector2(0, -12)
		_hoopoe.visible = false
		add_child(_hoopoe)


func _process(delta: float) -> void:
	_t += delta
	var hour := Game.day_time
	var night := Lighting.night_amount(hour)
	var view := _view()
	var season: String = Game.calendar.season_id()
	if hour >= 17.0 and hour < 20.0 and _swallows.size() < 4 and randf() < delta * 0.3:
		_swallows.append({"pos": Vector2(view.position.x - 10, randf_range(150, 210)), "phase": randf() * TAU, "speed": randf_range(70, 110)})
	for s in _swallows:
		s["phase"] += delta * 3.0
		s["pos"] += Vector2(float(s["speed"]), cos(s["phase"]) * 40.0) * delta
	_swallows = _swallows.filter(func(s): return s["pos"].x < view.end.x + 20)
	if not _swallows.is_empty():
		_seen("animal:birds", _swallows[0]["pos"], view)
	var dragon_time: bool = night < 0.2 and (season == "summer" or Game.calendar.wet_left > 0.0)
	if dragon_time and _dragonflies.size() < 3 and randf() < delta * 0.1:
		_dragonflies.append({"pos": Vector2(randf_range(view.position.x, view.end.x), randf_range(200, 240)), "target": Vector2.ZERO, "rest": 0.0, "age": 0.0})
	elif not dragon_time and not _dragonflies.is_empty() and randf() < delta * 0.2:
		_dragonflies.pop_back()
	for d in _dragonflies:
		d["age"] = float(d["age"]) + delta
		d["rest"] = float(d["rest"]) - delta
		if float(d["rest"]) > 0.0:
			continue
		if d["pos"].distance_to(d["target"]) < 2.0 or d["target"] == Vector2.ZERO:
			var next: Vector2 = d["pos"] + Vector2(randf_range(-60, 60), randf_range(-15, 15))
			d["target"] = Vector2(next.x, clampf(next.y, 190, 245))
			d["rest"] = randf_range(0.3, 1.5)
		d["pos"] = d["pos"].move_toward(d["target"], 80.0 * delta)
		_seen("animal:dragonfly", d["pos"], view)
	if Game.calendar.wet() and _snails.size() < 5 and randf() < delta * 0.05:
		_snails.append({"pos": Vector2(randf_range(view.position.x, view.end.x), randf_range(262, 268)), "dir": 1.0 if randf() < 0.5 else -1.0, "life": randf_range(60, 160), "age": 0.0})
	for s in _snails:
		s["pos"].x += float(s["dir"]) * 0.6 * delta
		s["life"] = float(s["life"]) - delta
		s["age"] = float(s["age"]) + delta
		_seen("animal:snail", s["pos"], view)
	_snails = _snails.filter(func(s): return s["life"] > 0.0)
	_update_lizard(delta, hour, view)
	_update_rabbits(delta, hour, view)
	_rare_timer -= delta
	if _rare_timer <= 0.0:
		_rare_timer = randf_range(120.0, 300.0)
		_start_rare(hour, night, view)
	_update_fox(delta, view)
	_update_hoopoe(delta, view)
	_update_white(delta, view)
	queue_redraw()


func _update_lizard(delta: float, hour: float, view: Rect2) -> void:
	var sunny: bool = Game.calendar.weather == "sun" and hour >= 10.0 and hour < 16.0
	if _lizard.is_empty() and sunny and randf() < delta * 0.02:
		_lizard = {"pos": Vector2(lizard_wall.position.x + randf() * lizard_wall.size.x, lizard_wall.end.y), "target": Vector2.ZERO, "rest": 0.0, "life": 40.0, "age": 0.0}
	if _lizard.is_empty():
		return
	_lizard["life"] = float(_lizard["life"]) - delta
	_lizard["age"] = float(_lizard["age"]) + delta
	_lizard["rest"] = float(_lizard["rest"]) - delta
	if float(_lizard["rest"]) <= 0.0:
		var to: Vector2 = _lizard["target"]
		if to == Vector2.ZERO or _lizard["pos"].distance_to(to) < 1.0:
			_lizard["target"] = Vector2(lizard_wall.position.x + randf() * lizard_wall.size.x, lizard_wall.position.y + randf() * lizard_wall.size.y)
			_lizard["rest"] = randf_range(1.0, 5.0)
		else:
			# Lizards dart, then freeze.
			_lizard["pos"] = _lizard["pos"].move_toward(to, 60.0 * delta)
	_seen("animal:lizard", _lizard["pos"], view)
	if float(_lizard["life"]) <= 0.0 or not sunny:
		_lizard = {}


func _update_rabbits(delta: float, hour: float, view: Rect2) -> void:
	var twilight := (hour >= 5.5 and hour < 7.5) or (hour >= 18.5 and hour < 20.5)
	if twilight and _rabbits.size() < 2 and randf() < delta * 0.05:
		var zones := [Vector2(10, 470), Vector2(1930, 2390)]
		var z: Vector2 = zones[randi() % zones.size()]
		_rabbits.append({"pos": Vector2(randf_range(z.x, z.y), randf_range(250, 266)), "hop": 0.0, "dir": 1.0, "life": randf_range(30, 60), "min": z.x, "max": z.y, "age": 0.0})
	for r in _rabbits:
		r["life"] = float(r["life"]) - delta
		r["age"] = float(r["age"]) + delta
		r["hop"] = maxf(0.0, float(r["hop"]) - delta)
		# A startled rabbit bounds away in long quick hops, then slips into the grass.
		if float(r.get("flee", 0.0)) > 0.0:
			r["flee"] = float(r["flee"]) - delta
			r["pos"].x = clampf(r["pos"].x + float(r["dir"]) * 80.0 * delta, float(r["min"]) - 40.0, float(r["max"]) + 40.0)
			r["hop"] = 0.1
			if float(r["flee"]) <= 0.0:
				r["life"] = minf(float(r["life"]), 0.6)
			continue
		if float(r["hop"]) <= 0.0 and randf() < delta * 0.5:
			r["hop"] = 0.4
			r["dir"] = 1.0 if randf() < 0.5 else -1.0
		if float(r["hop"]) > 0.0:
			r["pos"].x = clampf(r["pos"].x + float(r["dir"]) * 30.0 * delta, float(r["min"]), float(r["max"]))
		_seen("animal:rabbit", r["pos"], view)
	_rabbits = _rabbits.filter(func(r): return r["life"] > 0.0)


func _start_rare(hour: float, night: float, view: Rect2) -> void:
	var r := randf()
	if night > 0.3 and night < 0.95 and r < 0.35 and _fox and not _fox.visible:
		_fox_dir = 1.0 if randf() < 0.5 else -1.0
		_fox.position = Vector2(view.position.x - 30 if _fox_dir > 0 else view.end.x + 30, 262)
		_fox.flip_h = _fox_dir < 0
		_fox.visible = true
		_fox.play()
	elif night < 0.2 and r < 0.3 and _hoopoe and not _hoopoe.visible:
		_hoopoe.position = Vector2(randf_range(view.position.x + 40, view.end.x - 40), 258)
		_hoopoe.flip_h = randf() < 0.5
		_hoopoe.visible = true
		_hoopoe.modulate.a = 0.0
		create_tween().tween_property(_hoopoe, "modulate:a", 1.0, 0.6)
		_hoopoe_left = randf_range(12, 25)
	elif night < 0.2 and r < 0.45 and _white.is_empty():
		_white = {"pos": Vector2(view.position.x - 5, 220), "life": 25.0}


func _update_fox(delta: float, view: Rect2) -> void:
	if not _fox or not _fox.visible:
		return
	_fox.position.x += _fox_dir * 28.0 * delta
	if view.has_point(_fox.position + Vector2(0, -6)):
		Game.discover("animal:fox")
		Game.discover("sighting:fox")
	if _fox.position.x < view.position.x - 60 or _fox.position.x > view.end.x + 60:
		_fox.visible = false


func _update_hoopoe(delta: float, view: Rect2) -> void:
	if not _hoopoe or not _hoopoe.visible:
		return
	_hoopoe_left -= delta
	if view.has_point(_hoopoe.position + Vector2(0, -6)):
		Game.discover("animal:hoopoe")
		Game.discover("sighting:hoopoe")
	if _hoopoe_left <= 0.0:
		_hoopoe.modulate.a = clampf(_hoopoe.modulate.a - delta / 0.6, 0.0, 1.0)
		if _hoopoe.modulate.a <= 0.0:
			_hoopoe.visible = false


func _update_white(delta: float, view: Rect2) -> void:
	if _white.is_empty():
		return
	_white["life"] = float(_white["life"]) - delta
	_white["pos"] += Vector2(16.0, sin(_t * 2.0) * 10.0) * delta
	_seen("sighting:white_butterfly", _white["pos"], view)
	if float(_white["life"]) <= 0.0:
		_white = {}


## Creatures that appear in view fade in over their first moments and out over their last, rather than popping.
## The rabbit under the pointer, if any, while it is still in plain sight.
func rabbit_at(point: Vector2) -> Dictionary:
	for r in _rabbits:
		if float(r.get("flee", 0.0)) <= 0.0 and float(r["life"]) > 0.6 and Rect2(r["pos"] + Vector2(-8, -18), Vector2(16, 18)).has_point(point):
			return r
	return {}


## Thumps a hind foot in alarm and bounds away from the click.
func startle(rabbit: Dictionary, from: Vector2) -> void:
	rabbit["dir"] = 1.0 if rabbit["pos"].x >= from.x else -1.0
	rabbit["flee"] = 1.5
	Sfx.play("thump", -2.0, 0.08)


func _fade(creature: Dictionary) -> float:
	var life := float(creature.get("life", 1.0))
	return clampf(float(creature.get("age", 1.0)) / 0.6, 0.0, 1.0) * clampf(life / 0.6, 0.0, 1.0)


func _seen(entry: String, pos: Vector2, view: Rect2) -> void:
	if view.has_point(pos) and not Game.journal.has(entry):
		Game.discover(entry)


func _view() -> Rect2:
	return get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()


func _draw() -> void:
	var dark := Color(0.2, 0.18, 0.26)
	for s in _swallows:
		var p: Vector2 = s["pos"].round()
		var up := fmod(_t * 6.0 + float(s["phase"]), 1.0) < 0.5
		for d in ([Vector2(-2, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, -1), Vector2(-1, 1), Vector2(-2, 2)] if up else [Vector2(-2, 1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 1), Vector2(-1, 1), Vector2(-2, 2)]):
			draw_rect(Rect2(p + d, Vector2.ONE), dark)
	for d in _dragonflies:
		var p: Vector2 = d["pos"].round()
		var a := _fade(d)
		draw_rect(Rect2(p, Vector2(4, 1)), Color(0.2, 0.55, 0.65, a))
		var wing := Color(0.9, 0.95, 1.0, (0.7 if fmod(_t * 20.0, 1.0) < 0.5 else 0.35) * a)
		draw_rect(Rect2(p + Vector2(1, -1), Vector2(1, 1)), wing)
		draw_rect(Rect2(p + Vector2(2, -1), Vector2(1, 1)), wing)
	for s in _snails:
		var p: Vector2 = s["pos"].round()
		var a := _fade(s)
		draw_rect(Rect2(p + Vector2(-1, -2), Vector2(3, 2)), Color(0.55, 0.4, 0.28, a))
		draw_rect(Rect2(p + Vector2(-2 if s["dir"] < 0 else 2, -1), Vector2(1, 1)), Color(0.7, 0.66, 0.55, a))
	if not _lizard.is_empty():
		var p: Vector2 = _lizard["pos"].round()
		var skin := Color(0.42, 0.5, 0.3, _fade(_lizard))
		draw_rect(Rect2(p, Vector2(5, 1)), skin)
		draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 1)), skin)
		draw_rect(Rect2(p + Vector2(3, -1), Vector2(1, 1)), skin)
	for r in _rabbits:
		var fleeing := float(r.get("flee", 0.0)) > 0.0
		# While fleeing each bound is a little arc, a quarter of a second long, landing between bounds.
		var bound := fmod(float(r.get("flee", 0.0)), 0.25) / 0.25
		var tex: Texture2D = (_rabbit_hop if bound > 0.2 else _rabbit_sit) if fleeing else (_rabbit_hop if float(r["hop"]) > 0.0 else _rabbit_sit)
		var lift := Vector2(0, -roundf(sin(bound * PI) * 4.0)) if fleeing else Vector2.ZERO
		if tex:
			draw_set_transform(r["pos"].round() + lift, 0.0, Vector2(float(r["dir"]), 1.0))
			draw_texture(tex, Vector2(-12, -22), Color(1, 1, 1, _fade(r)))
			draw_set_transform(Vector2.ZERO)
	if not _white.is_empty():
		var p: Vector2 = _white["pos"].round()
		var open := fmod(_t * 5.0, 1.0) < 0.5
		var c := Color(1, 1, 1)
		for d in ([Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-2, -1), Vector2(2, -1)] if open else [Vector2(0, -1), Vector2(0, -2)]):
			draw_rect(Rect2(p + d, Vector2.ONE), c)
		draw_rect(Rect2(p, Vector2.ONE), Color(0.3, 0.25, 0.25))
		if fmod(_t * 3.0, 1.0) < 0.3:
			draw_rect(Rect2(p + Vector2(3, 2), Vector2.ONE), Color(1, 1, 0.8, 0.8))
