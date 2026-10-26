extends Node2D
## One estate building on screen: its ruin, scaffolding or working look, a shadow, and a progress bar while it works.

const DIR := "res://assets/sprites/buildings/"
const Scaffold := preload("res://scripts/world/scaffold.gd")

var id := ""
var hovered := false
var _sprite: Sprite2D
var _shadow: Sprite2D
var _look := ""
var _scaffold: Node2D
## The working picture's loop, for buildings whose machinery moves while they make something.
var _frames: Array[Texture2D] = []
var _still: Texture2D
var _clock := 0.0
## The fire's light, for a building such as the bakery whose oven glows while it bakes.
var _lamp: Lamp


func _ready() -> void:
	_shadow = Sprite2D.new()
	_shadow.centered = false
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.region_enabled = true
	add_child(_sprite)
	_scaffold = Scaffold.new()
	_scaffold.ladders = Game.building_info(id).get("ladders", [])
	_scaffold.visible = false
	add_child(_scaffold)
	Game.building_changed.connect(func(changed): if changed == id: _refresh())
	_refresh()


func _process(delta: float) -> void:
	_animate(delta)
	var zone := String(Game.building_info(id).get("zone", "home"))
	modulate = Color.WHITE if Game.zone_owned(zone) else Color(0.62, 0.6, 0.58)
	if _look != _look_for_state():
		_refresh()
	queue_redraw()


func _draw() -> void:
	var r := local_rect()
	if hovered:
		UiKit.outline(self, r, Color(1, 0.96, 0.85, 0.7))
	var b: Dictionary = Game.buildings[id]
	var bar := Rect2(Vector2(r.position.x + r.size.x / 2 - 12, r.position.y - 5), Vector2(24, 3))
	var fill := -1.0
	if b["state"] == "repairing":
		fill = 1.0 - float(b["time_left"]) / float(Game.building_info(id).get("repair_seconds", 30))
	elif b["state"] == "upgrading":
		fill = 1.0 - float(b["time_left"]) / Game.building_upgrade_seconds(id)
	elif b["state"] == "working" and b["busy"]:
		fill = float(b["progress"]) / float(Game.building_info(id).get("seconds", 30))
	if fill >= 0.0:
		draw_rect(bar, Color(0.2, 0.14, 0.12, 0.8))
		draw_rect(Rect2(bar.position + Vector2.ONE, Vector2(roundf(22 * clampf(fill, 0, 1)), 1)), Color(0.98, 0.84, 0.4))


## Turns the millstone or the press screw while the building is making something, and rests it otherwise.
func _animate(delta: float) -> void:
	if _frames.is_empty() or _look != "working":
		return
	var b: Dictionary = Game.buildings[id]
	var running: bool = b["busy"] and not b.get("paused", false)
	if running and not Settings.reduced_motion:
		_clock += delta
		_sprite.texture = _frames[int(_clock * 6.0) % _frames.size()]
	elif _sprite.texture != _still:
		_sprite.texture = _still
	if _lamp:
		# Firelight shows most at night, and wavers a little with the flames.
		var night := Lighting.night_amount(Game.day_time)
		var flicker := 0.85 + 0.1 * sin(_clock * 9.0) + 0.05 * sin(_clock * 23.0)
		_lamp.shine((0.2 + 0.8 * night) * flicker if running else 0.0)


## The building's visible area relative to its base point, used for hover, clicks and the strip's click-through outline.
func local_rect() -> Rect2:
	return Rect2(_sprite.position, _sprite.region_rect.size)


func world_rect() -> Rect2:
	return Rect2(position + _sprite.position, _sprite.region_rect.size)


func _look_for_state() -> String:
	match Game.buildings[id]["state"]:
		"repairing":
			return "scaffold"
		"upgrading":
			return "upgrade"
		"working":
			return "working"
	return "ruin"


func _refresh() -> void:
	var was := _look
	_look = _look_for_state()
	# Under repair the ruin stays as it is, and while being enlarged the working building does, with scaffolding stood
	# in front of it either way.
	var picture := "ruin" if _look == "scaffold" else ("working" if _look == "upgrade" else _look)
	var built := _look in ["scaffold", "upgrade"]
	var was_built := was in ["scaffold", "upgrade"]
	var path := "%s%s_%s.png" % [DIR, id, picture]
	var tex: Texture2D = load(path if ResourceLoader.exists(path) else "%s%s_working.png" % [DIR, id])
	_sprite.texture = tex
	_still = tex
	_frames.clear()
	var folder := "%s%s_working_anim/" % [DIR, id]
	while picture == "working" and ResourceLoader.exists("%sframe_%02d.png" % [folder, _frames.size()]):
		_frames.append(load("%sframe_%02d.png" % [folder, _frames.size()]))
	var used := tex.get_image().get_used_rect()
	_sprite.region_rect = used
	var light: Array = Game.building_info(id).get("light", [])
	if _lamp:
		_lamp.queue_free()
		_lamp = null
	if picture == "working" and light.size() == 3:
		_lamp = Lamp.new()
		_lamp.position = Vector2(round(-used.size.x / 2.0), -used.size.y) + Vector2(float(light[0]), float(light[1])) - Vector2(used.position)
		_lamp.radius = float(light[2])
		add_child(_lamp)
	# The node sits at the middle of the building's base, so every look stands on the same spot.
	_sprite.position = Vector2(round(-used.size.x / 2.0), -used.size.y)
	_scaffold.rect = local_rect()
	if built:
		_scaffold.visible = true
		if was != "" and not was_built and not Settings.reduced_motion:
			_scaffold.rise()
		else:
			_scaffold.share = 1.0
	elif was_built and not Settings.reduced_motion:
		_scaffold.sink().tween_callback(func(): _scaffold.visible = _look in ["scaffold", "upgrade"])
	else:
		_scaffold.visible = false
	_shadow.texture = Lighting.ellipse_texture(used.size.x + 8, 7, Color(0.16, 0.11, 0.12, 0.28))
	_shadow.position = Vector2(round(-used.size.x / 2.0) - 4, -5)
