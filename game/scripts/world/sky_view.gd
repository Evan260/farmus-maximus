extends Node2D
## The sky behind the estate: a banded gradient that follows the hour, the sun and moon crossing it, stars at night and
## clouds in three depths lit to match. Everything here is in the painting's pixels; the scene scales the node up.

const SkyFx := preload("res://scripts/world/sky_fx.gd")
const WIDTH := 768.0
const GRADIENT := preload("res://assets/shaders/sky_gradient.gdshader")
const CLOUD_TINT := preload("res://assets/shaders/cloud_tint.gdshader")
const AURORA := preload("res://assets/shaders/aurora.gdshader")
const MILKY_WAY := preload("res://assets/shaders/milky_way.gdshader")
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
var _aurora_clock := 0.0
## Set for screenshots: the lights show tonight whatever the dice say.
var force_aurora := false
## On for checking the Milky Way without waiting for a dark, clear night.
var force_galaxy := false
var _galaxy: Sprite2D
var _galaxy_amount := 0.0
var _galaxy_clock := 0.0
## "vertical" or "horizontal" to see one shape of the lights for checking; empty lets each night choose.
var aurora_shape := ""
## Each evening's rolls for the northern lights, their shape and the Milky Way, made once that evening.
var _rolls_evening := 0
var _rolled := false
var _aurora_roll := 0.0
var _shape_roll := 0.0
var _galaxy_roll := 0.0


func _ready() -> void:
	_gradient = Sprite2D.new()
	_gradient.texture = _solid(Color.WHITE)
	_gradient.centered = false
	# The sky reaches far above the hills, so a tall window shows more sky rather than an empty band.
	_gradient.position = Vector2(0, -1600)
	_gradient.scale = Vector2(WIDTH * 2, 1600 + HORIZON + 80)
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
	_galaxy = Sprite2D.new()
	_galaxy.texture = _gradient.texture
	_galaxy.centered = false
	_galaxy.position = Vector2(0, -120)
	_galaxy.scale = Vector2(WIDTH * 2, 120 + HORIZON)
	var stars := ShaderMaterial.new()
	stars.shader = MILKY_WAY
	stars.set_shader_parameter("area", _galaxy.scale)
	stars.set_shader_parameter("origin", _galaxy.position)
	stars.set_shader_parameter("horizon", HORIZON)
	_galaxy.material = stars
	_galaxy.visible = false
	add_child(_galaxy)
	_sun = Sprite2D.new()
	_sun.texture = _disc(9)
	add_child(_sun)
	_night = Node2D.new()
	add_child(_night)
	_moon_glow = Sprite2D.new()
	_moon_glow.texture = _moon_rings()
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


## The moon's light in the night air: a bright glow close round it, a wider soft halo, and a faint ring further out,
## in steps like the sky's bands.
func _moon_rings() -> ImageTexture:
	var size := 140
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0 - 0.5, size / 2.0 - 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(c)
			var a := 0.0
			if d < 30.0:
				a = 0.11
			elif d < 40.0:
				a = 0.07
			elif d < 52.0:
				a = 0.04
			if d >= 60.0 and d < 63.0:
				a = 0.06
			elif d >= 52.0 and d < 69.0:
				a = maxf(a, 0.02)
			if a > 0.0:
				img.set_pixel(x, y, Color(0.85, 0.87, 1.0, a))
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
	SkyPalette.paint(_gradient.material as ShaderMaterial, _sun, _cloud_look, hour, overcast, WIDTH, HORIZON, 170.0, Vector2(230, 130), _t)
	var night := Lighting.night_amount(hour)
	_night.modulate.a = night
	# Sleeping fast-forwards the night, and the clouds hurry across with it.
	var wind := (1.8 if overcast else 1.0) * (0.3 if Settings.reduced_motion else 1.0) * minf(Game.speed, 30.0)
	for c in _clouds:
		var s: Sprite2D = c["sprite"]
		s.position.x += float(c["speed"]) * wind * delta
		s.position.y = float(c["base_y"]) + float(c["lift"]) * sin(_t * TAU / float(c["period"]) + float(c["phase"])) * (0.3 if Settings.reduced_motion else 1.0)
		# Carrying on from the left by the overshoot keeps the clouds spread out even after one very long frame.
		if s.position.x > WIDTH * 2:
			s.position.x = fposmod(s.position.x + s.texture.get_width(), WIDTH * 2 + s.texture.get_width()) - s.texture.get_width()
		var shown := float(c["alpha"]) if overcast or not c["grey_only"] else 0.0
		s.modulate.a = move_toward(s.modulate.a, shown, delta * 0.2)
	_place_moon()
	_show_galaxy(delta, night, _show_aurora(delta, night))


## The northern lights are rare this far south: on about one clear night in fourteen they ripple over the hills for
## the darkest hours, fading in after dusk and away before dawn.
## Returns whether tonight is a night for the lights, so the Milky Way keeps to other nights.
func _show_aurora(delta: float, night: float) -> bool:
	var evening: int = Game.calendar.day - (1 if Game.day_time < 12.0 else 0)
	_roll(evening)
	# Nobody should miss the lights by bad luck alone: after enough days without them, every clear night has them.
	var overdue: bool = evening >= int(Data.get_value("calendar.aurora_sure_after_days", 30)) and not Game.journal.has("sighting:aurora")
	var tonight := force_aurora or overdue or _aurora_roll < float(Data.get_value("calendar.aurora_chance", 0.07))
	var rising := _shape_roll < 0.5 if aurora_shape == "" else aurora_shape == "vertical"
	var clear: bool = Game.calendar.weather == "sun"
	var target := smoothstep(0.75, 1.0, night) if tonight and clear else 0.0
	# Sleeping fast-forwards the night, and the lights with it, though never so fast that they flicker.
	var pace := minf(Game.speed, 40.0) * (0.3 if Settings.reduced_motion else 1.0)
	_aurora_clock += delta * pace
	_aurora_amount = target if force_aurora else move_toward(_aurora_amount, target, delta * minf(Game.speed, 40.0) / 20.0)
	_aurora.visible = _aurora_amount > 0.01
	if _aurora.visible:
		var lights := _aurora.material as ShaderMaterial
		lights.set_shader_parameter("amount", _aurora_amount)
		lights.set_shader_parameter("clock", _aurora_clock)
		lights.set_shader_parameter("rising", 1.0 if rising else 0.0)
		if _aurora_amount > 0.5 and sky_visible.call():
			Game.discover("sighting:aurora")
	return tonight and not force_galaxy


func _roll(evening: int) -> void:
	if _rolled and evening == _rolls_evening:
		return
	_rolled = true
	_rolls_evening = evening
	var rng := RandomNumberGenerator.new()
	rng.seed = evening * 7717 + 13
	_aurora_roll = rng.randf()
	_shape_roll = rng.randf()
	rng.seed = evening * 3191 + 7
	_galaxy_roll = rng.randf()


## On a clear night near the new moon the Milky Way can be seen arching over the farm, as it can far from any town.
## About half of those dark nights show it; a player who has never seen it gets it on the first dark night after a
## few weeks, so nobody misses it by bad luck.
func _show_galaxy(delta: float, night: float, aurora_tonight: bool) -> void:
	var evening: int = Game.calendar.day - (1 if Game.day_time < 12.0 else 0)
	_roll(evening)
	var dark := _lit_share(posmod(evening, MOON_CYCLE)) <= 0.3
	var overdue: bool = evening >= int(Data.get_value("calendar.milky_way_sure_after_days", 20)) and not Game.journal.has("sighting:milky_way")
	var chance := float(Data.get_value("calendar.milky_way_chance", 0.5))
	var tonight := force_galaxy or (dark and not aurora_tonight and (overdue or _galaxy_roll < chance))
	var target := smoothstep(0.8, 1.0, night) if tonight and Game.calendar.weather == "sun" else 0.0
	_galaxy_clock += delta
	_galaxy_amount = target if force_galaxy else move_toward(_galaxy_amount, target, delta * minf(Game.speed, 40.0) / 20.0)
	_galaxy.visible = _galaxy_amount > 0.01
	if _galaxy.visible:
		var stars := _galaxy.material as ShaderMaterial
		stars.set_shader_parameter("amount", _galaxy_amount)
		stars.set_shader_parameter("clock", _galaxy_clock)
		if _galaxy_amount > 0.5 and sky_visible.call():
			Game.discover("sighting:milky_way")


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
