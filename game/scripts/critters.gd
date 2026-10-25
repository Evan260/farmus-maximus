extends Node2D
## Butterflies, bees and passing birds, each drawn as a few pixels so the scene stays lively at almost no cost.

## Supplied by the scene: returns the top of every blooming plant, where butterflies and bees like to go.
var bloom_points: Callable = func() -> Array: return []

var _butterflies: Array = []
var _bees: Array = []
var _birds: Array = []
var _bird_timer := 6.0
var _t := 0.0


func _ready() -> void:
	var colours := [Color(1, 0.98, 0.92), Color(0.98, 0.85, 0.42), Color(0.84, 0.72, 1.0), Color(1, 0.98, 0.92)]
	for c in colours:
		_butterflies.append({"pos": Vector2(randf_range(20, 300), randf_range(190, 240)), "target": Vector2.ZERO, "color": c, "phase": randf() * 10.0})
	for i in 3:
		_bees.append({"pos": Vector2(randf_range(20, 300), randf_range(215, 250)), "target": Vector2.ZERO, "phase": randf() * 10.0})
	for b in _butterflies + _bees:
		b["target"] = _new_target(b["pos"])


func _process(delta: float) -> void:
	_t += delta
	var night := Lighting.night_amount(Game.day_time)
	for b in _butterflies:
		_steer(b, delta, 12.0, 4.0)
	for b in _bees:
		_steer(b, delta, 18.0, 1.5)
	_bird_timer -= delta
	if _bird_timer <= 0.0 and night < 0.5:
		_spawn_flock()
		_bird_timer = randf_range(25.0, 60.0)
	for bird in _birds:
		bird["pos"] += bird["vel"] * delta
	_birds = _birds.filter(func(bird): return bird["pos"].x > -20 and bird["pos"].x < 500)
	# Insects rest at night, so they fade out rather than flying in the dark.
	modulate.a = 1.0 - night * 0.9
	queue_redraw()


func _steer(b: Dictionary, delta: float, speed: float, wobble: float) -> void:
	b["phase"] += delta
	var to: Vector2 = b["target"] - b["pos"]
	if to.length() < 3.0:
		b["target"] = _new_target(b["pos"])
		return
	b["pos"] += to.normalized() * speed * delta + Vector2(0, sin(b["phase"] * 7.0) * wobble * delta * 4.0)


func _new_target(from: Vector2) -> Vector2:
	var points: Array = bloom_points.call()
	if not points.is_empty() and randf() < 0.75:
		return points[randi() % points.size()] + Vector2(randf_range(-6, 6), randf_range(-4, 2))
	return Vector2(clampf(from.x + randf_range(-80, 80), 10, 320), randf_range(190, 245))


func _spawn_flock() -> void:
	var left := randf() < 0.5
	var y := randf_range(30, 100)
	var speed := randf_range(26, 40) * (1.0 if left else -1.0)
	for i in randi_range(3, 6):
		_birds.append({"pos": Vector2(-10 - i * 9 if left else 490 + i * 9, y + randf_range(-6, 6)), "vel": Vector2(speed, randf_range(-1.5, 1.5)), "phase": randf() * 5.0})


func _draw() -> void:
	for b in _butterflies:
		var p: Vector2 = b["pos"].round()
		var c: Color = b["color"]
		if fmod(b["phase"] * 6.0, 1.0) < 0.5:
			for d in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0)]:
				draw_rect(Rect2(p + d, Vector2.ONE), c)
		else:
			draw_rect(Rect2(p + Vector2(0, -1), Vector2.ONE), c)
		draw_rect(Rect2(p, Vector2.ONE), Color(0.3, 0.22, 0.2))
	for b in _bees:
		var p: Vector2 = b["pos"].round()
		draw_rect(Rect2(p, Vector2.ONE), Color(0.95, 0.76, 0.2))
		draw_rect(Rect2(p + Vector2(1, 0), Vector2.ONE), Color(0.2, 0.15, 0.1))
		if fmod(b["phase"] * 12.0, 1.0) < 0.5:
			draw_rect(Rect2(p + Vector2(0, -1), Vector2.ONE), Color(1, 1, 1, 0.8))
	for bird in _birds:
		var p: Vector2 = bird["pos"].round()
		var up := fmod(_t * 3.0 + bird["phase"], 1.0) < 0.5
		var c := Color(0.27, 0.22, 0.3)
		for d in ([Vector2(-2, -1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, -1)] if up else [Vector2(-2, 1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 1)]):
			draw_rect(Rect2(p + d, Vector2.ONE), c)
