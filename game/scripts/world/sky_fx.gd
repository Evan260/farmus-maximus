extends Node2D
## Rare sights in the sky: a rainbow when rain clears in daylight, and shooting stars on clear nights.

## Supplied by the scene: whether the sky can be seen, which it cannot in the transparent desktop strip.
var sky_visible: Callable = func() -> bool: return true
const RAINBOW_SECONDS := 120.0
const RADIUS := 150.0
const WIDTH := 12.0
## The row where the bow's feet meet the distant hills.
const HORIZON := 200.0
## Seconds since the rainbow appeared, or below zero when there is none.
var _rainbow_age := -1.0
var _rainbow_x := 300.0
var _rainbow_tex: Texture2D
var _star := {}
var _star_timer := 60.0


func _ready() -> void:
	Game.weather_changed.connect(_on_weather_changed)


func _on_weather_changed(weather: String, before: String) -> void:
	var day := Lighting.night_amount(Game.day_time) < 0.3
	if before == "rain" and weather != "rain" and day and randf() < 0.5:
		_rainbow_age = 0.0
		_rainbow_x = randf_range(150, 600)
		_rainbow_tex = _paint_rainbow(randi())
		if sky_visible.call():
			Game.discover("sighting:rainbow")


## Starts a rainbow already this many seconds along, for screenshots.
func show_rainbow(age := 0.0) -> void:
	_rainbow_age = age
	_rainbow_tex = _paint_rainbow(randi())


func _process(delta: float) -> void:
	if _rainbow_age >= 0.0:
		_rainbow_age += delta
		if _rainbow_age > RAINBOW_SECONDS:
			_rainbow_age = -1.0
			_rainbow_tex = null
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
	if _rainbow_age >= 0.0 or not _star.is_empty():
		queue_redraw()


## Paints one rainbow: a soft spectrum from red outside to violet inside, patchy along its length, the sky a little
## lighter inside the bow, and a faint second bow outside with its colours the other way round.
func _paint_rainbow(seed: int) -> Texture2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var phase := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var size := Vector2i(int(RADIUS * 2 + 60), int(RADIUS + 40))
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var centre := Vector2(RADIUS + 30, RADIUS + 30)
	for y in size.y:
		for x in size.x:
			var off := Vector2(x, y) - centre
			var d := off.length()
			var angle := atan2(-off.y, off.x)
			if angle < 0.0:
				continue
			# Patches along the bow, different each time: some stretches bright, others nearly gone.
			var patch := clampf(0.55 + 0.3 * sin(angle * 3.1 + phase[0]) + 0.2 * sin(angle * 7.3 + phase[1]) + 0.12 * sin(angle * 13.0 + phase[2]), 0.0, 1.0)
			var c := Color(0, 0, 0, 0)
			var t := (RADIUS - d) / WIDTH
			if t >= 0.0 and t <= 1.0:
				c = _spectrum(t)
				c.a = sin(t * PI) * 0.34 * patch
			elif t > 1.0 and t < 3.5:
				c = Color(1, 1, 1, 0.05 * (1.0 - (t - 1.0) / 2.5) * patch)
			var t2 := (d - RADIUS - 14.0) / (WIDTH * 1.4)
			if t2 >= 0.0 and t2 <= 1.0:
				var second := _spectrum(1.0 - t2)
				second.a = sin(t2 * PI) * 0.09 * patch
				c = second if c.a == 0.0 else c
			if c.a > 0.0:
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _spectrum(t: float) -> Color:
	var stops := [Color(0.93, 0.32, 0.3), Color(0.98, 0.62, 0.3), Color(0.98, 0.9, 0.45), Color(0.45, 0.82, 0.48), Color(0.38, 0.58, 0.95), Color(0.55, 0.42, 0.85)]
	var at := clampf(t, 0.0, 1.0) * (stops.size() - 1)
	var i := mini(int(at), stops.size() - 2)
	return (stops[i] as Color).lerp(stops[i + 1], at - i)


func _draw() -> void:
	if _rainbow_tex:
		# It gathers slowly as the light comes through the last of the rain, and fades as the drops dry up.
		var shown := smoothstep(0.0, 10.0, _rainbow_age) * (1.0 - smoothstep(RAINBOW_SECONDS - 30.0, RAINBOW_SECONDS, _rainbow_age))
		draw_texture(_rainbow_tex, Vector2(_rainbow_x - RADIUS - 30, HORIZON - RADIUS - 30), Color(1, 1, 1, shown))
	if not _star.is_empty():
		var p: Vector2 = _star["pos"]
		for k in 6:
			draw_rect(Rect2((p - Vector2(5, 2) * k).round(), Vector2.ONE), Color(1, 1, 0.9, (1.0 - k / 6.0) * float(_star["life"])))
