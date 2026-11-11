extends Control
## The title screen, laid over the live estate when the game opens: the game's name, and a small menu to carry on
## with the last farm, start a new one and name it, pick another farm, change settings or quit.

signal closed

const FarmsPanel := preload("res://scripts/ui/farms_panel.gd")
const LOGO := Color(0.99, 0.95, 0.86)
const LOGO_SHADOW := Color(0.29, 0.18, 0.14)

## Supplied by the HUD: opens one of its windows, such as the settings, over the title.
var open_window: Callable
var _menu: VBoxContainer
var _card: PanelContainer
var _farms: Node
## True while the menu asks for a new farm's name.
var _naming := false


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
	var logo := Label.new()
	logo.text = tr("Farmus Maximus").to_upper()
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_override("font", UiKit.FONT)
	logo.add_theme_font_size_override("font_size", 48)
	logo.add_theme_color_override("font_color", LOGO)
	logo.add_theme_color_override("font_shadow_color", LOGO_SHADOW)
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 4)
	logo.add_theme_constant_override("outline_size", 8)
	logo.add_theme_color_override("font_outline_color", LOGO_SHADOW)
	col.add_child(logo)
	var tagline := UiKit.label(col, tr("A Roman farm, slowly brought back to life"), true)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card = PanelContainer.new()
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_card)
	_menu = UiKit.column(_card)
	_farms = FarmsPanel.new()
	_farms.on_new = _name_farm
	_farms.on_change = _show_menu
	add_child(_farms)
	# The farm list takes the menu's place while it is open.
	_farms.closed.connect(func(): _card.visible = true)
	_show_menu()
	var version := UiKit.label(self, "v" + str(ProjectSettings.get_setting("application/config/version", "")), true)
	version.modulate.a = 0.7
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -4
	version.offset_bottom = -3
	UiKit.fade_in(self, 0.8)


func _show_menu() -> void:
	_naming = false
	UiKit.clear(_menu)
	_menu.custom_minimum_size = Vector2(150, 0)
	if Saves.has_farm:
		var go := UiKit.button(_menu, tr("Continue"), _continue)
		go.focus_mode = Control.FOCUS_ALL
		go.grab_focus.call_deferred()
		var info := Saves.slot_info(Saves.slot)
		var about := UiKit.label(_menu, FarmsPanel.describe(info))
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		about.add_theme_color_override("font_color", UiKit.MUTED)
	var fresh := UiKit.button(_menu, tr("New farm"), _new_farm)
	# A farm is never written over, so with every slot taken one has to be deleted first.
	if Saves.free_slot() == 0:
		fresh.disabled = true
		UiKit.tip_on(fresh, "You already keep three farms. Delete one to start another.")
	if Saves.any_farm():
		UiKit.button(_menu, tr("Farms"), _open_farms)
	UiKit.button(_menu, tr("Settings"), func(): open_window.call("settings"))
	# Quitting here does what closing the window does: the farm is saved and the window remembers its monitor.
	UiKit.button(_menu, tr("Quit"), func(): get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST); get_tree().quit())


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
	_card.visible = false
	_farms.open()


## Asks for the new farm's name, offering a Roman one to start from, then starts the farm in that slot.
func _name_farm(n: int) -> void:
	_farms.close()
	UiKit.clear(_menu)
	_naming = true
	_menu.custom_minimum_size = Vector2(190, 0)
	UiKit.label(_menu, tr("Name your farm"))
	var r := UiKit.row(_menu)
	var field := LineEdit.new()
	field.max_length = 22
	field.text = _suggestion()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(field)
	UiKit.button(r, tr("Another"), func(): field.text = _suggestion())
	field.grab_focus.call_deferred()
	var start := func():
		var chosen := field.text.strip_edges()
		Saves.create(n, chosen if chosen != "" else _suggestion())
	field.text_submitted.connect(func(_t): start.call())
	UiKit.button(_menu, tr("Begin"), start)
	UiKit.button(_menu, tr("Back"), _show_menu)


## Escape or B steps back from the farm list or the naming of a farm to the menu; true if there was a step to take.
func go_back() -> bool:
	if _farms.visible:
		_farms.close()
		return true
	if _naming:
		_show_menu()
		return true
	return false


func _suggestion() -> String:
	var names: Array = Balance.get_value("farm_names", ["Villa Aurelia"])
	return tr(String(names[randi() % names.size()]))
