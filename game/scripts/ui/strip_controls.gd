extends PanelContainer
## The desktop strip's own controls, along its top right corner: look left and right along the estate, make the strip
## smaller or larger, drag it along the screen or drag its width, move it to the top or bottom of the screen, and show
## or hide its painted sky. They fade in while the pointer is over the strip and away again when it leaves, so the
## strip is only the farm the rest of the time.

## Asks the estate to look one zone along, -1 to the left and 1 to the right.
signal pan_requested(step: int)

const ICONS := {
	"left": ["..X....", ".XX....", "XXXXXXX", ".XX....", "..X...."],
	"right": ["....X..", "....XX.", "XXXXXXX", "....XX.", "....X.."],
	"smaller": [".......", ".......", "XXXXXXX", ".......", "......."],
	"larger": ["...X...", "...X...", "XXXXXXX", "...X...", "...X..."],
	"move": ["...X...", "..XXX..", ".X.X.X.", "XXXXXXX", ".X.X.X.", "..XXX..", "...X..."],
	"width": [".X...X.", "XX...XX", "XXXXXXX", "XX...XX", ".X...X."],
	"to_top": ["XXXXXXX", ".......", "...X...", "..XXX..", ".X.X.X.", "...X...", "...X..."],
	"to_bottom": ["...X...", "...X...", ".X.X.X.", "..XXX..", "...X...", ".......", "XXXXXXX"],
	"sky": [".......", "..XX...", ".XXXXX.", "XXXXXXX", "XXXXXXX"],
	"no_sky": [".......", "..XX...", ".X..XX.", "X.....X", "XXXXXXX"],
}

var _scale_label: Label
var _dock_button: Button
var _sky_button: Button
## The drag in progress: "move" or "width", where the pointer started on the screen, and the value it started from.
var _drag := ""
var _drag_from := Vector2i.ZERO
var _drag_start := 0
## For checking how the controls look: shown all the time, as if the pointer were over the strip.
var _pinned := "--strip-controls" in OS.get_cmdline_user_args()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	var row := UiKit.row(self)
	row.add_theme_constant_override("separation", 2)
	_icon_button(row, "left", tr("Look left"), func(): pan_requested.emit(-1))
	_icon_button(row, "smaller", tr("Smaller"), func(): Windowing.change_strip_scale(-1))
	_scale_label = UiKit.label(row)
	_icon_button(row, "larger", tr("Larger"), func(): Windowing.change_strip_scale(1))
	_grip(_icon_button(row, "move", tr("Drag to move the strip"), Callable()), "move")
	_grip(_icon_button(row, "width", tr("Drag to make the strip wider or narrower"), Callable()), "width")
	_dock_button = _icon_button(row, "to_top", "", func(): Windowing.toggle_dock())
	_sky_button = _icon_button(row, "sky", "", func(): Windowing.set_transparent(not Windowing.transparent))
	_icon_button(row, "right", tr("Look right"), func(): pan_requested.emit(1))


## Shows the controls while the pointer is over the strip or a drag is under way, read from the pointer's place on the
## screen, which the game knows even over the see-through parts of the strip that let clicks through.
func _process(delta: float) -> void:
	var win := get_window()
	var over := Windowing.strip and Rect2i(win.position, win.size).has_point(DisplayServer.mouse_get_position())
	var target := 1.0 if over or _pinned or _drag != "" else 0.0
	modulate.a = move_toward(modulate.a, target, delta / 0.25)
	visible = Windowing.strip and modulate.a > 0.0
	if not visible:
		return
	_scale_label.text = "%dx" % Windowing.scale
	var top := Windowing.dock == "top"
	_dock_button.icon = _texture("to_bottom" if top else "to_top")
	_dock_button.tooltip_text = tr("Move the strip to the bottom") if top else tr("Move the strip to the top")
	_sky_button.icon = _texture("no_sky" if Windowing.transparent else "sky")
	_sky_button.tooltip_text = tr("Show the painted sky") if Windowing.transparent else tr("Show only the farm")
	# Along the top right corner, clear of the purse bar at the top left.
	var parent := get_parent() as Control
	position = Vector2(roundf(parent.size.x - size.x - 4.0), 4.0)


## The controls' area while they show, which must stay clickable when the rest of the sky lets clicks through.
func area() -> Rect2:
	return get_global_rect() if visible else Rect2()


func _icon_button(parent: Node, icon: String, tip: String, action: Callable) -> Button:
	var b := Button.new()
	b.icon = _texture(icon)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.expand_icon = false
	if action.is_valid():
		b.pressed.connect(func(): Sfx.play("click", -8.0))
		b.pressed.connect(action)
	parent.add_child(b)
	return b


## Makes a button a handle: held down and dragged, it moves the strip or changes its width, following the pointer
## across the screen, and the new place is remembered when it is let go.
func _grip(b: Button, kind: String) -> void:
	b.mouse_default_cursor_shape = Control.CURSOR_MOVE if kind == "move" else Control.CURSOR_HSIZE
	b.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag = kind
				_drag_from = DisplayServer.mouse_get_position()
				_drag_start = Windowing.offset_x if kind == "move" else get_window().size.x
			elif _drag != "":
				_drag = ""
				Windowing.finish_strip_drag()
		elif event is InputEventMouseMotion and _drag == kind:
			var dx := DisplayServer.mouse_get_position().x - _drag_from.x
			if kind == "move":
				Windowing.move_strip(_drag_start + dx)
			else:
				# The strip grows from its middle, so the edge under the pointer follows it.
				Windowing.set_strip_width(_drag_start + dx * 2))


static var _textures := {}


## A small pixel icon in the interface's ink, drawn from its picture above.
static func _texture(name: String) -> Texture2D:
	if not _textures.has(name):
		var rows: Array = ICONS[name]
		var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
		var top := (7 - rows.size()) / 2
		for y in rows.size():
			for x in 7:
				if String(rows[y])[x] == "X":
					img.set_pixel(x, top + y, UiKit.INK)
		_textures[name] = ImageTexture.create_from_image(img)
	return _textures[name]
