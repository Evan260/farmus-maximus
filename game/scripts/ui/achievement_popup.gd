extends Control
## Earned achievements slide in from the right edge on a small parchment card with a laurel wreath, one after another,
## and slide away again after a few seconds; clicking a card sends it away early. The card stands in the sky just below
## the buttons in the top-right corner, where it never covers the cart, the fields or Uncle Marcus.

const LAUREL := preload("res://assets/sprites/icons32/laurel.png")
const MARGIN := 6.0
const HOLD := 5.0

## The interface element the card stands below; without one it sits at the top edge.
var below: Control
## While true, cards wait in the queue and a card on its way stops where it is, such as while the title screen is up.
var hold := false:
	set(value):
		hold = value
		if _tween and _tween.is_valid():
			if hold:
				_tween.pause()
			else:
				_tween.play()
		if not hold and _card == null:
			_next()
var _queue: Array = []
var _card: PanelContainer
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func add(a: Dictionary) -> void:
	_queue.append(a)
	if _card == null and not hold:
		_next()


func _next() -> void:
	if _queue.is_empty() or hold or _card != null:
		return
	var a: Dictionary = _queue.pop_front()
	move_to_front()
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(_card)
	var frame := _card.get_theme_stylebox("panel").duplicate() as StyleBox
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		frame.set_content_margin(side, 6)
	# The font leaves room above its letters but none below, so the bottom gets the extra pixel.
	frame.set_content_margin(SIDE_TOP, 5)
	frame.set_content_margin(SIDE_BOTTOM, 7)
	_card.add_theme_stylebox_override("panel", frame)
	var r := UiKit.row(_card)
	r.add_theme_constant_override("separation", 4)
	var wreath := TextureRect.new()
	var cropped := AtlasTexture.new()
	cropped.atlas = LAUREL
	cropped.region = Rect2(LAUREL.get_image().get_used_rect())
	wreath.texture = cropped
	wreath.custom_minimum_size = cropped.region.size
	wreath.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wreath.pivot_offset = (cropped.region.size / 2.0).round()
	wreath.scale = Vector2(0.3, 0.3)
	r.add_child(wreath)
	var words := UiKit.column(r)
	words.add_theme_constant_override("separation", -1)
	UiKit.label(words, tr("Achievement")).add_theme_color_override("font_color", UiKit.HEADING)
	UiKit.label(words, tr(String(a["name"])))
	var desc := UiKit.para(words, tr(String(a.get("desc", ""))), 140)
	desc.add_theme_color_override("font_color", UiKit.FADED)
	# A description that wraps keeps the same tight line spacing as the lines above it.
	desc.add_theme_constant_override("line_spacing", -1)
	var card := _card
	card.position = Vector2(size.x, size.y)
	# A wrapped description only knows its height once laid out, so the card is measured a frame later, still out of sight.
	await get_tree().process_frame
	card.reset_size()
	var w := card.size.x
	card.position.y = _top()
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
	if hold:
		_tween.pause()


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


func _process(_delta: float) -> void:
	# The buttons above can change size with the interface size setting, so the card keeps to just below them.
	if _card:
		_card.position.y = _top()


func _top() -> float:
	if below and below.visible:
		return roundf(below.position.y + below.size.y + MARGIN)
	return MARGIN
