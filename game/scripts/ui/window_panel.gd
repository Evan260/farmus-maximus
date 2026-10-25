extends PanelContainer
## A centred parchment window with a title and a close button; the interface's panels build their contents inside it.

signal closed

var body: VBoxContainer
var _title: Label
var _refresh_timer := 0.0
var _signature := "-"
## When set, the window keeps this size whatever it shows, so switching tabs never makes it jump.
var fixed_size := Vector2.ZERO


func _init(title := "") -> void:
	var col := VBoxContainer.new()
	add_child(col)
	var head := UiKit.row(col)
	_title = UiKit.label(head, title)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.close_button(head, close)
	body = UiKit.column(col)
	visible = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH


func set_title(text: String) -> void:
	_title.text = text


func open() -> void:
	visible = true
	_signature = ""
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.25
		refresh()


## Rebuilds the contents only when what they show has changed, so buttons are not swapped out from under the pointer.
func refresh() -> void:
	var sig := signature()
	if sig == _signature:
		tick()
		return
	_signature = sig
	UiKit.clear(body)
	body.custom_minimum_size = fixed_size
	build()
	tick()
	UiKit.pad_focus.call_deferred(self)


## A summary of the state this window shows; when it changes, the window is rebuilt.
func signature() -> String:
	return ""


## Creates the window's contents; panels override it.
func build() -> void:
	pass


## Updates text that changes every moment, such as timers, without rebuilding.
func tick() -> void:
	pass
