extends Node2D
## A builder at work on a building under repair: walks along its front, climbs the scaffolding, and hammers at each spot.

const DIR := "res://assets/sprites/people/builder/"

## The building's outline in estate pixels; the builder keeps to its front and its scaffolding.
var site := Rect2()
var sprite: AnimatedSprite2D
var _floor := 0.0
var _plan: Array = []
var _timer := 0.0
var _offsets := {}


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.sprite_frames = _frames()
	add_child(sprite)
	position = Vector2(site.position.x + randf() * site.size.x, site.end.y)
	_floor = site.end.y
	_next()


func _process(delta: float) -> void:
	if _plan.is_empty():
		_timer -= delta
		if _timer <= 0.0:
			_next()
		return
	var step: Dictionary = _plan[0]
	var target: Vector2 = step["to"]
	var speed := 22.0 if step["kind"] == "climb" else 14.0
	position = position.move_toward(target, speed * delta)
	if position.distance_to(target) < 0.5:
		position = target
		_plan.pop_front()
		if _plan.is_empty():
			_timer = randf_range(2.5, 5.0)
			_play("work")


## Chooses a new spot: at ground level, or up on one of the scaffold's platforms, reached by the ladder at the left.
func _next() -> void:
	var levels := [site.end.y, site.end.y - site.size.y * 0.42, site.end.y - site.size.y * 0.72]
	var height: float = levels[randi() % levels.size()]
	var x := site.position.x + randf_range(0.15, 0.85) * site.size.x
	var ladder := site.position.x + site.size.x * 0.12
	_plan = []
	if not is_equal_approx(height, _floor):
		_plan.append({"kind": "walk", "to": Vector2(ladder, _floor)})
		_plan.append({"kind": "climb", "to": Vector2(ladder, height)})
	_plan.append({"kind": "walk", "to": Vector2(x, height)})
	_floor = height
	var first: Vector2 = _plan[0]["to"]
	sprite.flip_h = first.x < position.x
	_play("walk")


func _play(anim: String) -> void:
	if not sprite.sprite_frames.has_animation(anim):
		anim = "walk"
	sprite.play(anim)
	sprite.offset = _offsets.get(anim, Vector2.ZERO)


func _frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	for anim in ["walk", "work"]:
		var folder := "%s%s_east/" % [DIR, anim]
		if not ResourceLoader.exists(folder + "frame_00.png"):
			continue
		f.add_animation(anim)
		f.set_animation_speed(anim, 9.0)
		var i := 0
		while ResourceLoader.exists("%sframe_%02d.png" % [folder, i]):
			f.add_frame(anim, load("%sframe_%02d.png" % [folder, i]))
			i += 1
		var tex := f.get_frame_texture(anim, 0)
		var used := tex.get_image().get_used_rect()
		_offsets[anim] = Vector2(-roundf(tex.get_width() / 2.0), -(used.position.y + used.size.y))
	return f
