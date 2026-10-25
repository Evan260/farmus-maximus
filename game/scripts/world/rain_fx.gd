extends Node2D
## Rain and morning mist, drawn over the whole view on their own layer so they stay put while the estate pans.

var _drops: Array = []
var _rain := 0.0
var _mist := 0.0
var _t := 0.0


func _ready() -> void:
	for i in 140:
		_drops.append(Vector2(randf_range(0, 520), randf_range(0, 270)))


func _process(delta: float) -> void:
	_t += delta
	_rain = move_toward(_rain, 1.0 if Game.calendar.raining() else 0.0, delta / 4.0)
	_mist = move_toward(_mist, 1.0 if Game.calendar.weather == "mist" else 0.0, delta / 8.0)
	var size := get_viewport_rect().size
	var fall := Vector2(-18, 150) * (0.3 if Settings.reduced_motion else 1.0)
	for i in _drops.size():
		var d: Vector2 = _drops[i] + fall * delta
		if d.y > size.y:
			d = Vector2(randf_range(0, size.x + 40), -4)
		_drops[i] = d
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	if _rain > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.4, 0.5, 0.12 * _rain))
		var shown := int(_drops.size() * _rain)
		for i in shown:
			var d: Vector2 = _drops[i].round()
			# Each drop is a short slanted streak of single pixels, which stays crisp at any scale.
			var c := Color(0.85, 0.9, 1.0, 0.45)
			draw_rect(Rect2(d, Vector2(1, 2)), c)
			draw_rect(Rect2(d + Vector2(-1, 2), Vector2(1, 2)), c)
	if _mist > 0.01:
		for band in 5:
			var y := size.y - 70 + band * 12 + sin(_t * 0.2 + band) * 3.0
			var drift := fmod(_t * (3.0 + band), 64.0)
			for x in range(-64, int(size.x) + 64, 32):
				draw_rect(Rect2(x + drift, y, 40, 10), Color(0.95, 0.94, 0.98, 0.07 * _mist))
