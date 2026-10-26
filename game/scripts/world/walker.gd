extends Node2D
## A person or animal that ambles about a stretch of ground: stands, walks somewhere, and now and then does its work animation.

## Folder holding east.png and frame folders such as walk_east/ and work_east/.
var dir := ""
var min_x := 0.0
var max_x := 100.0
var speed := 18.0
## Called for a spot worth walking to, such as a ripe plot; returns NAN when there is none.
var find_work: Callable
## Called with the spot when the work there is finished; returns what was picked, if anything, to carry away.
var work_done: Callable
## Called with what was picked; returns where to take it, or NAN to keep working.
var carry_to: Callable
## Called with the drop-off spot; false while it cannot take the load yet, such as the cart being away at market.
var can_drop: Callable
## Seconds of the work animation at each stop.
var work_seconds := 3.0
var idle_anim := ""
## For passers-by: the spot where they leave the estate; they walk straight there and are gone.
var leave_at := NAN
## People go indoors for the night: they walk to this spot, fade away, and come back out in the morning.
var rests_at_night := false
var home_x := NAN
var _homeward := false
var sprite: AnimatedSprite2D
var _state := "idle"
var _timer := 0.0
var _target := 0.0
var _working_next := false
var _offsets := {}
## How fast each walking animation's feet travel at its own frame rate, so the legs can be matched to the pace.
var _stride := {}
var _carry: Sprite2D
var _delivering := false


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
	_carry = Sprite2D.new()
	_carry.position = Vector2(0, -24)
	_carry.visible = false
	add_child(_carry)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)
	_timer = randf_range(1.0, 4.0)
	_play("stand")


func _process(delta: float) -> void:
	if rests_at_night and _night_check():
		return
	_timer -= delta
	match _state:
		"walk":
			position.x = move_toward(position.x, _target, speed * delta)
			if is_equal_approx(position.x, _target):
				if _homeward:
					_homeward = false
					_state = "home"
					_play("stand")
					create_tween().tween_property(self, "modulate:a", 0.0, 0.8)
				elif not is_nan(leave_at):
					_fade_out()
				elif _delivering:
					_state = "wait"
					_timer = 0.0
					_play("carry_still")
				elif _working_next:
					_state = "work"
					_timer = work_seconds
					_play("work")
				else:
					_rest()
		"wait":
			# Holding the load until the spot can take it, then setting it down.
			if _timer <= 0.0:
				_timer = 0.5
				if not can_drop.is_valid() or can_drop.call(_target):
					_set_down()
		_:
			if _timer <= 0.0:
				if _state == "drop":
					_carry.visible = false
					_delivering = false
				elif _state == "work" and work_done.is_valid():
					var picked: Variant = work_done.call(_target)
					if picked is String and picked != "" and carry_to.is_valid():
						var to: float = carry_to.call(picked, position.x)
						if not is_nan(to):
							_carry_away(picked, to)
							return
				_choose()


## Walks off with what was just picked, held up in front, to wherever it belongs.
func _carry_away(item: String, to: float) -> void:
	var path := "res://assets/sprites/icons/%s.png" % item
	_carry.texture = load(path) if ResourceLoader.exists(path) else null
	_carry.visible = _carry.texture != null
	_delivering = true
	_working_next = false
	_target = to
	_state = "walk"
	sprite.flip_h = _target < position.x
	_carry.position = Vector2(-6.0 if sprite.flip_h else 6.0, -24.0)
	_carry.modulate.a = 1.0
	_play("carry" if has_animation("carry") else "walk")


## Leans over and sets the load down: it drops from the hands into the cart or through the doorway.
func _set_down() -> void:
	_state = "drop"
	_timer = 1.0
	if has_animation("place"):
		# The placing animation shows the load going in, so the carried icon steps aside for it.
		_carry.visible = false
		_play("place")
		_timer = sprite.sprite_frames.get_frame_count("place") / sprite.sprite_frames.get_animation_speed("place")
		return
	_play("stand")
	var reach := -1.0 if sprite.flip_h else 1.0
	var fall := _carry.create_tween().set_parallel()
	fall.tween_property(_carry, "position", _carry.position + Vector2(10.0 * reach, 12.0), 0.5).set_delay(0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(_carry, "modulate:a", 0.0, 0.2).set_delay(0.7)


## Sends the walker home at nightfall, once any load is set down, and brings them back out at daybreak. True while
## they are indoors, so nothing else happens.
func _night_check() -> bool:
	var night: bool = Game.is_night()
	if _state == "home":
		if night:
			return true
		_state = "idle"
		_timer = randf_range(0.5, 2.0)
		create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
		return false
	if night and not _homeward and not _delivering and _state in ["idle", "walk", "work"]:
		_homeward = true
		_working_next = false
		_target = home_x if not is_nan(home_x) else position.x
		_state = "walk"
		sprite.flip_h = _target < position.x
		_play("walk")
	return false


func _fade_out() -> void:
	set_process(false)
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.6)
	fade.tween_callback(queue_free)


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
		# Work can take a helper anywhere their plants are, beyond where they usually stroll.
		_target = spot
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
	var still := anim == "carry_still"
	if still:
		anim = "carry" if has_animation("carry") else "stand"
	if not sprite.sprite_frames.has_animation(anim):
		anim = "stand"
	sprite.play(anim)
	sprite.offset = _offsets.get(anim, Vector2.ZERO)
	# The legs keep pace with the ground: a walk cycle plays exactly as fast as the walker moves.
	sprite.speed_scale = speed / float(_stride[anim]) if _stride.has(anim) else 1.0
	if still:
		sprite.pause()
		sprite.frame = 0


func _frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	var still: Texture2D = load(dir + "east.png") if ResourceLoader.exists(dir + "east.png") else null
	f.add_animation("stand")
	if still:
		f.add_frame("stand", still)
		_offsets["stand"] = _anchor(still)
	for anim in ["walk", "carry", "work", "place", "graze", "sleep"]:
		var folder := "%s%s_east/" % [dir, anim]
		if not ResourceLoader.exists(folder + "frame_00.png"):
			continue
		f.add_animation(anim)
		f.set_animation_speed(anim, 9.0 if anim in ["walk", "carry"] else 6.0)
		f.set_animation_loop(anim, anim != "place")
		var i := 0
		while ResourceLoader.exists("%sframe_%02d.png" % [folder, i]):
			f.add_frame(anim, load("%sframe_%02d.png" % [folder, i]))
			i += 1
		_offsets[anim] = _anchor(f.get_frame_texture(anim, 0))
		if anim in ["walk", "carry"]:
			var pace := natural_pace(f, anim)
			if pace > 0.0:
				_stride[anim] = pace
	return f


## How many pixels a second a walk animation's feet cover at its frame rate: two steps a cycle, each step as long as
## the feet are furthest apart.
static func natural_pace(f: SpriteFrames, anim: String) -> float:
	var spread := []
	for i in f.get_frame_count(anim):
		var img := f.get_frame_texture(anim, i).get_image()
		var used := img.get_used_rect()
		var left := used.end.x
		var right := used.position.x
		for y in range(used.end.y - 3, used.end.y):
			for x in range(used.position.x, used.end.x):
				if img.get_pixel(x, y).a > 0.0:
					left = mini(left, x)
					right = maxi(right, x)
		spread.append(right - left + 1)
	var step: int = spread.max() - spread.min()
	if step < 4:
		return 0.0
	return 2.0 * step * f.get_animation_speed(anim) / f.get_frame_count(anim)


## Places the feet on the node's position whatever the frame size, since animation frames are larger than the still pose.
func _anchor(tex: Texture2D) -> Vector2:
	var used := tex.get_image().get_used_rect()
	return Vector2(-roundf(tex.get_width() / 2.0), -(used.position.y + used.size.y))
