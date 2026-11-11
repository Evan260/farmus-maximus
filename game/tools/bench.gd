extends Node
## Measures how smoothly one scene runs: --bench=NAME [--bench-seconds=20 --bench-warmup=3 --bench-out=FILE].
## NAME "estate" pans back and forth across the whole estate and "journal" turns the journal's pages; any other name
## measures the scene the other flags opened. The results are appended to FILE as one line of JSON.
## --bench-skip=NAME stops every node whose script path contains NAME from processing, to see what its scripts cost.
## "windows" opens and closes every window, the market town and the farmhouse in turn, to show anything that piles up.
## "minimised" minimises the window and keeps the game's own frame rate cap, to show what a game left minimised costs.
## --bench-speed=N runs the farm N times faster. Objects, nodes, orphans and memory are sampled every ten seconds.

const PAN_SPEED := 300.0
const HISTOGRAM := 10000
const PAGES := ["Goods", "Buildings", "Helpers", "Animals", "Finds", "Sightings", "Achievements", "Crops"]
const WINDOWS := ["journal", "helpers", "store", "settings", "upgrades", "companions", "building:mill", "building:villa", "town", "inside"]

var scene := ""
var seconds := 20.0
var warmup := 3.0
var out := ""
var _clock := 0.0
var _last_usec := 0
## Running totals rather than every frame's numbers, so a long run measures memory without growing its own.
var _frames := 0
var _sums := {"frame": 0.0, "process": 0.0, "scripts": 0.0, "draw_calls": 0.0, "objects": 0.0}
## How many frames took each tenth of a millisecond, for the slowest one percent.
var _histogram := PackedInt32Array()
var _first: Node
var _start := {}
var _pan_dir := 1.0
var _page := 0
var _page_timer := 0.0
var _window := 0
var _series: Array = []
var _sample_timer := 0.0


func _ready() -> void:
	scene = Dev.get_arg("bench")
	seconds = Dev.num("bench-seconds", 20.0)
	warmup = Dev.num("bench-warmup", 3.0)
	out = Dev.get_arg("bench-out", "user://bench.jsonl")
	process_priority = 100000
	_histogram.resize(HISTOGRAM)
	# A node that processes before every other one marks when the frame's scripts begin.
	_first = Node.new()
	_first.process_priority = -100000
	_first.set_script(_Mark)
	add_child(_first)


func _process(delta: float) -> void:
	if scene == "minimised":
		if get_window().mode != Window.MODE_MINIMIZED:
			get_window().mode = Window.MODE_MINIMIZED
	else:
		# The frame rate is left uncapped so the frame time shows the work done, not the wait for the screen.
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var now := Time.get_ticks_usec()
	_clock += delta
	_drive(delta)
	if _clock < warmup:
		_last_usec = now
		return
	if _start.is_empty():
		_start = _monitors()
	_sample_timer -= delta
	if _sample_timer <= 0.0:
		_sample_timer = 10.0
		_series.append(_monitors())
	var frame := (now - _last_usec) / 1000.0
	_last_usec = now
	_frames += 1
	_histogram[mini(int(frame * 10.0), HISTOGRAM - 1)] += 1
	_sums["frame"] += frame
	_sums["process"] += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_sums["scripts"] += (now - _first.get("at")) / 1000.0
	_sums["draw_calls"] += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_sums["objects"] += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	if _clock >= warmup + seconds:
		_finish()


func _drive(delta: float) -> void:
	var m: Estate = Dev.m
	if m == null:
		return
	if Dev.has("bench-speed"):
		Game.speed = Dev.num("bench-speed", 1.0)
	if Dev.has("bench-skip") and Engine.get_process_frames() % 60 == 0:
		_skip(get_tree().root, Dev.get_arg("bench-skip"))
	if scene == "estate":
		var edge := maxf(0.0, m.estate_width - m._view_size().x)
		if m.cam_x >= edge - 1.0:
			_pan_dir = -1.0
		elif m.cam_x <= 1.0:
			_pan_dir = 1.0
		m._pan_by(_pan_dir * PAN_SPEED * delta)
	elif scene == "journal":
		_page_timer -= delta
		if _page_timer <= 0.0 and m.hud._journal and m.hud._journal.is_inside_tree():
			_page_timer = 1.5
			m.hud._journal._turn_to(PAGES[_page % PAGES.size()])
			_page += 1
	elif scene == "windows":
		_page_timer -= delta
		if _page_timer <= 0.0:
			_page_timer = 2.0
			_next_window(m)


func _next_window(m: Estate) -> void:
	if m.market.visible:
		m.market.leave()
		return
	if m.interior.visible:
		m.interior.leave()
		return
	if m.hud.close_windows():
		return
	var which: String = WINDOWS[_window % WINDOWS.size()]
	_window += 1
	if which == "town":
		m.go_to_town()
	elif which == "inside":
		m.go_inside()
	elif which.begins_with("building:"):
		m.hud.show_building(which.trim_prefix("building:"))
	else:
		m.hud.open_window(which)


func _skip(node: Node, name: String) -> void:
	var script: Script = node.get_script()
	if script and script.resource_path.contains(name) and node != self:
		node.set_process(false)
	for child in node.get_children():
		_skip(child, name)


func _monitors() -> Dictionary:
	return {
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"texture_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
	}


func _mean(key: String) -> float:
	return _sums[key] / maxf(1.0, _frames)


## The mean of the slowest one percent of frames, to the nearest tenth of a millisecond.
func _worst() -> float:
	var left := maxi(1, _frames / 100)
	var total := 0.0
	var counted := 0
	for bin in range(HISTOGRAM - 1, -1, -1):
		var take := mini(_histogram[bin], left - counted)
		total += take * (bin + 0.5) / 10.0
		counted += take
		if counted >= left:
			break
	return total / maxf(1.0, counted)


func _canvas_items(node: Node) -> int:
	var count := 1 if node is CanvasItem and node.is_visible_in_tree() else 0
	for child in node.get_children():
		count += _canvas_items(child)
	return count


func _finish() -> void:
	set_process(false)
	var end := _monitors()
	var result := {
		"scene": scene,
		"frames": _frames,
		"fps": _frames / maxf(0.001, seconds),
		"frame_ms": _mean("frame"),
		"worst1_ms": _worst(),
		"process_max_ms": _mean("process"),
		"scripts_ms": _mean("scripts"),
		"draw_calls": _mean("draw_calls"),
		"objects_drawn": _mean("objects"),
		"canvas_items": _canvas_items(get_tree().root),
		"start": _start,
		"end": end,
		"series": _series,
	}
	var f := FileAccess.open(out, FileAccess.READ_WRITE if FileAccess.file_exists(out) else FileAccess.WRITE)
	f.seek_end()
	f.store_line(JSON.stringify(result))
	f.close()
	print("bench ", JSON.stringify(result))
	get_tree().quit()


static var _Mark: GDScript = _mark_script()


static func _mark_script() -> GDScript:
	var g := GDScript.new()
	g.source_code = "extends Node
var at := 0
func _process(_d: float) -> void:
	at = Time.get_ticks_usec()
"
	g.reload()
	return g
