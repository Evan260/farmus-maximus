extends Node2D
## A builder at work on a building under repair: hammers along its front, and where the scaffold has a ladder,
## climbs it to work from it, then climbs back down.

const DIRS := ["res://assets/sprites/people/builder_small/", "res://assets/sprites/people/builder/"]

## The building's outline in estate pixels.
var site := Rect2()
## Where the scaffold's ladders stand, in estate pixels; with none the builder keeps to the ground.
var ladders: Array = []
var sprite: AnimatedSprite2D
var _plan: Array = []
var _timer := 0.0
var _offsets := {}
var _dir := ""


func _ready() -> void:
	for d in DIRS:
		if ResourceLoader.exists(d + "east.png"):
			_dir = d
			break
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.sprite_frames = _frames()
	add_child(sprite)
	position = Vector2(site.position.x + randf() * site.size.x, site.end.y + 2)
	_next()


func _process(delta: float) -> void:
	if _plan.is_empty():
		_next()
		return
	var step: Dictionary = _plan[0]
	match step["kind"]:
		"wait":
			_timer -= delta
			if _timer <= 0.0:
				_plan.pop_front()
				_begin()
		_:
			var target: Vector2 = step["to"]
			position = position.move_toward(target, (10.0 if step["kind"] == "climb" else 14.0) * delta)
			if position.distance_to(target) < 0.5:
				position = target
				_plan.pop_front()
				_begin()


## Chooses the next job: hammering somewhere along the front, or up a ladder when the scaffold has one.
func _next() -> void:
	var ground := site.end.y + 2
	_plan = []
	if not ladders.is_empty() and randf() < 0.45:
		var x: float = ladders[randi() % ladders.size()]
		var height := ground - site.size.y * randf_range(0.3, 0.55)
		_plan.append({"kind": "walk", "to": Vector2(x, ground)})
		_plan.append({"kind": "climb", "to": Vector2(x, height)})
		_plan.append({"kind": "wait", "anim": "climb_still", "seconds": randf_range(3.0, 6.0)})
		_plan.append({"kind": "climb", "to": Vector2(x, ground)})
	else:
		var x := site.position.x + randf_range(0.1, 0.9) * site.size.x
		_plan.append({"kind": "walk", "to": Vector2(x, ground)})
		_plan.append({"kind": "wait", "anim": "work", "seconds": randf_range(2.5, 5.0)})
	_begin()


func _begin() -> void:
	if _plan.is_empty():
		return
	var step: Dictionary = _plan[0]
	match step["kind"]:
		"walk":
			var to: Vector2 = step["to"]
			sprite.flip_h = to.x < position.x
			_play("walk")
		"climb":
			_play("climb")
		"wait":
			_timer = float(step["seconds"])
			_play(String(step["anim"]))


func _play(anim: String) -> void:
	var name := anim
	if name == "climb_still":
		# Working from the ladder: the builder stays in the climbing pose, facing the wall, with small pauses.
		name = "climb"
	if not sprite.sprite_frames.has_animation(name):
		name = "work" if sprite.sprite_frames.has_animation("work") else "walk"
	sprite.play(name)
	sprite.speed_scale = 0.35 if anim == "climb_still" else 1.0
	sprite.offset = _offsets.get(name, Vector2.ZERO)


func _frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	for anim in [["walk", "walk_east"], ["work", "work_east"], ["climb", "climb_north"]]:
		var folder := "%s%s/" % [_dir, anim[1]]
		if not ResourceLoader.exists(folder + "frame_00.png"):
			continue
		f.add_animation(anim[0])
		f.set_animation_speed(anim[0], 9.0)
		var i := 0
		while ResourceLoader.exists("%sframe_%02d.png" % [folder, i]):
			f.add_frame(anim[0], load("%sframe_%02d.png" % [folder, i]))
			i += 1
		var tex := f.get_frame_texture(anim[0], 0)
		var used := tex.get_image().get_used_rect()
		_offsets[anim[0]] = Vector2(-roundf(tex.get_width() / 2.0), -(used.position.y + used.size.y))
	return f
