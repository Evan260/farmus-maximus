extends Node
## Command-line options for checking the game without a hand on the mouse: screenshots, bursts of frames, pointing and
## clicking, the window and interface size, and runs that never write the player's farms or settings.
## --shot=PATH [--shot-at=SECONDS] saves one screenshot; --burst=PREFIX [--burst-start, --burst-gap, --burst-count]
## saves several as PREFIX_00.png and on; --quit closes the game after the last one; --hover=X,Y and --click=X,Y point
## and click in interface pixels (at --hover-at and --click-at seconds); --no-save writes nothing anywhere.

var args := {}
var time := 0.0
## Set once the tests or a bot have started, after the estate the game opened on has been put away.
var running := false
var _shots: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("shot"):
		_shots.append([num("shot-at", 0.75), args["shot"]])
	if args.has("burst"):
		var start := num("burst-start", 0.75)
		var gap := num("burst-gap", 0.25)
		for k in int(num("burst-count", 8)):
			_shots.append([start + k * gap, "%s_%02d.png" % [args["burst"], k]])
	_shots.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	if args.has("hover"):
		get_tree().create_timer(num("hover-at", 1.5)).timeout.connect(func(): _point(_at("hover")))
	if args.has("click"):
		get_tree().create_timer(num("click-at", 1.5)).timeout.connect(func(): _click(_at("click")))
	if args.has("quit") and _shots.is_empty():
		get_tree().create_timer(num("quit-at", 3.0)).timeout.connect(get_tree().quit)
	if args.has("run-tests"):
		get_tree().root.add_child.call_deferred(load("res://tests/run_tests.gd").new())
	elif args.has("pacing") or args.has("completion"):
		get_tree().root.add_child.call_deferred(load("res://tests/%s_bot.gd" % ("completion" if args.has("completion") else "pacing")).new())


func has(key: String) -> bool:
	return args.has(key)


func get_arg(key: String, fallback: String = "") -> String:
	return args.get(key, fallback)


func num(key: String, fallback: float) -> float:
	return float(args[key]) if args.has(key) and args[key] != "" else fallback


## "max" for the maxed farm, "demo" for the demo farm, or "" for the player's own; --demo and --maxed are the old names.
func state() -> String:
	if has("max-state") or (has("demo") and has("maxed")):
		return "max"
	if has("demo-state") or has("demo"):
		return "demo"
	return ""


## True for runs that leave the player's farms, settings and window exactly as they were: demo and maxed farms, a new
## farm tried out, read-only checks, --no-save, and the tests and bots.
func no_save() -> bool:
	for flag in ["no-save", "new-farm", "readonly", "run-tests", "pacing", "completion"]:
		if has(flag):
			return true
	for arg in OS.get_cmdline_args():
		if String(arg).begins_with("res://tests/"):
			return true
	return state() != ""


## True for the tests and the bots, which play the rules themselves rather than the estate.
func checking() -> bool:
	return has("run-tests") or has("pacing") or has("completion")


func _process(delta: float) -> void:
	time += delta
	while not _shots.is_empty() and time >= _shots[0][0]:
		_take_shot(_shots.pop_front()[1], _shots.is_empty())


func _take_shot(path: String, last: bool) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)
	if last and args.has("quit"):
		get_tree().quit()


## A point given in interface pixels, in the window's own pixels.
func _at(key: String) -> Vector2:
	var xy: PackedStringArray = args[key].split(",")
	return Vector2(float(xy[0]), float(xy[1])) * Windowing.ui_scale


func _point(at: Vector2) -> void:
	for k in 2:
		var m := InputEventMouseMotion.new()
		m.position = at + Vector2(k, 0)
		m.global_position = m.position
		m.relative = Vector2(1, 0)
		get_viewport().push_input(m)


func _click(at: Vector2) -> void:
	_point(at)
	for pressed in [true, false]:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = pressed
		b.position = at
		b.global_position = at
		get_viewport().push_input(b)
