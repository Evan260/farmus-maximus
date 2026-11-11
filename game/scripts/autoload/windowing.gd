extends Node
## Switches between the full window and the desktop strip, remembers the strip's settings, and keeps power use low.

signal view_changed

const BASE := Vector2i(480, 270)
## The narrowest stretch of the estate a tall window shows, in estate pixels: a little over half a zone.
const NARROWEST := 300
## How many rows of the scene the strip shows, counted up from the bottom: enough for the field, the villa and the storehouse.
const STRIP_ROWS := 166
## The strip's narrowest and widest view in estate pixels: room for its controls at one end, and no wider than the
## painted sky behind it reaches.
const STRIP_MIN_VIEW := 200
const STRIP_MAX_VIEW := 1440

var strip := false
var transparent := true
## Screen pixels per estate pixel the player has chosen for the strip; a smaller screen may hold fewer.
var strip_scale := 2
## The strip's width in screen pixels, set by dragging it wider or narrower; 0 until the player first does.
var strip_width := 0
## Where the strip sits on the screen: "bottom" or "top".
var dock := "bottom"
## Focus mode makes the strip quieter and slower, for long stretches of work.
var focus_mode := false
## When on, the strip drifts to whichever zone has the most going on.
var follow := false
## The monitor the window was on when the game last closed, which it is moved back to once, as the game starts.
var screen := -1
## The strip's horizontal offset from centre, in screen pixels, set by dragging it.
var offset_x := 0
## How far the strip sits in from the screen edge it is docked to, in screen pixels, set by dragging it up or down.
var offset_y := 0
## The narrowest the strip may be, in screen pixels, so its two bars always fit side by side; the interface sets it.
var strip_min_width := 0
## True while the strip is being dragged along the screen or wider; see start_strip_drag.
var strip_dragging := false
## Screen pixels per estate pixel: the largest whole number that still shows the full height of the scene.
var scale := 1
## Screen pixels per interface pixel, which the player can set larger or smaller than the estate's.
var ui_scale := 1
var _dragging := false
var _drag_from := Vector2i.ZERO
var _drag_start_x := 0
var _focused := true
## Whether the window was maximized or fullscreen before it became the strip, so leaving the strip brings that back.
var _mode_before_strip := Window.MODE_WINDOWED
## The window's mode before it went full screen, so F11 brings back a maximised window as it was.
var _mode_before_fullscreen := Window.MODE_WINDOWED


func _ready() -> void:
	_load()
	if "--strip" in OS.get_cmdline_user_args():
		strip = true
		transparent = not "--solid" in OS.get_cmdline_user_args()
	# A test run at a set window size is always the full window, whatever the player last left it as.
	elif Array(OS.get_cmdline_user_args()).any(func(arg): return String(arg).begins_with("--window=")):
		strip = false
	get_window().size_changed.connect(_on_resized)
	Settings.changed.connect(_on_resized)
	Settings.changed.connect(_apply_volume)
	_apply.call_deferred()
	_restore_fullscreen.call_deferred()
	# Minimising does not tell the game, so it looks once a second.
	var look := Timer.new()
	look.wait_time = 1.0
	look.timeout.connect(func() -> void: if not strip_dragging: _update_fps())
	add_child(look)
	look.start()


func _on_resized() -> void:
	_rescale()
	view_changed.emit()


## Picks the pixel scales from the window's size; the estate's viewport is then the window divided by that scale, so it always fills the window.
func _rescale() -> void:
	var size := get_window().size
	# In the strip the interface is sized for the screen rather than the strip, so it stays readable however small the
	# strip is made: two interface pixels to the screen pixel on an ordinary screen, more on a very large one.
	if strip:
		var screen_tall := DisplayServer.screen_get_usable_rect(get_window().current_screen).size.y
		ui_scale = clampi(screen_tall / 540 + Settings.ui_scale_step, 1, 4)
		return
	scale = maxi(1, mini(size.x / BASE.x, size.y / BASE.y))
	# A tall narrow window crops a little off each side rather than shrinking the estate under a sea of sky.
	scale = maxi(scale, mini(size.x / NARROWEST, size.y / BASE.y))
	# Recordings for phones choose their own scale, so a portrait frame shows the estate close up.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scale="):
			scale = maxi(1, int(arg.trim_prefix("--scale=")))
	# The money panel and the zone buttons need about 560 interface pixels side by side, and the windows about 225 down.
	var most := maxi(1, mini(size.x / 560, size.y / 225))
	# One step under what fits the window itself, rather than the estate's scale, so a tall narrow window stays readable.
	var fit := maxi(1, mini(size.x / 400, size.y / BASE.y))
	ui_scale = clampi(fit - 1 + Settings.ui_scale_step, 1, maxi(1, most))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
			_update_fps()
			_apply_volume()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
			_update_fps()
			_apply_volume()
		# The window opens next time on the monitor it was closed on.
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save()
			if Settings.fullscreen != is_fullscreen():
				Settings.set_value("fullscreen", is_fullscreen())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
	elif event.is_action_pressed("toggle_strip"):
		toggle_strip()
	elif event.is_action_pressed("reset_strip") and strip:
		offset_x = 0
		offset_y = 0
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


## Full screen belongs to the full window: the strip is always a plain window, so F11 there goes back to the full window.
func toggle_fullscreen() -> void:
	if strip:
		toggle_strip()
		return
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = _mode_before_fullscreen
	else:
		_mode_before_fullscreen = win.mode
		win.mode = Window.MODE_FULLSCREEN
	Settings.set_value("fullscreen", is_fullscreen())


## Whether the full window is full screen, or will be again once the strip is left.
func is_fullscreen() -> bool:
	return get_window().mode == Window.MODE_FULLSCREEN or (strip and _mode_before_strip == Window.MODE_FULLSCREEN)


func _restore_fullscreen() -> void:
	if not Settings.fullscreen or Array(OS.get_cmdline_user_args()).any(func(arg): return String(arg).begins_with("--window=")):
		return
	if strip:
		_mode_before_strip = Window.MODE_FULLSCREEN
	else:
		_mode_before_fullscreen = get_window().mode
		get_window().mode = Window.MODE_FULLSCREEN


func toggle_strip() -> void:
	strip = not strip
	_apply()
	_save()


func set_transparent(on: bool) -> void:
	transparent = on
	# On Windows the outline that lets clicks through also clips what the window draws, so with the painted sky behind
	# the farm the whole strip is drawn and clickable again; the clear strip sets its outline afresh.
	if not on:
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
	_strip_changed()


func change_strip_scale(step: int) -> void:
	var was := scale
	strip_scale = clampi(scale + step, 1, max_strip_scale())
	# The strip keeps the same stretch of the estate in view as it grows or shrinks.
	if strip_width > 0 and was > 0:
		strip_width = strip_width * strip_scale / was
	_strip_changed()


## The largest strip the screen holds: at most 40% of its height.
func max_strip_scale() -> int:
	var usable := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	return mini(maxi(1, int(usable.size.y * 0.4) / STRIP_ROWS), maxi(1, usable.size.x / BASE.x))


## Moves the strip across and up or down the screen while it is dragged; where it is kept when the drag ends.
func move_strip(offset: Vector2i) -> void:
	offset_x = offset.x
	# Dragged up a strip at the bottom moves in from its edge, and dragged down a strip at the top does.
	offset_y = -offset.y if dock == "bottom" else offset.y
	_place_strip()
	_redraw_now()


## Where the strip is dragged from: across from the middle, and up or down from the bottom or down from the top.
func strip_offset() -> Vector2i:
	return Vector2i(offset_x, -offset_y if dock == "bottom" else offset_y)


## Makes the strip wider or narrower while it is dragged; the width is kept when the drag ends.
## Makes the strip wider or narrower from its right edge while it is dragged, its left edge staying where it is, so
## the window only changes size and never jumps along the screen as well.
func set_strip_width(width: int) -> void:
	var left := get_window().position.x
	strip_width = width
	_place_strip()
	var usable := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	offset_x = left - usable.position.x - (usable.size.x - get_window().size.x) / 2
	_place_strip()
	view_changed.emit()
	_redraw_now()


## Windows shows a grown window's new edge blank until the game next draws, so during a drag it draws at once rather
## than waiting for its next frame.
func _redraw_now() -> void:
	if strip_dragging:
		RenderingServer.force_draw()


## While the strip is dragged it lets no clicks through: on Windows the outline that does so also cuts away what the
## strip draws, and redrawing it on every step of the drag makes the strip flicker. It is drawn afresh once the drag ends.
func start_strip_drag() -> void:
	strip_dragging = true
	# The strip's usual low frame rate would leave each step of the drag on screen half drawn.
	Engine.max_fps = 0
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array())


func finish_strip_drag() -> void:
	strip_dragging = false
	_update_fps()
	view_changed.emit()
	_save()


func toggle_dock() -> void:
	dock = "top" if dock == "bottom" else "bottom"
	offset_y = 0
	_strip_changed()


func set_focus_mode(on: bool) -> void:
	focus_mode = on
	_strip_changed()


## The strip's own settings only change the window while it is the strip; the full window is left exactly as it is.
func _strip_changed() -> void:
	if strip:
		_apply()
	_save()


func set_follow(on: bool) -> void:
	follow = on
	_save()


## The strip window's polygon of clickable area, in game pixels of the visible view; everything outside lets clicks through to the desktop.
func set_click_area(points: PackedVector2Array) -> void:
	if strip_dragging:
		return
	if not (strip and transparent):
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
		return
	var screen_points := PackedVector2Array()
	for p in points:
		screen_points.append(p * scale)
	DisplayServer.window_set_mouse_passthrough(screen_points)


func _apply() -> void:
	var win := get_window()
	# The window itself is drawn at full resolution; the estate scales its own viewport (see main.gd), and the interface its own layer.
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	if screen >= 0 and screen < DisplayServer.get_screen_count() and win.current_screen != screen:
		win.current_screen = screen
	screen = -1
	if strip:
		# Windows keeps a maximized window's frame and size whatever is asked of it, so the strip starts from a plain window.
		if win.mode != Window.MODE_WINDOWED:
			_mode_before_strip = win.mode
			win.mode = Window.MODE_WINDOWED
		win.borderless = true
		win.always_on_top = true
		# The window is created transparent-capable (see project settings), because OpenGL cannot add an alpha channel later; here only the drawing changes.
		get_viewport().transparent_bg = transparent
		_place_strip()
	else:
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
		win.always_on_top = false
		win.borderless = false
		get_viewport().transparent_bg = false
		# A maximized or fullscreen window belongs to Windows, which would keep its frame but draw the game at the new size.
		if win.mode == Window.MODE_WINDOWED:
			var usable := DisplayServer.screen_get_usable_rect(win.current_screen)
			scale = clampi(mini((usable.size.x - 80) / BASE.x, (usable.size.y - 80) / BASE.y), 1, 6)
			win.size = BASE * scale
			for arg in OS.get_cmdline_user_args():
				if arg.begins_with("--window="):
					win.size = Vector2i(int(arg.get_slice("=", 1).get_slice("x", 0)), int(arg.get_slice("x", 1)))
			win.position = usable.position + (usable.size - win.size) / 2
		if _mode_before_strip != Window.MODE_WINDOWED:
			win.mode = _mode_before_strip
			_mode_before_strip = Window.MODE_WINDOWED
	_rescale()
	_update_fps()
	_apply_volume()
	view_changed.emit()


func _apply_volume() -> void:
	# Focus mode turns everything down a little, so a strip left running all day stays in the background.
	var db := linear_to_db(maxf(float(Audio.volumes["Master"]), 0.0001)) + (-8.0 if strip and focus_mode else 0.0)
	# A recording is made while other windows have the focus, so it always keeps its sound.
	var behind := not _focused and Engine.get_write_movie_path() == ""
	if behind and Settings.background_sound == "quieter":
		db -= 12.0
	AudioServer.set_bus_volume_db(0, db)
	AudioServer.set_bus_mute(0, (behind and Settings.background_sound == "muted") or float(Audio.volumes["Master"]) <= 0.001)


func _place_strip() -> void:
	var win := get_window()
	var usable := DisplayServer.screen_get_usable_rect(win.current_screen)
	# The strip may take at most 40% of the screen's height; larger sizes shrink to fit smaller screens.
	scale = clampi(strip_scale, 1, max_strip_scale())
	# Recordings choose the strip's size and width, so it comes out the same on any screen.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scale="):
			scale = maxi(1, int(arg.trim_prefix("--scale=")))
		elif arg.begins_with("--strip-width="):
			strip_width = int(arg.trim_prefix("--strip-width="))
	# Until the player sets a width it is the main view's, with 16 pixels to spare at each side.
	var width := strip_width if strip_width > 0 else (BASE.x + 32) * scale
	width = clampi(width, maxi(STRIP_MIN_VIEW * scale, strip_min_width), mini(usable.size.x, STRIP_MAX_VIEW * scale))
	strip_width = width if strip_width > 0 else 0
	win.size = Vector2i(width, STRIP_ROWS * scale)
	# The strip never slides off the screen, and its offset is held to what fits so a later drag starts from there.
	var room := (usable.size.x - width) / 2
	offset_x = clampi(offset_x, -room, room)
	var x := usable.position.x + room + offset_x
	# The usable rect already leaves out the taskbar, wherever it sits, so the strip never covers it.
	offset_y = clampi(offset_y, 0, maxi(0, usable.size.y - win.size.y))
	var y := usable.position.y + offset_y if dock == "top" else usable.position.y + usable.size.y - win.size.y - offset_y
	win.position = Vector2i(x, y)


func _update_fps() -> void:
	# A cozy game left running all day should barely touch the CPU or battery.
	var fps := 60
	if strip or not _focused:
		fps = 30
	if Settings.low_power or (strip and focus_mode):
		fps = 15 if not _focused or focus_mode else 30
	# A minimised window shows nothing, so the farm only needs to keep its time.
	if get_window().mode == Window.MODE_MINIMIZED:
		fps = 5
	Engine.max_fps = fps


func _load() -> void:
	# Trial runs ignore the player's window settings too, so they always start the same way.
	if not Settings.persist or not Settings.cfg.has_section("window"):
		return
	var d := {}
	for key in Settings.cfg.get_section_keys("window"):
		d[key] = Settings.cfg.get_value("window", key)
	strip = bool(d.get("strip", false))
	transparent = bool(d.get("transparent", true))
	# Older settings kept one of three sizes, 2, 3 or 4 screen pixels to the estate pixel.
	strip_scale = int(d.get("strip_scale", [2, 3, 4][clampi(int(d.get("size_index", 0)), 0, 2)]))
	strip_width = int(d.get("strip_width", 0))
	offset_x = int(d.get("offset_x", 0))
	offset_y = int(d.get("offset_y", 0))
	dock = String(d.get("dock", "bottom"))
	focus_mode = bool(d.get("focus_mode", false))
	follow = bool(d.get("follow", false))
	screen = int(d.get("screen", -1))


func _save() -> void:
	Settings.store("window", {"strip": strip, "transparent": transparent, "strip_scale": strip_scale, "strip_width": strip_width,
		"offset_x": offset_x, "offset_y": offset_y, "dock": dock, "focus_mode": focus_mode, "follow": follow, "screen": get_window().current_screen})
