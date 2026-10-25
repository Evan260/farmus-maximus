extends Node
## Switches between the full window and the desktop strip, remembers the strip's settings, and keeps power use low.

signal view_changed

const SETTINGS_PATH := "user://window.json"
const BASE := Vector2i(480, 270)
## How many rows of the scene the strip shows, counted up from the bottom: enough for the field, the villa and the storehouse.
const STRIP_ROWS := 150
const SIZES := ["Small", "Medium", "Large"]

var strip := false
var transparent := true
var size_index := 0
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


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F10:
				toggle_strip()
			KEY_F9:
				if strip:
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
	if strip:
		win.content_scale_size = Vector2i(BASE.x, STRIP_ROWS)
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
	view_changed.emit()


func _place_strip() -> void:
	var win := get_window()
	var usable := DisplayServer.screen_get_usable_rect(win.current_screen)
	# The strip may take at most 40% of the screen's height; larger sizes shrink to fit smaller screens.
	var max_scale := maxi(1, int(usable.size.y * 0.4) / STRIP_ROWS)
	scale = clampi([2, 3, 4][size_index], 1, max_scale)
	scale = mini(scale, maxi(1, usable.size.x / BASE.x))
	# As wide as the painted background, which extends 16 pixels past each side of the main view.
	var width := mini(usable.size.x, (BASE.x + 32) * scale)
	win.size = Vector2i(width, STRIP_ROWS * scale)
	var x := usable.position.x + (usable.size.x - width) / 2 + offset_x
	x = clampi(x, usable.position.x, usable.position.x + usable.size.x - width)
	win.position = Vector2i(x, usable.position.y + usable.size.y - win.size.y)


func _update_fps() -> void:
	# A cozy game left running all day should barely touch the CPU or battery.
	Engine.max_fps = 30 if strip or not _focused else 60


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


func _save() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"strip": strip, "transparent": transparent, "size_index": size_index, "offset_x": offset_x}))
