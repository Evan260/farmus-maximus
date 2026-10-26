extends Node2D
## The sky behind the estate, drawn at the screen's full resolution so clouds and the moon glide rather than step a pixel at a time.
## Everything here is in the painting's pixels; the node is scaled up to the screen by the scene.

const SkyFx := preload("res://scripts/world/sky_fx.gd")
const DIR := "res://assets/backgrounds/estate/"
const WIDTH := 768.0
const SMOOTH := preload("res://assets/shaders/smooth_pixels.gdshader")
## The moon goes from new to full and back over this many nights.
const MOON_CYCLE := 8
const MOON_R := 20
const MOON_LIGHT := Color8(241, 237, 204)
const MOON_SEA := Color8(220, 215, 186)
## The dark part of the moon still shows faintly against the sky, lit by the earth.
const MOON_DARK := Color(0.55, 0.57, 0.72, 0.13)

## Supplied by the scene: whether the sky can be seen, which it cannot in the transparent desktop strip.
var sky_visible: Callable = func() -> bool: return true
var _day: Node2D
var _night: Node2D
var _clouds: Array = []
var _moon: Sprite2D
var _moon_glow: Sprite2D
var _moon_phases: Array[Texture2D] = []
var _moon_phase := -1


func _ready() -> void:
	# The whole sky glides by fractions of a screen pixel, so slow clouds drift smoothly instead of stepping.
	var smooth := ShaderMaterial.new()
	smooth.shader = SMOOTH
	material = smooth
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_night = Node2D.new()
	_day = Node2D.new()
	_night.use_parent_material = true
	_day.use_parent_material = true
	add_child(_night)
	add_child(_day)
	_base(_day, DIR + "sky_day/base.png")
	_base(_night, DIR + "sky_night/base.png")
	_moon_glow = Sprite2D.new()
	_moon_glow.texture = Lighting.ellipse_texture(64, 64, Color(0.85, 0.85, 1.0, 0.07))
	_moon_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_night.add_child(_moon_glow)
	_moon = Sprite2D.new()
	for phase in MOON_CYCLE:
		_moon_phases.append(_moon_texture(phase))
	_moon.use_parent_material = true
	_night.add_child(_moon)
	_load_clouds(_night, DIR + "sky_night/", 0.6)
	_load_clouds(_day, DIR + "sky_day/", 1.0)
	var fx := SkyFx.new()
	fx.sky_visible = sky_visible
	add_child(fx)


## The sky's base, plus a mirrored copy to its right so a very wide window never runs out of sky.
func _base(parent: Node2D, path: String) -> void:
	var tex: Texture2D = load(path)
	for k in 2:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position.x = WIDTH * k
		s.flip_h = k == 1
		s.use_parent_material = true
		parent.add_child(s)
	var top := tex.get_image().get_pixel(0, 0)
	# Above the painting, the sky simply carries on in its top colour, for windows taller than the painting.
	var above := Sprite2D.new()
	above.texture = _solid(top)
	above.centered = false
	above.scale = Vector2(WIDTH * 2, 400)
	above.position = Vector2(0, -400)
	parent.add_child(above)


func _solid(c: Color) -> ImageTexture:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, c)
	return ImageTexture.create_from_image(img)


func _load_clouds(parent: Node2D, dir: String, pace: float) -> void:
	var list: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + "clouds.json"))
	if typeof(list) != TYPE_ARRAY:
		return
	for c in list:
		var s := Sprite2D.new()
		s.texture = load(dir + String(c["file"]))
		s.centered = false
		s.position = Vector2(float(c["x"]), float(c["y"]))
		s.use_parent_material = true
		parent.add_child(s)
		# Higher clouds drift a little faster than the ones low on the horizon, which reads as depth.
		var height := 1.0 - clampf(float(c["y"]) / 150.0, 0.0, 1.0)
		_clouds.append({"sprite": s, "speed": pace * (0.6 + height * 1.6) * randf_range(0.8, 1.2)})


func _process(delta: float) -> void:
	var night := Lighting.night_amount(Game.day_time)
	var light := Lighting.color_at(Game.day_time)
	if Game.calendar.weather in ["cloudy", "rain"]:
		light = light.darkened(0.15)
	_day.modulate = Color(light, 1.0 - night)
	_night.modulate.a = night
	var wind := (1.8 if Game.calendar.weather in ["rain", "cloudy"] else 1.0) * (0.3 if Settings.reduced_motion else 1.0)
	for c in _clouds:
		var s: Sprite2D = c["sprite"]
		s.position.x += float(c["speed"]) * wind * delta
		if s.position.x > WIDTH * 2:
			s.position.x = -s.texture.get_width()
	_place_moon()


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
