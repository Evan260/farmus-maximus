extends Node2D
## One farm plot on screen: its soil patch, the crop growing in it, and the hover and ready cues.

const BED := preload("res://assets/sprites/farm/plot_bed.png")
const SHADOW := preload("res://assets/sprites/farm/shadow_small.png")
const SWAY := preload("res://assets/shaders/sway.gdshader")
## Where each crop's pictures live; lavender varieties share the lavender pictures, recoloured.
const SETS := {
	"lavender": "res://assets/sprites/lavender/final/",
	"wheat": "res://assets/sprites/wheat/final/",
	"olives": "res://assets/sprites/olive/final/",
	"grapes": "res://assets/sprites/grapes/final/",
	"herbs": "res://assets/sprites/herbs/final/",
}

## Plants turn with the year: fresh in spring, golden at the edges in autumn, grey-green and resting in winter.
const SEASON_LOOK := {"spring": Color(0.97, 1.03, 0.97), "summer": Color.WHITE, "autumn": Color(1.04, 0.95, 0.84), "winter": Color(0.82, 0.9, 0.86)}

## One wind material for every plant, so changing the wind changes the whole estate at once.
static var wind: ShaderMaterial
static var _cache := {}

var index := 0
var hovered := false:
	set(value):
		if value != hovered:
			hovered = value
			queue_redraw()
var _bed: Sprite2D
var _shadow: Sprite2D
var _crop: Sprite2D
var _visual := ""
var _crop_id := ""
var _hit := Rect2(Vector2(0, -5), Vector2(30, 8))
var _time := 0.0
## What the last drawing showed: the twinkle over a ripe plant and the strong cues setting.
var _twinkled := false
var _cues := false


func _ready() -> void:
	if wind == null:
		wind = ShaderMaterial.new()
		wind.shader = SWAY
	_bed = _sprite(BED, Vector2(0, -4))
	_shadow = _sprite(SHADOW, Vector2(2, -2))
	_crop = _sprite(null, Vector2(-1, -29))
	_crop.material = wind
	# Mirroring every other plant keeps a field of identical sprites from looking stamped.
	_crop.flip_h = index % 2 == 1


func _process(delta: float) -> void:
	_time += delta
	var visual := Game.plot_visual(index)
	var crop := String(Game.plots[index]["crop"])
	_crop.modulate = SEASON_LOOK.get(Game.calendar.season_id(), Color.WHITE)
	_bed.modulate = Color(0.55, 0.5, 0.48) if visual == "locked" else (Color(0.82, 0.8, 0.85) if Game.watered(index) else Color.WHITE)
	if visual + crop != _visual + _crop_id:
		_visual = visual
		_crop_id = crop
		_crop.visible = visual not in ["locked", "empty"]
		_shadow.visible = _crop.visible
		if _crop.visible:
			_crop.texture = texture_for(crop, visual, index)
			# Plants of any size stand on the middle of the soil patch, measured from their lowest visible pixel,
			# so 48-pixel olive trees are planted in the bed just like 32-pixel lavender.
			var used := Hit.used_rect(_crop.texture)
			# Mirrored plants are measured from the other side, so they stand on the middle of the soil just the same.
			var left := (_crop.texture.get_width() - used.end.x) if _crop.flip_h else used.position.x
			_crop.position = Vector2(roundf(15 - left - used.size.x / 2.0), 0 - used.end.y)
		_hit = _hit_rect()
		queue_redraw()
	var twinkle := _visual == "bloom" and fmod(_time + index * 0.37, 1.6) < 0.8
	if twinkle != _twinkled or Settings.strong_cues != _cues:
		_twinkled = twinkle
		_cues = Settings.strong_cues
		queue_redraw()


## The picture for a crop at a stage, recoloured for lavender varieties and cached so each is made once.
static func texture_for(crop: String, visual: String, variant := 0) -> Texture2D:
	var info: Dictionary = Data.get_value("crops." + crop, {})
	var set_id := String(info.get("sprite", crop))
	var dir: String = SETS.get(set_id, SETS["lavender"])
	var name := visual
	if visual == "harvested" and not ResourceLoader.exists(dir + "harvested.png"):
		name = "stage2"
	if visual == "bloom" and not ResourceLoader.exists(dir + "bloom.png"):
		name = "bloom_%d" % (variant % 2 + 1)
	var recolor := String(info.get("recolor", ""))
	var key := "%s/%s/%s" % [dir, name, recolor]
	if not _cache.has(key):
		var tex: Texture2D = load(dir + name + ".png")
		_cache[key] = _recolor(tex, recolor) if recolor != "" else tex
	return _cache[key]


## Lavender varieties are the same plant in a different flower colour: only the purple pixels change.
static func _recolor(tex: Texture2D, how: String) -> Texture2D:
	return Recolour.apply(tex, "flower:" + how, func(c: Color, _down: float) -> Color:
		if c.h < 0.68 or c.h > 0.92 or c.s < 0.15:
			return c
		match how:
			"violet":
				return Color.from_hsv(0.76, minf(1.0, c.s * 1.25), c.v * 0.78, c.a)
			"bluegrey":
				return Color.from_hsv(0.6, c.s * 0.55, minf(1.0, c.v * 1.05), c.a)
			"white":
				return Color.from_hsv(0.75, c.s * 0.12, 0.82 + c.v * 0.18, c.a)
		return c)


func _draw() -> void:
	if hovered:
		Ui.outline(self, _hit, Color(1, 0.96, 0.85, 0.7))
	match _visual:
		"bloom":
			var top := _crop.position.y - 2
			if Settings.strong_cues:
				# A small arrow that does not depend on colour or blinking.
				var c := Color(1, 0.97, 0.8)
				draw_rect(Rect2(Vector2(13, top - 6), Vector2(3, 3)), c)
				draw_rect(Rect2(Vector2(14, top - 3), Vector2(1, 2)), c)
				draw_rect(Rect2(Vector2(12, top - 7), Vector2(5, 1)), Color(0.3, 0.2, 0.15))
			# A small twinkle above ready plants, so a glance shows what can be harvested.
			elif fmod(_time + index * 0.37, 1.6) < 0.8:
				var c := Color(1, 0.97, 0.8)
				var p := Vector2(14, top)
				draw_rect(Rect2(p, Vector2.ONE), c)
				draw_rect(Rect2(p + Vector2(-1, 1), Vector2(3, 1)), Color(c, 0.6))
				draw_rect(Rect2(p + Vector2(0, 2), Vector2.ONE), c)
		"empty":
			draw_rect(Rect2(Vector2(14, -6), Vector2(1, 3)), Color(1, 1, 1, 0.35))
			draw_rect(Rect2(Vector2(13, -5), Vector2(3, 1)), Color(1, 1, 1, 0.35))
		"locked":
			# A tiny padlock: a rounded shackle over a small body.
			var c := Color(0.15, 0.12, 0.1, 0.5)
			draw_rect(Rect2(14, -9, 1, 1), c)
			draw_rect(Rect2(13, -8, 1, 1), c)
			draw_rect(Rect2(15, -8, 1, 1), c)
			draw_rect(Rect2(13, -7, 3, 2), c)


## A small hop of the plant, so planting and harvesting feel like they did something.
func bounce() -> void:
	# The hop moves the picture's offset, so the crop's place on the soil is free to change with its new picture.
	var t := create_tween()
	t.tween_property(_crop, "offset:y", -2.0, 0.07)
	t.tween_property(_crop, "offset:y", 0.0, 0.12)


func contains(point: Vector2) -> bool:
	return Rect2(position + _hit.position, _hit.size).has_point(point)


## The top of the plant in estate pixels, where butterflies land and dew settles.
func plant_top() -> Vector2:
	return position + Vector2(14, _crop.position.y + 4)


## The clickable area: just the soil patch for an empty plot, or the soil plus the plant's visible pixels.
func _hit_rect() -> Rect2:
	var soil := Rect2(Vector2(0, -5), Vector2(30, 8))
	if not _crop.visible or _crop.texture == null:
		return soil
	var used := Rect2(Hit.used_rect(_crop.texture))
	if _crop.flip_h:
		used.position.x = _crop.texture.get_width() - used.position.x - used.size.x
	used.position += _crop.position
	return soil.merge(used)


func _sprite(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	add_child(s)
	return s
