extends Node2D
## One farm plot on screen: its soil patch, the crop growing in it, and the hover and ready cues.

const BED := preload("res://assets/sprites/farm/plot_bed.png")
const SHADOW := preload("res://assets/sprites/farm/shadow_small.png")
const SPRITES := {
	"lavender": {
		"stage0": preload("res://assets/sprites/lavender/final/stage0.png"),
		"stage1": preload("res://assets/sprites/lavender/final/stage1.png"),
		"stage2": preload("res://assets/sprites/lavender/final/stage2.png"),
		"harvested": preload("res://assets/sprites/lavender/final/harvested.png"),
		"bloom": [preload("res://assets/sprites/lavender/final/bloom_1.png"), preload("res://assets/sprites/lavender/final/bloom_2.png")],
	},
	"wheat": {
		"stage0": preload("res://assets/sprites/wheat/final/stage0.png"),
		"stage1": preload("res://assets/sprites/wheat/final/stage1.png"),
		"stage2": preload("res://assets/sprites/wheat/final/stage2.png"),
		"bloom": preload("res://assets/sprites/wheat/final/bloom.png"),
	},
}

var index := 0
var hovered := false
var _bed: Sprite2D
var _shadow: Sprite2D
var _crop: Sprite2D
var _visual := ""
var _crop_id := ""
var _hit := Rect2(Vector2(0, -5), Vector2(30, 8))
var _time := 0.0


func _ready() -> void:
	_bed = _sprite(BED, Vector2(0, -4))
	_shadow = _sprite(SHADOW, Vector2(2, -2))
	_crop = _sprite(null, Vector2(-1, -29))
	# Mirroring every other plant keeps a field of identical sprites from looking stamped.
	_crop.flip_h = index % 2 == 1


func _process(delta: float) -> void:
	_time += delta
	var visual := Game.plot_visual(index)
	var crop := String(Game.plots[index]["crop"])
	if visual + crop != _visual + _crop_id:
		_visual = visual
		_crop_id = crop
		_bed.modulate = Color(0.55, 0.5, 0.48) if visual == "locked" else Color.WHITE
		_crop.visible = visual not in ["locked", "empty"]
		_shadow.visible = _crop.visible
		if _crop.visible:
			var tex: Variant = SPRITES[crop][visual]
			_crop.texture = tex[index % tex.size()] if tex is Array else tex
		_hit = _hit_rect()
	queue_redraw()


func _draw() -> void:
	if hovered:
		draw_rect(_hit.grow(1), Color(1, 0.96, 0.85, 0.7), false, 1.0)
	match _visual:
		"bloom":
			# A small twinkle above ready plants, so a glance shows what can be harvested.
			if fmod(_time + index * 0.37, 1.6) < 0.8:
				var c := Color(1, 0.97, 0.8)
				var p := Vector2(14, -33)
				draw_rect(Rect2(p, Vector2.ONE), c)
				draw_rect(Rect2(p + Vector2(-1, 1), Vector2(3, 1)), Color(c, 0.6))
				draw_rect(Rect2(p + Vector2(0, 2), Vector2.ONE), c)
		"empty":
			draw_rect(Rect2(Vector2(14, -6), Vector2(1, 3)), Color(1, 1, 1, 0.35))
			draw_rect(Rect2(Vector2(13, -5), Vector2(3, 1)), Color(1, 1, 1, 0.35))
		"locked":
			var c := Color(0.15, 0.12, 0.1, 0.55)
			draw_rect(Rect2(Vector2(12, -8), Vector2(5, 4)), c)
			draw_rect(Rect2(Vector2(13, -11), Vector2(3, 3)), c, false, 1.0)


## A small hop of the plant, so planting and harvesting feel like they did something.
func bounce() -> void:
	var t := create_tween()
	t.tween_property(_crop, "position:y", -31.0, 0.07)
	t.tween_property(_crop, "position:y", -29.0, 0.12)


func contains(point: Vector2) -> bool:
	return Rect2(position + _hit.position, _hit.size).has_point(point)


## The clickable area: just the soil patch for an empty plot, or the soil plus the plant's visible pixels.
func _hit_rect() -> Rect2:
	var soil := Rect2(Vector2(0, -5), Vector2(30, 8))
	if not _crop.visible or _crop.texture == null:
		return soil
	var used := Rect2(_crop.texture.get_image().get_used_rect())
	if _crop.flip_h:
		used.position.x = _crop.texture.get_width() - used.position.x - used.size.x
	used.position += Vector2(-1, -29)
	return soil.merge(used)


func _sprite(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	add_child(s)
	return s
