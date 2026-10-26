extends Node2D
## The decorations the player has bought, each on its own spot on the estate; lanterns glow at night and the fountain plays.

const DIR := "res://assets/sprites/decorations/"

## Supplied by the scene: the layer for lamp light, which the night tint does not darken.
var glow_layer: Node
var _shown := {}


func _ready() -> void:
	Game.decoration_bought.connect(func(_id): _sync())
	_sync()


func _process(_delta: float) -> void:
	var night := Lighting.night_amount(Game.day_time)
	for id in _shown:
		var lamp: Lamp = _shown[id].get("glow")
		if lamp:
			lamp.shine(night)


## The middle of the lamp's flame: the bright yellow pixels of the picture, relative to its used rectangle.
func _flame(img: Image, used: Rect2i) -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for y in range(used.position.y, used.end.y):
		for x in range(used.position.x, used.end.x):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.r > 0.85 and c.g > 0.62 and c.b < c.g:
				sum += Vector2(x, y)
				count += 1
	if count == 0:
		return Vector2(used.size.x / 2.0, 6)
	return sum / count - Vector2(used.position) + Vector2(0.5, 0.5)


func _sync() -> void:
	for id in Game.decorations:
		if _shown.has(id) or not ResourceLoader.exists(DIR + id + ".png"):
			continue
		var d: Dictionary = Game.decoration_info(id)
		var tex: Texture2D = load(DIR + id + ".png")
		var used := tex.get_image().get_used_rect()
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.region_enabled = true
		s.region_rect = used
		var base := Vector2(float(d.get("x", 0)), float(d.get("y", 236)))
		if d.get("flat", false):
			# A floor mosaic lies flat in the path, so it is squashed to read as seen from the side.
			s.scale = Vector2(1, 0.4)
			s.position = base - Vector2(used.size.x / 2.0, used.size.y * 0.4)
		else:
			s.position = base - Vector2(roundf(used.size.x / 2.0), used.size.y)
			var shadow := Sprite2D.new()
			shadow.texture = Lighting.ellipse_texture(int(used.size.x) + 4, 4, Color(0.16, 0.11, 0.12, 0.25))
			shadow.centered = false
			shadow.position = base - Vector2(used.size.x / 2.0 + 2, 3)
			add_child(shadow)
		add_child(s)
		var entry := {"sprite": s}
		if d.get("glow", false) and glow_layer:
			var lamp := Lamp.new()
			lamp.position = s.position + _flame(tex.get_image(), used)
			lamp.radius = 46.0
			lamp.power = 1.1
			lamp.halo_layer = glow_layer
			lamp.halo_size = 9.0
			add_child(lamp)
			entry["glow"] = lamp
		if d.get("water", false):
			var p := CPUParticles2D.new()
			p.position = base + Vector2(0, -used.size.y + 4)
			p.amount = 16
			p.lifetime = 0.8
			p.direction = Vector2.UP
			p.spread = 15.0
			p.initial_velocity_min = 14.0
			p.initial_velocity_max = 20.0
			p.gravity = Vector2(0, 50)
			p.color = Color(0.75, 0.88, 1.0, 0.85)
			p.emitting = not Settings.reduced_motion
			add_child(p)
		_shown[id] = entry
