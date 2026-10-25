extends Node
## Switches between the full window and the desktop strip, remembers the strip's settings, and keeps power use low.

signal view_changed

const SETTINGS_PATH := "user://window.json"
const BASE := Vector2i(480, 270)
## How many rows of the scene the strip can show, counted up from the bottom: the middle one fits the field, the villa and the storehouse.
const HEIGHTS := [120, 150, 190]
const HEIGHT_NAMES := ["Short", "Medium", "Tall"]
const SIZES := ["Small", "Medium", "Large"]

var strip := false
var transparent := true
var size_index := 0
var height_index := 1
## Where the strip sits on the screen: "bottom" or "top".
var dock := "bottom"
## Focus mode makes the strip quieter and slower, for long stretches of work.
var focus_mode := false
## When on, the strip drifts to whichever zone has the most going on.
var follow := false
var screen := -1
## The strip's horizontal offset from centre, in screen pixels, set by dragging it.
var offset_x := 0
var scale := 1
var _dragging := false
var _drag_from := Vector2i.ZERO
var _drag_start_x := 0
var _focused := true


func _ready() -> void:
	_load()
	if "--strip" in OS.get_cmdline_user_args():
		strip = true
		transparent = not "--solid" in OS.get_cmdline_user_args()
	_apply.call_deferred()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
			_update_fps()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
			_update_fps()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_strip"):
		toggle_strip()
	elif event.is_action_pressed("reset_strip") and strip:
		offset_x = 0
		_apply()
		_save()


func _input(event: InputEvent) -> void:
	if not strip:
		return
	# A borderless strip has no title bar, so dragging with the right mouse button slides it along the screen.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging = event.pressed
		_drag_from = DisplayServer.mouse_get_position()
		_drag_start_x = offset_x
		if not event.pressed:
			_save()
	elif event is InputEventMouseMotion and _dragging:
		offset_x = _drag_start_x + DisplayServer.mouse_get_position().x - _drag_from.x
		_place_strip()


func toggle_strip() -> void:
	strip = not strip
	_apply()
	_save()


func set_transparent(on: bool) -> void:
	transparent = on
	_apply()
	_save()


func cycle_size() -> void:
	size_index = (size_index + 1) % SIZES.size()
	_apply()
	_save()


func cycle_height() -> void:
	height_index = (height_index + 1) % HEIGHTS.size()
	_apply()
	_save()


func toggle_dock() -> void:
	dock = "top" if dock == "bottom" else "bottom"
	_apply()
	_save()


func set_focus_mode(on: bool) -> void:
	focus_mode = on
	_apply()
	_save()


func set_follow(on: bool) -> void:
	follow = on
	_save()


func strip_rows() -> int:
	return int(HEIGHTS[height_index])


## The strip window's polygon of clickable area, in game pixels of the visible view; everything outside lets clicks through to the desktop.
func set_click_area(points: PackedVector2Array) -> void:
	if not (strip and transparent):
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
		return
	var screen_points := PackedVector2Array()
	for p in points:
		screen_points.append(p * scale)
	DisplayServer.window_set_mouse_passthrough(screen_points)


func _apply() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	if screen >= 0 and screen < DisplayServer.get_screen_count() and win.current_screen != screen:
		win.current_screen = screen
	if strip:
		win.content_scale_size = Vector2i(BASE.x, strip_rows())
		win.borderless = true
		win.always_on_top = true
		# The window is created transparent-capable (see project settings), because OpenGL cannot add an alpha channel later; here only the drawing changes.
		get_viewport().transparent_bg = transparent
		_place_strip()
	else:
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
		win.content_scale_size = BASE
		win.always_on_top = false
		win.borderless = false
		get_viewport().transparent_bg = false
		var usable := DisplayServer.screen_get_usable_rect(win.current_screen)
		scale = clampi(mini((usable.size.x - 80) / BASE.x, (usable.size.y - 80) / BASE.y), 1, 6)
		win.size = BASE * scale
		win.position = usable.position + (usable.size - win.size) / 2
	_update_fps()
	# Focus mode turns everything down a little, so a strip left running all day stays in the background.
	AudioServer.set_bus_volume_db(0, -8.0 if strip and focus_mode else 0.0)
	view_changed.emit()


func _place_strip() -> void:
	var win := get_window()
	var usable := DisplayServer.screen_get_usable_rect(win.current_screen)
	# The strip may take at most 40% of the screen's height; larger sizes shrink to fit smaller screens.
	var max_scale := maxi(1, int(usable.size.y * 0.4) / strip_rows())
	scale = clampi([2, 3, 4][size_index], 1, max_scale)
	scale = mini(scale, maxi(1, usable.size.x / BASE.x))
	# As wide as the painted background, which extends 16 pixels past each side of the main view.
	var width := mini(usable.size.x, (BASE.x + 32) * scale)
	win.size = Vector2i(width, strip_rows() * scale)
	var x := usable.position.x + (usable.size.x - width) / 2 + offset_x
	x = clampi(x, usable.position.x, usable.position.x + usable.size.x - width)
	# The usable rect already leaves out the taskbar, wherever it sits, so the strip never covers it.
	var y := usable.position.y if dock == "top" else usable.position.y + usable.size.y - win.size.y
	win.position = Vector2i(x, y)


func _update_fps() -> void:
	# A cozy game left running all day should barely touch the CPU or battery.
	var fps := 60
	if strip or not _focused:
		fps = 30
	if Settings.low_power or (strip and focus_mode):
		fps = 15 if not _focused or focus_mode else 30
	Engine.max_fps = fps


func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	strip = bool(d.get("strip", false))
	transparent = bool(d.get("transparent", true))
	size_index = clampi(int(d.get("size_index", 0)), 0, SIZES.size() - 1)
	offset_x = int(d.get("offset_x", 0))
	height_index = clampi(int(d.get("height_index", 1)), 0, HEIGHTS.size() - 1)
	dock = String(d.get("dock", "bottom"))
	focus_mode = bool(d.get("focus_mode", false))
	follow = bool(d.get("follow", false))
	screen = int(d.get("screen", -1))


func _save() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"strip": strip, "transparent": transparent, "size_index": size_index, "offset_x": offset_x,
			"height_index": height_index, "dock": dock, "focus_mode": focus_mode, "follow": follow, "screen": get_window().current_screen}))
