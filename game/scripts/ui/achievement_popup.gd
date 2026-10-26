extends Control
## Earned achievements slide in from the bottom-right corner on a small parchment card with a laurel wreath, one after
## another, and slide away again after a few seconds; clicking a card sends it away early.

const LAUREL := preload("res://assets/sprites/icons32/laurel.png")
const MARGIN := 6.0
const HOLD := 5.0

## While true, cards wait in the queue, such as while the title screen is up.
var hold := false:
	set(value):
		hold = value
		if not hold and _card == null:
			_next()
var _queue: Array = []
var _card: PanelContainer
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func():
		if _card:
			_card.position.y = size.y - _card.size.y - MARGIN)


func add(a: Dictionary) -> void:
	_queue.append(a)
	if _card == null and not hold:
		_next()


func _next() -> void:
	if _queue.is_empty() or hold:
		return
	var a: Dictionary = _queue.pop_front()
	move_to_front()
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(_card)
	var r := UiKit.row(_card)
	r.add_theme_constant_override("separation", 5)
	var wreath := TextureRect.new()
	wreath.texture = LAUREL
	wreath.custom_minimum_size = Vector2(32, 32)
	wreath.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wreath.pivot_offset = Vector2(16, 16)
	wreath.scale = Vector2(0.3, 0.3)
	r.add_child(wreath)
	var words := UiKit.column(r)
	words.add_theme_constant_override("separation", 1)
	UiKit.label(words, tr("Achievement")).add_theme_color_override("font_color", UiKit.HEADING)
	UiKit.label(words, tr(String(a["name"])))
	UiKit.para(words, tr(String(a.get("desc", ""))), 150).add_theme_color_override("font_color", UiKit.FADED)
	var card := _card
	card.position = Vector2(size.x, size.y)
	# A wrapped description only knows its height once laid out, so the card is measured a frame later, still out of sight.
	await get_tree().process_frame
	card.reset_size()
	var w := card.size.x
	card.position.y = roundf(size.y - card.size.y - MARGIN)
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and card == _card:
			_leave())
	_tween = create_tween()
	_tween.tween_method(func(x: float): card.position.x = roundf(x), size.x, size.x - w - MARGIN, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# The wreath springs open once the card has landed.
	_tween.tween_property(wreath, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(HOLD)
	_tween.tween_callback(_leave)


func _leave() -> void:
	if _tween:
		_tween.kill()
	var card := _card
	_tween = create_tween()
	_tween.tween_method(func(x: float): card.position.x = roundf(x), card.position.x, size.x + 4.0, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func():
		card.queue_free()
		_card = null)
	_tween.tween_interval(0.25)
	_tween.tween_callback(_next)
