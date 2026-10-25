extends Node2D
## Rare sights in the sky: a rainbow when rain clears in daylight, and shooting stars on clear nights.

## Supplied by the scene: whether the sky can be seen, which it cannot in the transparent desktop strip.
var sky_visible: Callable = func() -> bool: return true
var _rainbow := 0.0
var _rainbow_x := 300.0
var _star := {}
var _star_timer := 60.0


func _ready() -> void:
	Game.weather_changed.connect(_on_weather_changed)


func _on_weather_changed(weather: String, before: String) -> void:
	var day := Lighting.night_amount(Game.day_time) < 0.3
	if before == "rain" and weather != "rain" and day and randf() < 0.5:
		_rainbow = 1.0
		_rainbow_x = randf_range(150, 600)
		if sky_visible.call():
			Game.discover("sighting:rainbow")


func _process(delta: float) -> void:
	_rainbow = maxf(0.0, _rainbow - delta / 90.0)
	var night := Lighting.night_amount(Game.day_time)
	if night > 0.8 and Game.calendar.weather == "sun":
		_star_timer -= delta
		if _star_timer <= 0.0:
			_star_timer = randf_range(60.0, 180.0)
			_star = {"pos": Vector2(randf_range(100, 700), randf_range(10, 60)), "life": 0.8}
			if sky_visible.call():
				Game.discover("sighting:shooting_star")
	if not _star.is_empty():
		_star["life"] = float(_star["life"]) - delta
		_star["pos"] += Vector2(140, 55) * delta
		if _star["life"] <= 0.0:
			_star = {}
	if _rainbow > 0.0 or not _star.is_empty():
		queue_redraw()


func _draw() -> void:
	if _rainbow > 0.0:
		var colours := [Color(0.9, 0.35, 0.35), Color(0.95, 0.65, 0.3), Color(0.95, 0.9, 0.4), Color(0.45, 0.8, 0.45), Color(0.4, 0.6, 0.95), Color(0.6, 0.45, 0.85)]
		var a := minf(1.0, _rainbow * 3.0) * 0.35
		for i in colours.size():
			draw_arc(Vector2(_rainbow_x, 170), 120 - i * 2, PI, TAU, 64, Color(colours[i], a), 2.0)
	if not _star.is_empty():
		var p: Vector2 = _star["pos"]
		for k in 6:
			draw_rect(Rect2((p - Vector2(5, 2) * k).round(), Vector2.ONE), Color(1, 1, 0.9, (1.0 - k / 6.0) * float(_star["life"])))
