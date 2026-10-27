extends PanelContainer
## A centred parchment window with a title and a close button; the interface's panels build their contents inside it.

signal closed

var body: VBoxContainer
## Above the body and outside its scrolling, for tabs that should stay put while the page under them scrolls.
var top: VBoxContainer
var _title: Label
var _col: VBoxContainer
var _scroll: ScrollContainer
## Set when the next rebuild shows a different page, such as another tab, so it starts from the top.
var _reset_scroll := false
var _refresh_timer := 0.0
var _signature := "-"
## When set, the window keeps this size whatever it shows, so switching tabs never makes it jump.
var fixed_size := Vector2.ZERO
## Room kept clear above a window, and below it, where the toolbar sits at the bottom of the screen.
const SCREEN_MARGIN := 8.0
const TOOLBAR_ROOM := 30.0
## The right margin that keeps a scroll bar off the text when a window's page scrolls.
var _scroll_gap: MarginContainer


func _init(title := "") -> void:
	_col = VBoxContainer.new()
	add_child(_col)
	var head := UiKit.row(_col)
	_title = UiKit.label(head, title)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.close_button(head, close)
	top = UiKit.column(_col)
	body = UiKit.column(_col)
	visible = false


func _ready() -> void:
	# The page scrolls inside the window: at a fixed size, so the window is the same size on every tab, or otherwise
	# only once it is taller than the screen, so a long page never runs off the bottom.
	_scroll = ScrollContainer.new()
	UiKit.touch_scroll(_scroll)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_col.remove_child(body)
	_col.add_child(_scroll)
	_scroll_gap = MarginContainer.new()
	_scroll_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_scroll_gap)
	_scroll_gap.add_child(body)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if fixed_size != Vector2.ZERO:
		_scroll.custom_minimum_size = fixed_size
		_scroll_gap.add_theme_constant_override("margin_right", 8)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH


func set_title(text: String) -> void:
	_title.text = text


func open() -> void:
	if not visible:
		UiKit.fade_in(self)
	_signature = ""
	_reset_scroll = true
	refresh()


## Rebuilds straight away to show another tab or page, starting it from the top.
func show_page() -> void:
	_reset_scroll = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	if fixed_size == Vector2.ZERO:
		_fit_to_screen()
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
	var scrolled: Array = [] if _reset_scroll else _scroll_positions()
	_reset_scroll = false
	UiKit.clear(top)
	UiKit.clear(body)
	build()
	tick()
	if fixed_size == Vector2.ZERO:
		_fit_to_screen()
	if scrolled.is_empty():
		for s in _scrolls():
			s.scroll_vertical = 0
	else:
		_restore_scroll.call_deferred(scrolled)
	UiKit.pad_focus.call_deferred(self)


## Sizes the page to its contents, but no taller than the screen allows; a taller page scrolls, with room kept for
## the scroll bar.
func _fit_to_screen() -> void:
	var page := body.get_combined_minimum_size()
	var chrome := _col.get_combined_minimum_size().y - _scroll.custom_minimum_size.y + 12.0
	var screen := get_parent_area_size()
	var room := maxf(40.0, screen.y - SCREEN_MARGIN - TOOLBAR_ROOM - chrome)
	var scrolls := page.y > room
	var gap := 8 if scrolls else 0
	if _scroll_gap.get_theme_constant("margin_right") != gap:
		_scroll_gap.add_theme_constant_override("margin_right", gap)
	var want := Vector2(page.x + gap, minf(page.y, room))
	if _scroll.custom_minimum_size != want:
		_scroll.custom_minimum_size = want
		reset_size()
	# Centred in the space between the top of the screen and the toolbar, so a tall window clears both.
	var spot := Vector2(roundf((screen.x - size.x) / 2.0), roundf(SCREEN_MARGIN + (screen.y - SCREEN_MARGIN - TOOLBAR_ROOM - size.y) / 2.0))
	spot.y = maxf(SCREEN_MARGIN, spot.y)
	if position != spot:
		position = spot


func _scrolls() -> Array[Node]:
	return find_children("*", "ScrollContainer", true, false)


func _scroll_positions() -> Array:
	return _scrolls().map(func(s): return s.scroll_vertical)


## A rebuilt window keeps its place in every list, once the new lists are laid out long enough to scroll that far.
func _restore_scroll(values: Array) -> void:
	for pass_ in 2:
		var scrolls := _scrolls()
		for i in mini(values.size(), scrolls.size()):
			scrolls[i].scroll_vertical = values[i]
		await get_tree().process_frame


## A summary of the state this window shows; when it changes, the window is rebuilt.
func signature() -> String:
	return ""


## Creates the window's contents; panels override it.
func build() -> void:
	pass


## Updates text that changes every moment, such as timers, without rebuilding.
func tick() -> void:
	pass
