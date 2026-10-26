extends Node2D
## The sky behind the estate: a banded gradient that follows the hour, the sun and moon crossing it, stars at night and
## clouds in three depths lit to match. Everything here is in the painting's pixels; the scene scales the node up.

const SkyFx := preload("res://scripts/world/sky_fx.gd")
const WIDTH := 768.0
const GRADIENT := preload("res://assets/shaders/sky_gradient.gdshader")
const CLOUD_TINT := preload("res://assets/shaders/cloud_tint.gdshader")
const AURORA := preload("res://assets/shaders/aurora.gdshader")
const CLOUDS := "res://assets/backgrounds/sky_clouds/"
## The row where the sky meets the distant hills.
const HORIZON := 205.0
## The moon goes from new to full and back over this many nights.
const MOON_CYCLE := 8
const MOON_R := 20
const MOON_LIGHT := Color8(241, 237, 204)
const MOON_SEA := Color8(220, 215, 186)
## The dark part of the moon still shows faintly against the sky, lit by the earth.
const MOON_DARK := Color(0.55, 0.57, 0.72, 0.13)

## Supplied by the scene: whether the sky can be seen, which it cannot in the transparent desktop strip.
var sky_visible: Callable = func() -> bool: return true
## Rainbows and shooting stars.
var fx: Node2D
var _gradient: Sprite2D
var _sun: Sprite2D
var _night: Node2D
var _clouds: Array = []
var _cloud_look: ShaderMaterial
var _moon: Sprite2D
var _moon_glow: Sprite2D
var _moon_phases: Array[Texture2D] = []
var _moon_phase := -1
var _t := 0.0
var _aurora: Sprite2D
## How strongly the northern lights show right now, easing in and out.
var _aurora_amount := 0.0
## Set for screenshots: the lights show tonight whatever the dice say.
var force_aurora := false


func _ready() -> void:
	_gradient = Sprite2D.new()
	_gradient.texture = _solid(Color.WHITE)
	_gradient.centered = false
	_gradient.position = Vector2(0, -400)
	_gradient.scale = Vector2(WIDTH * 2, 400 + HORIZON + 80)
	var paint := ShaderMaterial.new()
	paint.shader = GRADIENT
	paint.set_shader_parameter("area", _gradient.scale)
	paint.set_shader_parameter("origin", _gradient.position)
	paint.set_shader_parameter("horizon", HORIZON)
	_gradient.material = paint
	add_child(_gradient)
	_aurora = Sprite2D.new()
	_aurora.texture = _gradient.texture
	_aurora.centered = false
	_aurora.position = Vector2(0, -120)
	_aurora.scale = Vector2(WIDTH * 2, 120 + HORIZON)
	var lights := ShaderMaterial.new()
	lights.shader = AURORA
	lights.set_shader_parameter("area", _aurora.scale)
	lights.set_shader_parameter("origin", _aurora.position)
	_aurora.material = lights
	_aurora.visible = false
	add_child(_aurora)
	_sun = Sprite2D.new()
	_sun.texture = _disc(9)
	add_child(_sun)
	_night = Node2D.new()
	add_child(_night)
	_moon_glow = Sprite2D.new()
	_moon_glow.texture = Lighting.ellipse_texture(64, 64, Color(0.85, 0.85, 1.0, 0.07))
	_night.add_child(_moon_glow)
	_moon = Sprite2D.new()
	for phase in MOON_CYCLE:
		_moon_phases.append(_moon_texture(phase))
	_night.add_child(_moon)
	_cloud_look = ShaderMaterial.new()
	_cloud_look.shader = CLOUD_TINT
	_scatter_clouds()
	fx = SkyFx.new()
	fx.sky_visible = sky_visible
	add_child(fx)


func _solid(c: Color) -> ImageTexture:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, c)
	return ImageTexture.create_from_image(img)


## The sun's face: a round disc with a paler rim, coloured by the hour.
func _disc(r: int) -> ImageTexture:
	var size := r * 2 + 1
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := Vector2(x - r, y - r).length()
			if d <= r + 0.3:
				img.set_pixel(x, y, Color(1, 1, 1) if d < r - 1.2 else Color(1, 1, 1, 0.75))
	return ImageTexture.create_from_image(img)


## Clouds in three depths across the whole sky: small faint ones low and far away drifting slowly, big ones high and
## near drifting faster. The same seed lays them out every time.
func _scatter_clouds() -> void:
	var textures: Array[Texture2D] = []
	var i := 0
	while ResourceLoader.exists("%scloud_%d.png" % [CLOUDS, i]):
		textures.append(load("%scloud_%d.png" % [CLOUDS, i]))
		i += 1
	if textures.is_empty():
		return
	var by_size := textures.duplicate()
	by_size.sort_custom(func(a, b): return a.get_width() < b.get_width())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for layer in [{"count": 6, "y": Vector2(118, 160), "speed": 0.5, "alpha": 0.7, "pick": 0.0},
			{"count": 6, "y": Vector2(62, 118), "speed": 1.0, "alpha": 0.9, "pick": 0.4},
			{"count": 5, "y": Vector2(-6, 60), "speed": 1.7, "alpha": 1.0, "pick": 0.65}]:
		for k in int(layer["count"]):
			var from := int(float(layer["pick"]) * by_size.size())
			var tex: Texture2D = by_size[rng.randi_range(from, mini(by_size.size() - 1, from + 2))]
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.flip_h = rng.randf() < 0.5
			s.material = _cloud_look
			s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			s.position = Vector2((k + rng.randf_range(0.0, 0.8)) * WIDTH * 2 / int(layer["count"]), rng.randf_range(layer["y"].x, layer["y"].y))
			add_child(s)
			# Every third cloud only shows on grey days, so a fine day has open sky between its clouds.
			# Each cloud also rises and sinks a little over a few minutes, as real ones seem to while they drift.
			_clouds.append({"sprite": s, "speed": float(layer["speed"]) * rng.randf_range(0.7, 1.35), "alpha": float(layer["alpha"]), "grey_only": _clouds.size() % 3 == 2,
				"base_y": s.position.y, "lift": rng.randf_range(2.0, 10.0), "period": rng.randf_range(80.0, 220.0), "phase": rng.randf() * TAU})
			var grey_only: bool = _clouds[-1]["grey_only"]
			s.modulate.a = float(layer["alpha"]) if Game.calendar.weather in ["cloudy", "rain"] or not grey_only else 0.0


func _process(delta: float) -> void:
	_t += delta
	var hour := Game.day_time
	var overcast: bool = Game.calendar.weather in ["cloudy", "rain"]
	var look := SkyPalette.at(hour, overcast)
	var paint := _gradient.material as ShaderMaterial
	for key in ["zenith", "middle", "glow"]:
		paint.set_shader_parameter(key, look[key])
	paint.set_shader_parameter("low", look["low"])
	var sun := SkyPalette.sun_position(hour, WIDTH, HORIZON, 170.0)
	_sun.visible = not is_nan(sun.x)
	if _sun.visible:
		_sun.position = sun.round()
		var height := clampf((HORIZON - sun.y) / 170.0, 0.0, 1.0)
		_sun.modulate = Color(1.0, 0.72, 0.45).lerp(Color(1.0, 0.98, 0.9), height) * Color(1, 1, 1, 0.5 if overcast else 1.0)
		paint.set_shader_parameter("sun", sun)
		paint.set_shader_parameter("glow_radius", lerpf(230.0, 130.0, height))
	var night := Lighting.night_amount(hour)
	paint.set_shader_parameter("stars", night * (0.3 if overcast else 1.0))
	paint.set_shader_parameter("time", _t)
	_night.modulate.a = night
	_cloud_look.set_shader_parameter("light", look["light"])
	_cloud_look.set_shader_parameter("shade", look["shade"])
	var wind := (1.8 if overcast else 1.0) * (0.3 if Settings.reduced_motion else 1.0)
	for c in _clouds:
		var s: Sprite2D = c["sprite"]
		s.position.x += float(c["speed"]) * wind * delta
		s.position.y = float(c["base_y"]) + float(c["lift"]) * sin(_t * TAU / float(c["period"]) + float(c["phase"])) * (0.3 if Settings.reduced_motion else 1.0)
		if s.position.x > WIDTH * 2:
			s.position.x = -s.texture.get_width()
		var shown := float(c["alpha"]) if overcast or not c["grey_only"] else 0.0
		s.modulate.a = move_toward(s.modulate.a, shown, delta * 0.2)
	_place_moon()
	_show_aurora(delta, night)


## The northern lights are rare this far south: on about one clear night in fourteen they ripple over the hills for
## the darkest hours, fading in after dusk and away before dawn.
func _show_aurora(delta: float, night: float) -> void:
	var evening: int = Game.calendar.day - (1 if Game.day_time < 12.0 else 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = evening * 7717 + 13
	var tonight := force_aurora or rng.randf() < float(Balance.get_value("calendar.aurora_chance", 0.07))
	var clear: bool = Game.calendar.weather == "sun"
	var target := smoothstep(0.75, 1.0, night) if tonight and clear else 0.0
	_aurora_amount = target if force_aurora else move_toward(_aurora_amount, target, delta / 20.0)
	_aurora.visible = _aurora_amount > 0.01
	if _aurora.visible:
		var lights := _aurora.material as ShaderMaterial
		lights.set_shader_parameter("amount", _aurora_amount)
		lights.set_shader_parameter("motion", 0.3 if Settings.reduced_motion else 1.0)
		if _aurora_amount > 0.5 and sky_visible.call():
			Game.discover("sighting:aurora")


## The moon rises on the left at dusk, climbs in an arc and sets on the right at dawn, like the real one seen facing south.
func _place_moon() -> void:
	var hour := Game.day_time
	var t := fposmod(hour - 19.0, 24.0) / 11.0
	_moon.visible = t <= 1.0
	_moon_glow.visible = _moon.visible
	if not _moon.visible:
		return
	_moon.position = Vector2(lerpf(40.0, 700.0, t), 150.0 - sin(t * PI) * 120.0)
	_moon_glow.position = _moon.position
	# After midnight it is still the moon that rose the evening before.
	var night: int = Game.calendar.day - (1 if hour < 12.0 else 0)
	var phase := posmod(night, MOON_CYCLE)
	if phase != _moon_phase:
		_moon_phase = phase
		_moon.texture = _moon_phases[phase]
		_moon_glow.modulate.a = 0.2 + 0.8 * _lit_share(phase)


## How much of the moon's face is lit, from 0 at new moon to 1 at full.
func _lit_share(phase: int) -> float:
	return (1.0 - cos(TAU * phase / MOON_CYCLE)) / 2.0


## The moon on one night of its cycle: lit from the right while it grows towards full, from the left as it wanes.
func _moon_texture(phase: int) -> Texture2D:
	var size := MOON_R * 2 + 1
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var turn := cos(TAU * phase / MOON_CYCLE)
	var seas := [Vector3(-6, -5, 4.5), Vector3(4, -8, 3.0), Vector3(5, 4, 5.0), Vector3(-4, 8, 3.0), Vector3(-9, 2, 2.5)]
	for y in size:
		for x in size:
			var u := (x - MOON_R) / float(MOON_R)
			var v := (y - MOON_R) / float(MOON_R)
			if u * u + v * v > 1.0:
				continue
			var w := sqrt(1.0 - v * v)
			var lit := u > w * turn if phase * 2 <= MOON_CYCLE else u < -w * turn
			if phase == 0:
				lit = false
			if not lit:
				img.set_pixel(x, y, MOON_DARK)
				continue
			var c := MOON_LIGHT
			for sea in seas:
				if Vector2(x - MOON_R - sea.x, y - MOON_R - sea.y).length() < sea.z:
					c = MOON_SEA
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
