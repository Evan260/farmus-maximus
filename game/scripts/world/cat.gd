extends Node2D
## The estate's cat: strolls a little, sits for a long while, and curls up for long naps, mostly at night and in the heat of midday.
## It can be petted, and stays as it is while it enjoys it.

signal petted

const DIR := "res://assets/sprites/animals/cat_small/"
const SPEED := 9.0

var min_x := 0.0
var max_x := 100.0
var sprite: AnimatedSprite2D
## Fur colour chosen by the player, applied to every frame.
var coat := ""
var _state := ""
var _timer := 0.0
var _target_x := 0.0
var _offsets := {}


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)
	var shadow := Sprite2D.new()
	shadow.texture = Lighting.ellipse_texture(14, 3, Color(0.16, 0.11, 0.12, 0.3))
	shadow.centered = false
	shadow.position = Vector2(-7, -2)
	add_child(shadow)
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.sprite_frames = _frames()
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)
	_sit(randf_range(5.0, 15.0))


func _process(delta: float) -> void:
	_timer -= delta
	match _state:
		"walk":
			position.x = move_toward(position.x, _target_x, SPEED * delta)
			if is_equal_approx(position.x, _target_x):
				_sit(randf_range(10.0, 30.0))
		"sit", "sleep":
			if _timer <= 0.0:
				_choose_next()


func is_asleep() -> bool:
	return _state in ["sleep", "lie_down"]


func pet() -> void:
	# A cat being petted stays exactly as it is, asleep or not; it just enjoys it.
	_timer = maxf(_timer, 6.0)
	petted.emit()


func contains(point: Vector2) -> bool:
	return Rect2(position + Vector2(-10, -16), Vector2(20, 16)).has_point(point)


func _choose_next() -> void:
	var hour := Game.day_time
	var sleepy := Lighting.night_amount(hour) * 0.6 + (0.3 if hour >= 12.0 and hour < 15.0 else 0.0)
	if _state == "sleep":
		_state = "wake"
		_play("sleep")
		sprite.play_backwards("sleep")
		return
	if randf() < 0.25 + sleepy:
		_state = "lie_down"
		_timer = randf_range(60.0, 180.0)
		_play("sleep")
	elif randf() < 0.5:
		_state = "walk"
		_target_x = clampf(position.x + randf_range(-40.0, 40.0), min_x, max_x)
		sprite.flip_h = _target_x < position.x
		_play("walk")
	else:
		_sit(randf_range(15.0, 40.0))


func _sit(seconds: float) -> void:
	_state = "sit"
	_timer = seconds
	_play("stand")


func _on_animation_finished() -> void:
	match _state:
		"lie_down":
			_state = "sleep"
		"wake":
			_sit(randf_range(10.0, 25.0))


func _play(anim: String) -> void:
	if not sprite.sprite_frames.has_animation(anim):
		anim = "stand"
	sprite.play(anim)
	sprite.offset = _offsets.get(anim, Vector2.ZERO)


func _frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	f.add_animation("stand")
	var still := _coloured(load(DIR + "east.png"))
	f.add_frame("stand", still)
	_offsets["stand"] = _anchor(still)
	for anim in [["walk", "walk_east", 8.0, true], ["sleep", "sleep_east", 5.0, false]]:
		var folder := DIR + String(anim[1]) + "/"
		if not ResourceLoader.exists(folder + "frame_00.png"):
			continue
		f.add_animation(anim[0])
		f.set_animation_speed(anim[0], float(anim[2]))
		f.set_animation_loop(anim[0], bool(anim[3]))
		var i := 0
		while ResourceLoader.exists("%sframe_%02d.png" % [folder, i]):
			f.add_frame(anim[0], _coloured(load("%sframe_%02d.png" % [folder, i])))
			i += 1
		_offsets[anim[0]] = _anchor(f.get_frame_texture(anim[0], 0))
	return f


func _coloured(tex: Texture2D) -> Texture2D:
	return Coats.recolour(tex, "cat", coat) if coat != "" else tex


func _anchor(tex: Texture2D) -> Vector2:
	var used := tex.get_image().get_used_rect()
	return Vector2(-roundf(tex.get_width() / 2.0), -(used.position.y + used.size.y))
