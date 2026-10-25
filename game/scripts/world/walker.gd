extends Node2D
## A person or animal that ambles about a stretch of ground: stands, walks somewhere, and now and then does its work animation.

## Folder holding east.png and frame folders such as walk_east/ and work_east/.
var dir := ""
var min_x := 0.0
var max_x := 100.0
var speed := 14.0
## Called for a spot worth walking to, such as a ripe plot; returns NAN when there is none.
var find_work: Callable
## Seconds of the work animation at each stop.
var work_seconds := 3.0
var idle_anim := ""
## For passers-by: the spot where they leave the estate; they walk straight there and are gone.
var leave_at := NAN
var sprite: AnimatedSprite2D
var _state := "idle"
var _timer := 0.0
var _target := 0.0
var _working_next := false
var _offsets := {}


func _ready() -> void:
	var shadow := Sprite2D.new()
	shadow.texture = Lighting.ellipse_texture(18, 4, Color(0.16, 0.11, 0.12, 0.28))
	shadow.position = Vector2(-9, -2)
	shadow.centered = false
	add_child(shadow)
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.sprite_frames = _frames()
	add_child(sprite)
	_timer = randf_range(1.0, 4.0)
	_play("stand")


func _process(delta: float) -> void:
	_timer -= delta
	match _state:
		"walk":
			position.x = move_toward(position.x, _target, speed * delta)
			if is_equal_approx(position.x, _target):
				if not is_nan(leave_at):
					queue_free()
				elif _working_next and sprite.sprite_frames.has_animation("work"):
					_state = "work"
					_timer = work_seconds
					_play("work")
				else:
					_rest()
		_:
			if _timer <= 0.0:
				_choose()


func has_animation(anim: String) -> bool:
	return sprite and sprite.sprite_frames.has_animation(anim)


func _choose() -> void:
	if not is_nan(leave_at):
		_target = leave_at
		_working_next = false
		_state = "walk"
		sprite.flip_h = _target < position.x
		_play("walk")
		return
	var spot: float = find_work.call() if find_work.is_valid() else NAN
	_working_next = not is_nan(spot)
	if _working_next:
		_target = clampf(spot, min_x, max_x)
	elif randf() < 0.35:
		_rest()
		return
	else:
		_target = clampf(position.x + randf_range(-90.0, 90.0), min_x, max_x)
	_state = "walk"
	sprite.flip_h = _target < position.x
	_play("walk")


func _rest() -> void:
	_state = "idle"
	_timer = randf_range(2.0, 6.0)
	_play(idle_anim if idle_anim != "" and sprite.sprite_frames.has_animation(idle_anim) and randf() < 0.5 else "stand")


func _play(anim: String) -> void:
	if not sprite.sprite_frames.has_animation(anim):
		anim = "stand"
	sprite.play(anim)
	sprite.offset = _offsets.get(anim, Vector2.ZERO)


func _frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	var still: Texture2D = load(dir + "east.png") if ResourceLoader.exists(dir + "east.png") else null
	f.add_animation("stand")
	if still:
		f.add_frame("stand", still)
		_offsets["stand"] = _anchor(still)
	for anim in ["walk", "work", "graze", "sleep"]:
		var folder := "%s%s_east/" % [dir, anim]
		if not ResourceLoader.exists(folder + "frame_00.png"):
			continue
		f.add_animation(anim)
		f.set_animation_speed(anim, 9.0 if anim == "walk" else 6.0)
		var i := 0
		while ResourceLoader.exists("%sframe_%02d.png" % [folder, i]):
			f.add_frame(anim, load("%sframe_%02d.png" % [folder, i]))
			i += 1
		_offsets[anim] = _anchor(f.get_frame_texture(anim, 0))
	return f


## Places the feet on the node's position whatever the frame size, since animation frames are larger than the still pose.
func _anchor(tex: Texture2D) -> Vector2:
	var used := tex.get_image().get_used_rect()
	return Vector2(-roundf(tex.get_width() / 2.0), -(used.position.y + used.size.y))
