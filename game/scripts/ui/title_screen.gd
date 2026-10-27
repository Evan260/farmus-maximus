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
	UiKit.fade_in(self, 0.8)


func _show_menu() -> void:
	UiKit.clear(_menu)
	_menu.custom_minimum_size = Vector2(150, 0)
	if Saves.has_farm:
		var go := UiKit.button(_menu, tr("Continue"), _continue)
		go.grab_focus.call_deferred()
		var info := Saves.slot_info(Saves.slot)
		var about := UiKit.label(_menu, FarmsPanel.describe(info))
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		about.add_theme_color_override("font_color", UiKit.FADED)
	UiKit.button(_menu, tr("New farm"), _new_farm)
	if Saves.has_farm or Saves.free_slot() != 1:
		UiKit.button(_menu, tr("Farms"), _open_farms)
	UiKit.button(_menu, tr("Settings"), func(): open_window.call("settings"))
	UiKit.button(_menu, tr("Quit"), func(): Saves.save_game(); get_tree().quit())


func _continue() -> void:
	Saves.title_done = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.5)
	fade.tween_callback(func():
		closed.emit()
		queue_free())


## A new farm goes in the first empty slot; with every slot taken, the farm list opens so one can be cleared.
func _new_farm() -> void:
	var n := Saves.free_slot()
	if n == 0:
		_open_farms()
		return
	_name_farm(n)


func _open_farms() -> void:
	_card.visible = false
	_farms.open()


## Asks for the new farm's name, offering a Roman one to start from, then starts the farm in that slot.
func _name_farm(n: int) -> void:
	_farms.close()
	UiKit.clear(_menu)
	_menu.custom_minimum_size = Vector2(190, 0)
	UiKit.label(_menu, tr("Name your farm"))
	var r := UiKit.row(_menu)
	var field := LineEdit.new()
	field.max_length = 22
	field.text = _suggestion()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(field)
	var dice := UiKit.button(r, tr("Another"), func(): field.text = _suggestion())
	dice.tooltip_text = tr("Suggest another name")
	field.grab_focus.call_deferred()
	var start := func():
		var chosen := field.text.strip_edges()
		Saves.create(n, chosen if chosen != "" else _suggestion())
	field.text_submitted.connect(func(_t): start.call())
	UiKit.button(_menu, tr("Begin"), start)
	UiKit.button(_menu, tr("Back"), _show_menu)


func _suggestion() -> String:
	var names: Array = Balance.get_value("farm_names", ["Villa Aurelia"])
	return tr(String(names[randi() % names.size()]))
