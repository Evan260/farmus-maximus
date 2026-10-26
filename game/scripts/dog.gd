extends Node2D
## The farm dog: trots along the front of the field, sits, naps (more often at night), and wags happily when petted.

signal petted

## The breed's folder of pictures, set from the breed before the dog is added.
var dir := "res://assets/sprites/dog/"
const SPEED := 15.0

## The stretch of ground the dog wanders, set by the scene.
var min_x := 10.0
var max_x := 456.0
## Coat colour chosen by the player, applied to every frame.
var coat := ""
var sprite: AnimatedSprite2D
var _shadow: Sprite2D
var _state := ""
var _timer := 0.0
var _target_x := 0.0


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)
	_shadow = Sprite2D.new()
	_shadow.texture = Lighting.ellipse_texture(23, 5, Color(0.16, 0.11, 0.12, 0.3))
	_shadow.position = Vector2(0, -1)
	add_child(_shadow)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_frames()
	sprite.centered = false
	var feet := _feet_line(load(dir + "walk_east/frame_00.png"))
	sprite.offset = Vector2(-30, -feet)
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)
	_sit()


func _process(delta: float) -> void:
	_timer -= delta
	if _state == "walk":
		var step := SPEED * delta
		position.x = move_toward(position.x, _target_x, step)
		if is_equal_approx(position.x, _target_x):
			_choose_next()
	elif _timer <= 0.0:
		_choose_next()


func pet() -> void:
	# A sitting or sleeping dog stays put and enjoys it; only a dog already on its feet jumps up wagging.
	if _state in ["sit_down", "sit", "lie_down", "sleep"]:
		_timer = maxf(_timer, 5.0)
	else:
		_state = "happy"
		_timer = 2.6
		sprite.play("happy")
	petted.emit()


func is_asleep() -> bool:
	return _state in ["lie_down", "sleep"]


func contains(point: Vector2) -> bool:
	return Hit.frame_rect(self, sprite).has_point(point)


func _choose_next() -> void:
	var sleepy := Lighting.night_amount(Game.day_time)
	var r := randf()
	# A dog already sitting or lying down stays put rather than getting up only to settle again.
	if r < 0.2 + sleepy * 0.6:
		_timer = randf_range(20.0, 45.0)
		if _state != "sleep":
			_state = "lie_down"
			sprite.play("lie_down")
	elif r < 0.55 + sleepy * 0.3:
		if _state == "sit":
			_timer = randf_range(8.0, 20.0)
		else:
			_sit()
	else:
		_state = "walk"
		_target_x = clampf(position.x + randf_range(-140.0, 140.0), min_x, max_x)
		sprite.flip_h = _target_x < position.x
		sprite.play("walk")


func _sit() -> void:
	_state = "sit_down"
	_timer = randf_range(8.0, 20.0)
	sprite.play("sit_down")


func _on_animation_finished() -> void:
	match sprite.animation:
		"sit_down":
			_state = "sit"
			sprite.play("sit")
		"lie_down":
			_state = "sleep"
			sprite.play("sleep")


func _build_frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	_add(f, "walk", "walk_east", range(1, 9), 9.0, true)
	_add(f, "sit_down", "sit_east", range(0, 3), 8.0, false)
	_add(f, "sit", "sit_east", range(3, 9), 4.0, true)
	_add(f, "lie_down", "sleep_east", range(0, 4), 6.0, false)
	_add(f, "sleep", "sleep_east", range(4, 9), 3.0, true)
	_add(f, "happy", "happy_east", range(1, 9), 12.0, true)
	return f


func _add(f: SpriteFrames, anim: String, folder: String, frames: Array, fps: float, loop: bool) -> void:
	f.add_animation(anim)
	f.set_animation_speed(anim, fps)
	f.set_animation_loop(anim, loop)
	for i in frames:
		f.add_frame(anim, Coats.recolour(load("%s%s/frame_%02d.png" % [dir, folder, i]), "dog", coat))


func _feet_line(tex: Texture2D) -> int:
	var used := tex.get_image().get_used_rect()
	return used.position.y + used.size.y
