extends Node2D
## One estate building on screen: its ruin, scaffolding or working look, a shadow, and a progress bar while it works.

const DIR := "res://assets/sprites/buildings/"

var id := ""
var hovered := false
var _sprite: Sprite2D
var _shadow: Sprite2D
var _look := ""


func _ready() -> void:
	_shadow = Sprite2D.new()
	_shadow.centered = false
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.region_enabled = true
	add_child(_sprite)
	Game.building_changed.connect(func(changed): if changed == id: _refresh())
	_refresh()


func _process(_delta: float) -> void:
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
	elif b["state"] == "working" and b["busy"]:
		fill = float(b["progress"]) / float(Game.building_info(id).get("seconds", 30))
	if fill >= 0.0:
		draw_rect(bar, Color(0.2, 0.14, 0.12, 0.8))
		draw_rect(Rect2(bar.position + Vector2.ONE, Vector2(roundf(22 * clampf(fill, 0, 1)), 1)), Color(0.98, 0.84, 0.4))


## The building's visible area relative to its base point, used for hover, clicks and the strip's click-through outline.
func local_rect() -> Rect2:
	return Rect2(_sprite.position, _sprite.region_rect.size)


func world_rect() -> Rect2:
	return Rect2(position + _sprite.position, _sprite.region_rect.size)


func _look_for_state() -> String:
	match Game.buildings[id]["state"]:
		"repairing":
			return "scaffold"
		"working":
			return "working"
	return "ruin"


func _refresh() -> void:
	_look = _look_for_state()
	var path := "%s%s_%s.png" % [DIR, id, _look]
	var tex: Texture2D = load(path if ResourceLoader.exists(path) else "%s%s_working.png" % [DIR, id])
	_sprite.texture = tex
	var used := tex.get_image().get_used_rect()
	_sprite.region_rect = used
	# The node sits at the middle of the building's base, so every look stands on the same spot.
	_sprite.position = Vector2(round(-used.size.x / 2.0), -used.size.y)
	_shadow.texture = Lighting.ellipse_texture(used.size.x + 8, 7, Color(0.16, 0.11, 0.12, 0.28))
	_shadow.position = Vector2(round(-used.size.x / 2.0) - 4, -5)
