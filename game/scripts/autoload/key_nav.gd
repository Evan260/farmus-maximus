extends Node
## Tells whether the interface is worked with the keyboard or a gamepad, so its buttons take the focus only then, and
## whether the gamepad is the input in use, so its button pictures show beside the key hints. With a gamepad, the right
## stick scrolls the list of the window that has the focus, and the shoulder buttons scroll it a page at a time.

## A key that moves through the buttons was pressed while none of them was chosen, or the keyboard was just picked up.
signal wanted(event: InputEvent)
## The gamepad became, or stopped being, the input in use.
signal pad_changed(on: bool)

const KEYS := ["ui_focus_next", "ui_focus_prev", "ui_left", "ui_right", "ui_up", "ui_down", "ui_accept"]
## The picture in assets/sprites/pad/ for each gamepad button.
const PAD_PICTURES := {JOY_BUTTON_B: "b", JOY_BUTTON_X: "x", JOY_BUTTON_Y: "y", JOY_BUTTON_LEFT_SHOULDER: "lb",
	JOY_BUTTON_RIGHT_SHOULDER: "rb", JOY_BUTTON_RIGHT_STICK: "rs"}
## The names --pad-keys takes, for checks without a gamepad.
const PAD_NAMES := {"A": JOY_BUTTON_A, "B": JOY_BUTTON_B, "X": JOY_BUTTON_X, "Y": JOY_BUTTON_Y,
	"LB": JOY_BUTTON_LEFT_SHOULDER, "RB": JOY_BUTTON_RIGHT_SHOULDER, "Start": JOY_BUTTON_START,
	"Up": JOY_BUTTON_DPAD_UP, "Down": JOY_BUTTON_DPAD_DOWN, "Left": JOY_BUTTON_DPAD_LEFT, "Right": JOY_BUTTON_DPAD_RIGHT}
## Interface pixels a second that a list scrolls with the right stick pushed all the way.
const LIST_SPEED := 300.0

## True from the first Tab, arrow key, Enter or Space until the mouse is clicked.
var keyboard := false
## Set by --pad, so checks on a computer without a gamepad can work the game as if one were connected.
var simulated := false
var _pad := false
var _scrolled := 0.0


func _ready() -> void:
	simulated = Dev.has("pad")
	_pad = pad_connected()
	# Godot's own interface actions answer only keys, so A presses the chosen button and B backs out, as on a console.
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var press := InputEventJoypadButton.new()
		press.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], press):
			InputMap.action_add_event(pair[0], press)
	for list in [["list_up", -1.0], ["list_down", 1.0]]:
		if not InputMap.has_action(list[0]):
			InputMap.add_action(list[0], 0.3)
			var tilt := InputEventJoypadMotion.new()
			tilt.axis = JOY_AXIS_RIGHT_Y
			tilt.axis_value = list[1]
			InputMap.action_add_event(list[0], tilt)
	Input.joy_connection_changed.connect(func(_device: int, connected: bool): _set_pad(connected or pad_connected()))
	if Dev.has("pad-keys"):
		var names := Dev.get_arg("pad-keys").split(",")
		for k in names.size():
			get_tree().create_timer(Dev.num("keys-at", 1.5) + k * 0.25).timeout.connect(_press.bind(names[k]))


## Whether buttons take the focus: while the keyboard is in use, or whenever a gamepad is connected.
func active() -> bool:
	return keyboard or pad_connected()


func pad_connected() -> bool:
	return simulated or not Input.get_connected_joypads().is_empty()


## True while the gamepad is the input in use: from its last press until a key or a click.
func using_pad() -> bool:
	return _pad


## The picture of a gamepad button, from PAD_PICTURES, or null for a button the game has no picture of.
static func pad_picture(button: JoyButton) -> Texture2D:
	return load("res://assets/sprites/pad/%s.png" % PAD_PICTURES[button]) if PAD_PICTURES.has(button) else null


func _set_pad(on: bool) -> void:
	if on != _pad:
		_pad = on
		pad_changed.emit(on)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		_set_pad(true)
	if event is InputEventMouseButton and event.pressed:
		keyboard = false
		_set_pad(false)
		_drop_button_focus.call_deferred()
	elif event is InputEventKey and event.pressed:
		_set_pad(false)
		if KEYS.any(func(a: String) -> bool: return event.is_action_pressed(a, true)):
			var was := keyboard
			keyboard = true
			if not was or get_viewport().gui_get_focus_owner() == null:
				wanted.emit(event)
	elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		var list := open_list()
		if list and not _turns_pages(list):
			var page := list.size.y * 0.8 * (-1.0 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1.0)
			list.scroll_vertical += roundi(page)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var push := Input.get_axis("list_up", "list_down") if pad_connected() else 0.0
	if push == 0.0:
		_scrolled = 0.0
		return
	var list := open_list()
	if list == null:
		return
	_scrolled += push * LIST_SPEED * delta
	var step := int(_scrolled)
	_scrolled -= step
	list.scroll_vertical += step


## The list that scrolls in the window holding the focus: the nearest one around the focused button that has more to
## show than fits, or null.
func open_list() -> ScrollContainer:
	var at := get_viewport().gui_get_focus_owner()
	while at:
		var lists: Array = ([at] if at is ScrollContainer else []) + at.find_children("*", "ScrollContainer", true, false)
		for s in lists:
			var bar: VScrollBar = s.get_v_scroll_bar()
			if s.is_visible_in_tree() and bar.max_value > bar.page + 1.0:
				return s
		at = at.get_parent() as Control
	return null


## Whether the list is in a window, such as the journal, whose shoulder buttons turn its pages instead.
func _turns_pages(list: Node) -> bool:
	while list:
		if list.has_meta("turns_pages"):
			return true
		list = list.get_parent()
	return false


## Presses a gamepad button named as in PAD_NAMES, or tilts the right stick down or up for a moment with RDown or RUp.
func _press(name: String) -> void:
	if name in ["RDown", "RUp"]:
		for value in [1.0 if name == "RDown" else -1.0, 0.0]:
			var tilt := InputEventJoypadMotion.new()
			tilt.axis = JOY_AXIS_RIGHT_Y
			tilt.axis_value = value
			Input.parse_input_event(tilt)
			if value != 0.0:
				await get_tree().create_timer(0.4).timeout
		return
	for pressed in [true, false]:
		var b := InputEventJoypadButton.new()
		b.button_index = PAD_NAMES.get(name, JOY_BUTTON_A)
		b.pressed = pressed
		Input.parse_input_event(b)


## A clicked button keeps no focus, so Space or Enter never presses a button the player cannot see is chosen.
func _drop_button_focus() -> void:
	if pad_connected():
		return
	var held := get_viewport().gui_get_focus_owner()
	if held is BaseButton:
		held.release_focus()
