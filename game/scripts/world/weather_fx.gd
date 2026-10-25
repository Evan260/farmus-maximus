extends Node2D
## Weather on the ground: puddles after rain, drifting cloud shadows on sunny days and dew on the plants in the morning.

## Supplied by the scene: the top of every plant, where dew settles.
var plant_tops: Callable = func() -> Array: return []
var _puddles: Array = []
var _shadows: Array = []
var _wet := 0.0
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 40:
		_puddles.append(Rect2(rng.randf_range(0, 2400), rng.randf_range(252, 268), rng.randi_range(8, 18), rng.randi_range(2, 3)))
	for i in 6:
		var w := rng.randi_range(90, 180)
		_shadows.append({"x": rng.randf_range(0, 2400), "w": w, "speed": rng.randf_range(3, 6), "tex": _shadow_texture(w)})


## A cloud's shadow: a soft, even shade that fades out at its edges, drawn once and then only moved.
func _shadow_texture(w: int) -> ImageTexture:
	var img := Image.create(w, 42, false, Image.FORMAT_RGBA8)
	for y in 42:
		for x in w:
			var d := pow((x - w / 2.0) / (w / 2.0), 2) + pow((y - 21.0) / 21.0, 2)
			if d < 1.0:
				img.set_pixel(x, y, Color(0.1, 0.08, 0.14, 0.11 * smoothstep(1.0, 0.4, d)))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	_wet = move_toward(_wet, 1.0 if Game.calendar.wet() else 0.0, delta / 20.0)
	for s in _shadows:
		s["x"] = fposmod(float(s["x"]) + float(s["speed"]) * delta, 2600.0) - 100.0
	queue_redraw()


func _draw() -> void:
	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	if Game.calendar.weather == "sun" and Lighting.night_amount(Game.day_time) < 0.3:
		for s in _shadows:
			var x0 := int(s["x"]) - int(s["w"]) / 2
			if x0 + int(s["w"]) >= view.position.x and x0 <= view.end.x:
				draw_texture(s["tex"], Vector2(x0, 228))
	if _wet > 0.01:
		var sky := Lighting.color_at(Game.day_time)
		for p in _puddles:
			if p.end.x < view.position.x or p.position.x > view.end.x:
				continue
			draw_rect(p, Color(sky.r * 0.55, sky.g * 0.62, sky.b * 0.75, 0.55 * _wet))
			draw_rect(Rect2(p.position + Vector2(2, 0), Vector2(p.size.x * 0.4, 1)), Color(1, 1, 1, 0.25 * _wet))
	if Game.day_time >= 5.0 and Game.day_time < 8.5:
		var fade := clampf(1.0 - (Game.day_time - 7.0) / 1.5, 0.0, 1.0)
		for top in plant_tops.call():
			var p: Vector2 = top
			if fmod(_t * 0.8 + p.x * 0.13, 2.0) < 0.6:
				draw_rect(Rect2(p + Vector2(int(p.x) % 7 - 3, 4), Vector2.ONE), Color(1, 1, 1, 0.9 * fade))
