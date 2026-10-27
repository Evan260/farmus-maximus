extends Control
## Uncle Marcus, who left the farm to the player, stands in the bottom left corner of the screen with a word of advice
## for the next thing to do: plant, harvest, dig more beds, sell at market, and so on. Each new piece of advice slides
## in beside his portrait; clicking him folds the advice away and back. When every step is done he says goodbye.

const PORTRAIT := preload("res://assets/ui/uncle.png")

var _portrait: TextureRect
var _box: PanelContainer
var _text: Label
var _shown_id := ""
var _folded := false
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_portrait = TextureRect.new()
	_portrait.texture = PORTRAIT
	_portrait.mouse_filter = Control.MOUSE_FILTER_STOP
	_portrait.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_portrait.tooltip_text = tr("Uncle Marcus")
	_portrait.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_folded = not _folded
			_box.visible = not _folded
			Sfx.play("tab", -8.0))
	add_child(_portrait)
	_box = PanelContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	var col := UiKit.column(_box)
	UiKit.label(col, tr("Uncle Marcus")).add_theme_color_override("font_color", UiKit.HEADING)
	_text = UiKit.para(col, "", 170)


## Shows a piece of advice, sliding it in when it is new; an empty id hides him.
func show_advice(id: String, text: String) -> void:
	if id == "":
		visible = false
		_shown_id = ""
		return
	visible = true
	if id == _shown_id:
		return
	_shown_id = id
	_text.text = text
	_folded = false
	_box.visible = true
	_box.reset_size()
	# He slides in from the left edge, and the advice follows a moment later.
	var tween := create_tween().set_parallel()
	_portrait.position.x = -100
	tween.tween_property(_portrait, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_box.modulate.a = 0.0
	tween.tween_property(_box, "modulate:a", 1.0, 0.3).set_delay(0.25)
	Sfx.play("page_turn", -6.0)


func showing() -> String:
	return _shown_id if visible else ""


## He stands in the corner of the screen, cut off at the waist by its bottom edge; his advice sits beside his head,
## high enough to keep clear of the fields.
func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var screen := get_parent_area_size()
	size = screen
	_box.reset_size()
	var tall := PORTRAIT.get_height()
	# He breathes gently, a pixel up and down, so he seems present rather than pasted on.
	_portrait.position.y = screen.y - tall + 2 + (1.0 if fmod(_t, 2.4) < 1.2 else 0.0)
	var top := minf(screen.y - tall + 6, screen.y * 0.6 - _box.size.y)
	_box.position = Vector2(PORTRAIT.get_width() - 4, roundf(maxf(30.0, top)))
