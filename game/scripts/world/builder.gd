extends Node2D
## A builder at work on a building under repair: hammers along its front, and where the scaffold has a ladder,
## climbs it to work from it, then climbs back down.

const DIRS := ["res://assets/sprites/people/builder_small/", "res://assets/sprites/people/builder/"]
const Walker := preload("res://scripts/world/walker.gd")

## The building's outline in estate pixels.
var site := Rect2()
## Where the scaffold's ladders stand, in estate pixels; with none the builder keeps to the ground.
var ladders: Array = []
## The rows of the scaffold's plank floors in estate pixels, where builders step off the ladder to work.
var planks: Array = []
## For work that moves along, such as paving: the builder keeps up with it rather than finishing a job far behind.
var follows := false
## The ladder a builder up on the scaffold came up by, to go back down the same way.
var _ladder_x := 0.0
## Returns the seconds the work still has to run, so the builder is down off the ladder before it ends.
var time_left: Callable
## Where the road leaves the estate for the town, which is where the builder goes home to.
var town_x := 2400.0
## The row the road runs along.
var road_y := 283.0
var sprite: AnimatedSprite2D
var _plan: Array = []
var _timer := 0.0
var _offsets := {}
var _dir := ""
var _leaving := false
## True through the night, when the builder has gone home and the work waits for morning.
var _resting := false
var _pace := 0.0
## Which clothes this builder wears, chosen at random so a team looks like different people.
var outfit := randi() % Outfits.OUTFITS.size()


func _ready() -> void:
	for d in DIRS:
		if ResourceLoader.exists(d + "east.png"):
			_dir = d
			break
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.sprite_frames = _frames()
	add_child(sprite)
	if sprite.sprite_frames.has_animation("walk"):
		_pace = Walker.natural_pace(sprite.sprite_frames, "walk")
	position = Vector2(site.position.x + randf() * site.size.x, site.end.y + 2)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
	_next()


## The work is done: the builder climbs down if need be, then walks down to the road and along it home to the town.
func leave() -> void:
	if _leaving:
		return
	_leaving = true
	_plan = []
	_climb_down()
	_plan.append({"kind": "walk", "to": Vector2(position.x + 6.0, road_y), "speed": 20.0})
	_plan.append({"kind": "walk", "to": Vector2(town_x + 30.0, road_y), "speed": 26.0})
	_begin()


func _on_ladder() -> bool:
	return position.y < site.end.y + 1.5


func _climb_down() -> void:
	if _on_ladder():
		# From out along a plank, the builder first walks back to the ladder.
		if absf(position.x - _ladder_x) > 0.5:
			_plan.append({"kind": "walk", "to": Vector2(_ladder_x, position.y)})
		_plan.append({"kind": "climb", "to": Vector2(_ladder_x, site.end.y + 2)})


## Real seconds until the work is done; a faster build speed makes the work's own seconds pass quicker.
func _seconds_left() -> float:
	return float(time_left.call()) / maxf(1.0, Game.build_speed) if time_left.is_valid() else INF


func _process(delta: float) -> void:
	if not _leaving:
		var night: bool = Game.is_night()
		if night and not _resting:
			_resting = true
			_plan = []
			_climb_down()
			_plan.append({"kind": "rest"})
			_begin()
		elif _resting and not night:
			_resting = false
			create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
			_plan = []
			_next()
			return
	if not _plan.is_empty() and _plan[0]["kind"] == "rest":
		return
	if _plan.is_empty():
		if _leaving:
			queue_free()
			return
		_next()
		return
	if not _leaving and _on_ladder() and _seconds_left() < 12.0 and String(_plan[0]["kind"]) not in ["climb", "walk"]:
		_plan = []
		_climb_down()
		_begin()
	var step: Dictionary = _plan[0]
	match step["kind"]:
		"wait":
			_timer -= delta
			if follows and site.get_center().x - position.x > 14.0:
				_timer = 0.0
			if _timer <= 0.0:
				_plan.pop_front()
				_begin()
		_:
			var target: Vector2 = step["to"]
			position = position.move_toward(target, float(step.get("speed", 10.0 if step["kind"] == "climb" else 14.0)) * delta)
			if position.distance_to(target) < 0.5:
				position = target
				_plan.pop_front()
				_begin()


## Chooses the next job: hammering somewhere along the front, or up a ladder when the scaffold has one.
func _next() -> void:
	var ground := site.end.y + 2
	_plan = []
	if not ladders.is_empty() and not planks.is_empty() and randf() < 0.45 and _seconds_left() > 25.0:
		# Up a ladder to one of the scaffold's floors, off along the planks to work there, then back and down.
		var x: float = ladders[randi() % ladders.size()]
		_ladder_x = x
		var floor_y: float = planks[randi() % planks.size()]
		var along := clampf(x + randf_range(12.0, 34.0) * (1.0 if randf() < 0.5 else -1.0), site.position.x + 8.0, site.end.x - 10.0)
		_plan.append({"kind": "walk", "to": Vector2(x, ground)})
		_plan.append({"kind": "climb", "to": Vector2(x, floor_y)})
		_plan.append({"kind": "walk", "to": Vector2(along, floor_y), "speed": 10.0})
		_plan.append({"kind": "wait", "anim": "work", "seconds": randf_range(3.0, 6.0)})
		_plan.append({"kind": "walk", "to": Vector2(x, floor_y), "speed": 10.0})
		_plan.append({"kind": "climb", "to": Vector2(x, ground)})
	else:
		var x := site.get_center().x + randf_range(-4.0, 6.0) if follows else site.position.x + randf_range(0.1, 0.9) * site.size.x
		# A builder left behind by work that moves along, like a road being paved, hurries to catch up.
		_plan.append({"kind": "walk", "to": Vector2(x, ground), "speed": clampf(absf(x - position.x) / 2.0, 14.0, 70.0)})
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
			if _pace > 0.0:
				sprite.speed_scale = float(step.get("speed", 14.0)) / _pace
		"climb":
			_play("climb")
		"wait":
			_timer = float(step["seconds"])
			_play(String(step["anim"]))
		"rest":
			_play("work")
			sprite.pause()
			create_tween().tween_property(self, "modulate:a", 0.0, 0.8)


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
		var dressed := func(tex: Texture2D) -> Texture2D: return Outfits.dress(tex, outfit)
		if Frames.add_folder(f, anim[0], "%s%s/" % [_dir, anim[1]], 9.0, true, dressed) > 0:
			_offsets[anim[0]] = Frames.anchor(f.get_frame_texture(anim[0], 0))
	return f
