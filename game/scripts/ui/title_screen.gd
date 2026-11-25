extends Control
## The title screen, laid over the live estate when the game opens: the game's name, and a small menu to carry on
## with the last farm, start a new one and name it, pick another farm, change settings or quit.

signal closed

const FarmsPanel := preload("res://scripts/ui/farms_panel.gd")
const LOGO := Color(0.99, 0.95, 0.86)
const LOGO_SHADOW := Color(0.29, 0.18, 0.14)
## The gold of the logo's laurel, for the word Demo under the name.
const DEMO := Color(0.98, 0.83, 0.43)

## Supplied by the HUD: opens one of its windows, such as the settings, over the title.
var open_window: Callable
var _menu: VBoxContainer
var _card: PanelContainer
## The game's name, its line under it and the menu, which the farm list stands in place of while it is open.
var _column: VBoxContainer
var _farms: Node
## True while the menu asks for a new farm's name.
var _naming := false
## True while the menu asks for Google Play's reviewer code.
var _reviewing := false
var _demo: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	add_child(col)
	_column = col
	var logo := Label.new()
	logo.text = tr("Farmus Maximus").to_upper()
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_override("font", UiTheme.FONT)
	logo.add_theme_font_size_override("font_size", 48)
	logo.add_theme_color_override("font_color", LOGO)
	logo.add_theme_color_override("font_shadow_color", LOGO_SHADOW)
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 4)
	logo.add_theme_constant_override("outline_size", 8)
	logo.add_theme_color_override("font_outline_color", LOGO_SHADOW)
	col.add_child(logo)
	# A phone that buys the full game on the title stops being the demo there and then.
	if Game.is_demo() or FullGame.sold_here():
		var demo := Label.new()
		demo.name = "DemoLabel"
		# A phone selling the full game shows its limits without calling itself a demo, which App Review refuses.
		demo.visible = Game.is_demo() and not FullGame.sold_here()
		_demo = demo
		demo.text = tr("Demo").to_upper()
		demo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		demo.add_theme_font_override("font", UiTheme.FONT)
		demo.add_theme_font_size_override("font_size", 24)
		demo.add_theme_color_override("font_color", DEMO)
		demo.add_theme_color_override("font_shadow_color", LOGO_SHADOW)
		demo.add_theme_constant_override("shadow_offset_x", 0)
		demo.add_theme_constant_override("shadow_offset_y", 2)
		demo.add_theme_constant_override("outline_size", 6)
		demo.add_theme_color_override("font_outline_color", LOGO_SHADOW)
		col.add_child(demo)
	var tagline := Ui.label(col, tr("A Roman farm, slowly brought back to life"), true)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card = PanelContainer.new()
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_card)
	_menu = Ui.column(_card)
	_farms = FarmsPanel.new()
	_farms.on_new = _name_farm
	_farms.on_change = _show_menu
	add_child(_farms)
	# The farm list takes the menu's place while it is open.
	_farms.closed.connect(func(): _column.visible = true)
	_show_menu()
	FullGame.changed.connect(_on_store_changed)
	var version := Ui.label(self, "v" + str(ProjectSettings.get_setting("application/config/version", "")), true)
	version.name = "Version"
	version.modulate.a = 0.7
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -4 - Windowing.safe_bottom_right.x
	version.offset_bottom = -3 - Windowing.safe_bottom_right.y
	# The version takes a fingertip's taps, reaching up and left from where it is drawn.
	version.custom_minimum_size = Vector2.ONE * Windowing.touch_px()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version.mouse_filter = Control.MOUSE_FILTER_STOP
	version.gui_input.connect(_on_version_input)
	Ui.fade_in(self, 0.8)


func _process(_delta: float) -> void:
	if Windowing.phone:
		_clear_keyboard()


## While a phone's keyboard is up, the menu rises until the farm's name being typed shows above it.
func _clear_keyboard() -> void:
	var y := roundf((size.y - _column.size.y) / 2.0)
	var field := Ui.typing_in(_column)
	if field != null:
		var rect := field.get_global_rect()
		y = maxf(minf(y, roundf(Ui.keyboard_top() - (rect.end.y - _column.global_position.y) - 4)), 2 - (rect.position.y - _column.global_position.y))
	if _column.position.y != y:
		_column.position.y = y


func _show_menu() -> void:
	_naming = false
	_reviewing = false
	Ui.clear(_menu)
	_menu.custom_minimum_size = Vector2(150, 0)
	if Saves.has_farm:
		var go := Ui.button(_menu, tr("Continue"), _continue)
		go.focus_mode = Control.FOCUS_ALL
		go.grab_focus.call_deferred(not KeyNav.active())
		var info := Saves.slot_info(Saves.slot)
		var about := Ui.label(_menu, FarmsPanel.describe(info))
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		about.add_theme_color_override("font_color", UiTheme.MUTED)
	var fresh := Ui.button(_menu, tr("New farm"), _new_farm)
	# A farm is never written over, so with every slot taken one has to be deleted first.
	if Saves.free_slot() == 0:
		fresh.disabled = true
		Ui.tip_on(fresh, "You already keep three farms. Delete one to start another.")
	if Saves.any_farm():
		Ui.button(_menu, tr("Farms"), _open_farms)
	# A phone's short screen has no room for one more line, so there the unlock sits beside Settings.
	var last: Container = _menu
	if Windowing.phone and FullGame.locked():
		last = Ui.row(_menu)
	Ui.button(last, tr("Settings"), func(): open_window.call("settings")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var unlock := Ui.full_game_button(last)
	if unlock:
		unlock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Phone apps are put away rather than quit, so a phone has no Quit button.
	if Windowing.phone:
		return
	# Quitting here does what closing the window does: the farm is saved and the window remembers its monitor.
	Ui.button(_menu, tr("Quit"), func(): get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST); get_tree().quit())


## The store's price arrived or the full game was bought, which changes the unlock button and the word Demo.
func _on_store_changed() -> void:
	if _demo:
		_demo.visible = Game.is_demo() and not FullGame.sold_here()
	# Deferred, so the menu built this frame first takes the focus it asked for before it is replaced.
	if not _naming and not _reviewing:
		_show_menu.call_deferred()


func _continue() -> void:
	Saves.title_done = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.5)
	fade.tween_callback(func():
		closed.emit()
		queue_free())


func _new_farm() -> void:
	var n := Saves.free_slot()
	if n > 0:
		_name_farm(n)


func _open_farms() -> void:
	_column.visible = false
	_farms.open()


## Asks for the new farm's name, offering a Roman one to start from, then starts the farm in that slot.
func _name_farm(n: int) -> void:
	_farms.close()
	Ui.clear(_menu)
	_naming = true
	_menu.custom_minimum_size = Vector2(190, 0)
	Ui.label(_menu, tr("Name your farm"))
	var r := Ui.row(_menu)
	var field := LineEdit.new()
	field.max_length = 22
	field.text = _suggestion()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(field)
	Ui.button(r, tr("Another"), func(): field.text = _suggestion())
	field.grab_focus.call_deferred()
	var start := func():
		var chosen := field.text.strip_edges()
		Saves.create(n, chosen if chosen != "" else _suggestion())
	field.text_submitted.connect(func(_t): start.call())
	Ui.button(_menu, tr("Begin"), start)
	Ui.button(_menu, tr("Back"), _show_menu)


## Five quick taps on the version open the box for Google Play's reviewer code while the full game is locked.
func _on_version_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if FullGame.review_tap(Time.get_ticks_msec() / 1000.0):
			_review_code()


## The box for the code that opens the full game for Google Play's reviewers, in English since only they see it.
func _review_code() -> void:
	_farms.close()
	Ui.clear(_menu)
	_reviewing = true
	_menu.custom_minimum_size = Vector2(190, 0)
	var box := Ui.column(_menu)
	box.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	Ui.label(box, "Reviewer code")
	# The message and OK sit above and beside the field, which a phone's keyboard stops just below.
	var wrong := Ui.label(box, "That code isn't right.")
	wrong.add_theme_color_override("font_color", UiTheme.RED)
	wrong.visible = false
	var r := Ui.row(box)
	var field := LineEdit.new()
	field.name = "ReviewCode"
	field.placeholder_text = "XXXX-XXXX-XXXX"
	field.max_length = 20
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(field)
	var enter := func():
		if FullGame.redeem(field.text):
			_show_menu()
		else:
			wrong.visible = true
	field.text_submitted.connect(func(_t): enter.call())
	Ui.button(r, "OK", enter)
	Ui.button(box, "Cancel", _show_menu)
	field.grab_focus.call_deferred()


## Escape or B steps back from the farm list, a farm's naming or the reviewer's code to the menu; true if there was a step.
func go_back() -> bool:
	if _farms.visible:
		_farms.close()
		return true
	if _naming or _reviewing:
		_show_menu()
		return true
	return false


func _suggestion() -> String:
	var names: Array = Data.get_value("farm_names", ["Villa Aurelia"])
	return tr(String(names[randi() % names.size()]))
