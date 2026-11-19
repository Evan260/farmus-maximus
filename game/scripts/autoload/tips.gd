extends CanvasLayer
## Tooltips drawn in the interface's own pixels, so they grow with the interface size like everything else.
## A control asks for one with Ui.tip_on(control, text); the text is read every frame, so it can change while shown.
## A phone has no pointer resting anywhere, so there a finger held still on a control shows its tip instead.

const DELAY := 0.35
const WRAP := 170.0
## How long a tip shown by a held finger stays after the finger lifts.
const SHOW_FOR := 4.0

## True from a finger resting still long enough to ask what is under it until the next touch, so the lift does not act.
var long_press := false

var _root: Control
var _panel: PanelContainer
var _label: Label
var _owner: Control
var _wait := 0.0
## Where the pointer last moved, in window pixels, as the interface saw it.
var _mouse := Vector2.ZERO
## Where the finger touched down, or INF while no finger rests; how far it has wandered and how long it has rested.
var _press_at := Vector2.INF
var _moved := 0.0
var _pressed_for := 0.0
var _shown_left := 0.0


func _ready() -> void:
	layer = 60
	_root = Control.new()
	_root.theme = UiTheme.build()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = UiTheme.CREAM
	box.border_color = UiTheme.INK
	box.set_border_width_all(1)
	box.content_margin_left = 3
	box.content_margin_right = 3
	box.content_margin_top = 2
	box.content_margin_bottom = 3
	_panel.add_theme_stylebox_override("panel", box)
	_root.add_child(_panel)
	_label = Ui.label(_panel)
	_panel.visible = false
	Windowing.view_changed.connect(_fit)
	_fit()


func _fit() -> void:
	scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_root.size = (get_viewport().get_visible_rect().size / Windowing.ui_scale).floor()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = event.position
		if _press_at != Vector2.INF:
			_moved = maxf(_moved, event.position.distance_to(_press_at))
	elif Windowing.phone and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			long_press = false
			_press_at = event.position
			_mouse = event.position
			_moved = 0.0
			_pressed_for = 0.0
			_owner = null
			_panel.visible = false
		else:
			_press_at = Vector2.INF


func _process(delta: float) -> void:
	if Windowing.phone:
		_process_touch(delta)
		return
	var owner := _tip_owner(get_viewport().gui_get_hovered_control())
	if owner == null or not Settings.tooltips or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or get_viewport().gui_is_dragging():
		_owner = null
		_panel.visible = false
		_wait = 0.0
		return
	if owner != _owner:
		_owner = owner
		_wait = 0.0
		_panel.visible = false
	_wait += delta
	if _wait < DELAY:
		return
	_show(tr(str(owner.get_meta("tip"))))


func _process_touch(delta: float) -> void:
	if _press_at != Vector2.INF and not long_press:
		_pressed_for += delta
		if Touch.is_hold(_pressed_for, _moved, Windowing.touch_slop()):
			long_press = true
			var under := get_viewport().gui_get_hovered_control()
			var owner := _tip_owner(under)
			if owner != null and Settings.tooltips:
				_cancel_press(under)
				_owner = owner
				_shown_left = SHOW_FOR
	if _owner != null and is_instance_valid(_owner) and _owner.is_visible_in_tree() and _shown_left > 0.0:
		if _press_at == Vector2.INF:
			_shown_left -= delta
		_show(tr(str(_owner.get_meta("tip"))))
	else:
		_owner = null
		_panel.visible = false


## A button whose tip was asked for forgets its press, as disabling it for a moment makes it do.
func _cancel_press(c: Control) -> void:
	var n: Node = c
	for i in 4:
		if n is BaseButton:
			if not n.disabled:
				n.disabled = true
				n.disabled = false
			return
		if not n is Control:
			return
		n = n.get_parent()


func _tip_owner(c: Control) -> Control:
	var n: Node = c
	for i in 4:
		if not n is Control:
			return null
		if n.has_meta("tip") and str(n.get_meta("tip")) != "" and (n as Control).is_visible_in_tree():
			return n
		n = n.get_parent()
	return null


func _show(text: String) -> void:
	# The language can change while the game runs, and with it the font, so the tip follows it.
	if _root.theme.default_font != UiTheme.ui_font():
		_root.theme = UiTheme.build()
	var lines := _wrap(text)
	if _label.text != lines or not _panel.visible:
		_label.text = lines
		_panel.visible = true
		_panel.reset_size()
	var mouse := _mouse / Windowing.ui_scale
	var room := _root.size
	var pos := mouse + Vector2(8, 12)
	# A finger covers what is under it and below, so on a phone the tip stands above it.
	if Windowing.phone:
		pos = Vector2(mouse.x - _panel.size.x / 2.0, mouse.y - _panel.size.y - 14)
		if pos.y < 2:
			pos.y = mouse.y + 18
		pos.x = clampf(pos.x, 2, room.x - _panel.size.x - 2)
	if pos.x + _panel.size.x > room.x - 2:
		pos.x = mouse.x - _panel.size.x - 4
	if pos.y + _panel.size.y > room.y - 2:
		pos.y = mouse.y - _panel.size.y - 4
	_panel.position = pos.max(Vector2(2, 2)).floor()


## Breaks a tip into lines by hand, between letters where a language leaves no spaces, as a self-sizing panel can't.
func _wrap(text: String) -> String:
	var font := UiTheme.ui_font()
	var size := UiTheme.text_size()
	var out := PackedStringArray()
	var line := ""
	for word in text.split(" "):
		var next := word if line == "" else line + " " + word
		if font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= WRAP:
			line = next
			continue
		if line != "":
			out.append(line)
		line = ""
		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= WRAP:
			line = word
			continue
		for c in word:
			if line != "" and font.get_string_size(line + c, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > WRAP:
				out.append(line)
				line = ""
			line += c
	out.append(line)
	return "\n".join(out)
