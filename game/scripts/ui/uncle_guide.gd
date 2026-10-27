extends Control
## Uncle Marcus, who left the farm to the player, stands in the bottom left corner of the screen with a word of advice
## for the next thing to do: plant, harvest, dig more beds, sell at market, and so on. Each new piece of advice slides
## in beside his portrait; clicking him folds the advice away and back. When every step is done he says goodbye.

const PORTRAIT := preload("res://assets/ui/uncle.png")
## The portrait is drawn about one and a half times its pixel size, with the screen's bottom edge cutting him off
## below the hands.
const SIZE := 1.5
const SHOWN_ROWS := 104
## The picture's columns and row where his head ends and starts, so the advice can sit beside it or above it.
const HEAD_RIGHT := 70
const HEAD_TOP := 7
## How far above the bottom of the scene the advice stays, in the scene's own pixels, so it never covers the crop fields.
const FIELDS_CLEAR := 72.0

var _portrait: TextureRect
var _box: PanelContainer
var _text: Label
var _shown_id := ""
## Advice the player has closed with OK; he stays away until he has something new to say.
var _dismissed_id := ""
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
	var ok := UiKit.button(col, tr("OK"), func():
		_dismissed_id = _shown_id
		visible = false)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_END
	ok.custom_minimum_size = Vector2(40, 0)


## Shows a piece of advice, sliding it in when it is new; an empty id hides him.
func show_advice(id: String, text: String) -> void:
	if id == "":
		visible = false
		_shown_id = ""
		return
	if id == _dismissed_id:
		visible = false
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
	_portrait.position.x = -PORTRAIT.get_width() * _scale()
	tween.tween_property(_portrait, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_box.modulate.a = 0.0
	tween.tween_property(_box, "modulate:a", 1.0, 0.3).set_delay(0.25)
	Sfx.play("advice", -3.0)


## The advice the player last closed with OK.
func dismissed() -> String:
	return _dismissed_id


## The advice he is on, even while it is tucked away behind a window or closed with OK.
func showing() -> String:
	return _shown_id


## He stands in the corner of the screen, cut off below the hands by its bottom edge; his advice sits beside his
## head, high enough to keep clear of the fields, or above his head when the window is too narrow for both.
func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var screen := get_parent_area_size()
	size = screen
	_box.reset_size()
	# He breathes gently, a pixel up and down, so he seems present rather than pasted on.
	var scale := _scale()
	_portrait.scale = Vector2(scale, scale)
	_portrait.position.y = screen.y - SHOWN_ROWS * scale + (1.0 if fmod(_t, 2.4) < 1.2 else 0.0)
	var head_top := _portrait.position.y + HEAD_TOP * scale
	var beside := HEAD_RIGHT * scale + 4
	if beside + _box.size.x <= screen.x - 4:
		# The scene and the interface can be drawn at different scales, so the fields' height is converted to interface pixels.
		var clear := FIELDS_CLEAR * Windowing.scale / Windowing.ui_scale
		_box.position = Vector2(beside, roundf(maxf(30.0, minf(head_top, screen.y - clear - _box.size.y))))
	else:
		_box.position = Vector2(maxf(4.0, screen.x - 4 - _box.size.x), roundf(maxf(4.0, head_top - _box.size.y - 4)))


## The portrait's size in interface pixels: exactly SIZE, except at the smallest interface scale, where half a pixel
## would show as a ragged picture, so it is drawn at twice its size instead.
func _scale() -> float:
	return SIZE if Windowing.ui_scale >= 2 else 2.0
