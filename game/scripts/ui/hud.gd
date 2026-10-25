extends CanvasLayer
## The interface over the estate: the farm's numbers, the zone bar, the windows, messages, tips and the debug panel.

signal zone_chosen(zone_id: String)
signal town_requested

const WindowPanel := preload("res://scripts/ui/window_panel.gd")
const BuildingPanel := preload("res://scripts/ui/building_panel.gd")
const StorePanel := preload("res://scripts/ui/store_panel.gd")
const HelpersPanel := preload("res://scripts/ui/helpers_panel.gd")
const JournalPanel := preload("res://scripts/ui/journal_panel.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const UpgradesPanel := preload("res://scripts/ui/upgrades_panel.gd")
const SeedsPanel := preload("res://scripts/ui/seeds_panel.gd")
const CompanionsPanel := preload("res://scripts/ui/companions_panel.gd")
## The id the building panel uses for the farmhouse.
const VILLA := "villa"
const WEATHER_NAMES := {"sun": "Sunny", "cloudy": "Cloudy", "rain": "Rain", "mist": "Mist"}
const SHORT_ZONES := {"grove": "Grove", "home": "Farm", "yard": "Yard", "vineyard": "Vines", "pasture": "Pasture"}

var _root: Control
var _coins: Label
var _storage: Label
var _cart: Label
var _calendar: Label
var _seed_button: Button
var _info: Label
var _toast: Label
var _toast_tween: Tween
var _toast_queue: Array = []
var _tip: Label
var _debug: PanelContainer
var _stats_panel: PanelContainer
var _buttons: VBoxContainer
var _compact: PanelContainer
var _compact_label: Label
var _zone_bar: HBoxContainer
var _zone_buttons := {}
var _windows: Array = []
var _building: WindowPanel
var _store: WindowPanel
var _helpers: WindowPanel
var _journal: WindowPanel
var _settings: WindowPanel
var _upgrades: WindowPanel
var _seeds: WindowPanel
var _companions: WindowPanel


func _ready() -> void:
	# Above the scene, the firefly glow and the weather.
	layer = 10
	_root = Control.new()
	# Clicks on empty parts of the interface pass through to the farm.
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiKit.make_theme()
	add_child(_root)
	Windowing.view_changed.connect(_fit)
	_fit()

	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(4, 4)
	_root.add_child(_stats_panel)
	var col := UiKit.column(_stats_panel)
	_coins = UiKit.label(col)
	_storage = UiKit.label(col)
	_cart = UiKit.label(col)
	_calendar = UiKit.label(col)
	_seed_button = UiKit.button(col, "", func(): _open(_seeds))

	_buttons = VBoxContainer.new()
	_root.add_child(_buttons)
	# Anchored to the top-right corner and growing leftwards, so longer button text never gets cut off.
	_buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_buttons.offset_top = 4
	_buttons.offset_right = -4
	UiKit.button(_buttons, tr("Upgrades"), func(): _open(_upgrades))
	UiKit.button(_buttons, tr("Storehouse"), func(): _open(_store))
	UiKit.button(_buttons, tr("Helpers"), func(): _open(_helpers))
	UiKit.button(_buttons, tr("Journal"), func(): _open(_journal))
	UiKit.button(_buttons, tr("Settings"), func(): _open(_settings))

	_info = UiKit.label(_root, "", true)
	_info.visible = false
	_tip = UiKit.label(_root, "", true)
	_toast = UiKit.label(_root, "", true)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0

	_build_zone_bar()
	_building = _add_window(BuildingPanel.new("Building"))
	_store = _add_window(StorePanel.new())
	_helpers = _add_window(HelpersPanel.new())
	_journal = _add_window(JournalPanel.new())
	_settings = _add_window(SettingsPanel.new())
	_upgrades = _add_window(UpgradesPanel.new())
	_seeds = _add_window(SeedsPanel.new())
	_companions = _add_window(CompanionsPanel.new())
	add_to_group("hud")
	_build_compact()
	_build_debug()
	Settings.changed.connect(_apply_text_size)
	_apply_text_size()
	Game.message.connect(func(text): toast(tr(text)); Sfx.play("nope", -6.0))
	Game.storage_full.connect(func(): toast(tr("The storehouse is full: send the cart to market")))
	Game.achievement_unlocked.connect(func(a): toast(tr("Achievement: %s") % tr(String(a["name"]))); Sfx.play("villa_complete", -6.0))
	Game.discovered.connect(_on_discovered)
	Game.festival_started.connect(_on_festival)
	Game.season_changed.connect(func(_s): toast(tr("%s has come to the estate") % tr(Game.calendar.season_name())))
	Game.dog_found.connect(func(_id, text): toast(tr(text)))
	Game.blessing_started.connect(func(god): Sfx.play("shrine_bell"); toast(tr("%s blesses the estate") % tr(String(Game.gods()[god]["name"]))))
	Game.helper_hired.connect(func(id): toast(tr("%s has joined the household") % Game.helper_info(id).get("name", "")))
	Game.order_added.connect(func(): toast(tr("A new request is pinned to the market's notice board")))
	# A farmer who already has harvests behind them has read the letter long ago.
	if not Settings.intro_seen and int(Game.stats.get("harvested", 0)) > 0:
		Settings.set_value("intro_seen", true)
	if not Settings.intro_seen:
		_show_intro()
	elif not Saves.pending_summary.is_empty():
		_show_away(Saves.pending_summary)
		Saves.pending_summary = {}


func _process(_delta: float) -> void:
	var in_strip := Windowing.strip
	_stats_panel.visible = not in_strip
	_buttons.visible = not in_strip
	_zone_bar.visible = not in_strip
	_compact.visible = in_strip
	if in_strip:
		for w in _windows:
			w.visible = false
	_compact_label.text = "%d   %d/%d" % [Game.coins, Game.stored_total(), Game.storage_capacity()]
	_coins.text = tr("Sestertii  %d") % Game.coins + (("   " + tr("Aurei  %d") % Game.aureus) if Game.aureus > 0 else "")
	_storage.text = tr("Storehouse  %d / %d") % [Game.stored_total(), Game.storage_capacity()]
	if Game.cart["away"]:
		_cart.text = tr("Cart back in  %s") % UiKit.duration(float(Game.cart["time_left"]))
	else:
		_cart.text = tr("Cart ready  (carries %d)") % Game.cart_capacity()
	var cal := "%s %d  %s" % [tr(Game.calendar.season_name()), Game.calendar.day_of_season() + 1, tr(WEATHER_NAMES.get(Game.calendar.weather, ""))]
	var festival: Dictionary = Game.calendar.festival()
	if not festival.is_empty():
		cal += "  " + tr(String(festival["name"]))
	if not Game.blessing.is_empty():
		cal += "\n" + tr("Blessing of %s") % tr(String(Game.gods()[Game.blessing["god"]]["name"]))
	_calendar.text = cal
	_seed_button.text = tr("Seed: %s") % tr(String(Game.crop_info(Game.selected_seed).get("name", "")))
	_update_tip()


## The interface is drawn at its own whole-number scale, laid out in the window's size divided by that scale.
func _fit() -> void:
	scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_root.position = Vector2.ZERO
	_root.size = (get_viewport().get_visible_rect().size / Windowing.ui_scale).floor()


## The compact bar's area in the strip, which must stay clickable when the rest of the sky lets clicks through.
func compact_rect() -> Rect2:
	return _compact.get_global_rect() if _compact.visible else Rect2()


## True while a window covers the estate, so clicks there do not reach the farm.
func window_open() -> bool:
	for w in _windows:
		if w.visible:
			return true
	return false


func close_windows() -> bool:
	var any := false
	for w in _windows:
		if w.visible:
			w.close()
			any = true
	return any


func show_building(id: String) -> void:
	_building.id = id
	if _building.visible:
		_building.open()
	else:
		_open(_building)


## Opens the journal at one entry, such as "item:lavender", on its section's page.
func show_journal_entry(id: String) -> void:
	var sections := {"crop": "Crops", "item": "Goods", "building": "Buildings", "helper": "Helpers", "animal": "Animals", "find": "Finds",
		"sighting": "Sightings", "festival": "Festivals", "milestone": "Milestones", "achievement": "Achievements"}
	_journal.section = sections.get(id.get_slice(":", 0), "Crops")
	_journal.selected = id
	_journal.refresh()


func open_window(name: String) -> void:
	var w: WindowPanel = {"store": _store, "helpers": _helpers, "journal": _journal, "settings": _settings, "upgrades": _upgrades, "companions": _companions}.get(name)
	if w and not w.visible:
		_open(w)


## Highlights the zone the camera is looking at in the zone bar.
func set_zone(zone_id: String) -> void:
	for id in _zone_buttons:
		_zone_buttons[id].button_pressed = id == zone_id


func set_info(text: String) -> void:
	_info.visible = text != ""
	_info.text = text
	_info.position = Vector2(4, _root.size.y - _info.get_minimum_size().y - 2)


func toast(text: String) -> void:
	# Messages that arrive together are shown one after another rather than overwriting each other.
	if _toast_tween and _toast_tween.is_running() and _toast.text != text:
		if not text in _toast_queue and _toast_queue.size() < 4:
			_toast_queue.append(text)
		return
	_show_toast(text)


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	var view := _root.size
	_toast.position = Vector2(0, roundf(view.y * 0.2))
	_toast.size.x = view.x
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
	_toast_tween.tween_callback(func(): if not _toast_queue.is_empty(): _show_toast(_toast_queue.pop_front()))


## Text that floats up from a spot on screen; pos is in estate pixels relative to the view's corner.
func float_text(pos: Vector2, text: String) -> void:
	var l := UiKit.label(_root, text, true)
	pos = (pos * Windowing.scale / Windowing.ui_scale).round()
	l.position = pos
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", pos.y - 12, 0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)


func _open(w: WindowPanel) -> void:
	var was_open := w.visible
	for other in _windows:
		if other != w:
			other.visible = false
	if was_open:
		w.close()
	else:
		if w == _journal:
			Sfx.play("page_turn")
		w.open()


func _add_window(w: WindowPanel) -> WindowPanel:
	_root.add_child(w)
	_windows.append(w)
	return w


func _apply_text_size() -> void:
	for l in [_info, _toast, _tip]:
		l.add_theme_font_size_override("font_size", 16 if Settings.large_text else 8)


func _update_tip() -> void:
	var step: Dictionary = Game.journal.tutorial_step() if Settings.show_tutorial else {}
	_tip.visible = not step.is_empty() and not Windowing.strip and not _info.visible
	if _tip.visible:
		_tip.text = tr("Tip: %s") % tr(String(step["text"]))
		_tip.position = Vector2(4, _root.size.y - _tip.get_minimum_size().y - 2)


func _on_discovered(id: String) -> void:
	var kind := id.get_slice(":", 0)
	if kind in ["quality", "item", "building", "helper", "crop", "festival"]:
		return
	for e in Game.journal.catalogue():
		if e["id"] == id:
			toast(tr("New in the journal: %s") % tr(String(e["name"])))
			return


func _on_festival(id: String) -> void:
	for f in Balance.get_value("calendar.festivals", []):
		if f["id"] == id:
			toast("%s! %s" % [tr(String(f["name"])), tr(String(f.get("about", "")))])


func _build_zone_bar() -> void:
	_zone_bar = HBoxContainer.new()
	_root.add_child(_zone_bar)
	for z in Game.zones():
		var id: String = z["id"]
		var b := UiKit.button(_zone_bar, tr(SHORT_ZONES.get(id, id)), func(): zone_chosen.emit(id))
		b.toggle_mode = true
		_zone_buttons[id] = b
	UiKit.button(_zone_bar, tr("Town"), func(): town_requested.emit())
	_zone_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_zone_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_zone_bar.offset_top = 4


func _show_intro() -> void:
	var p := PanelContainer.new()
	_root.add_child(p)
	var col := UiKit.column(p)
	UiKit.label(col, tr("A letter from your uncle Marcus"))
	UiKit.para(col, tr("My dear heir,\n\nThe old farm is yours now. The house is a ruin and the fields are bare, but the soil is good and the lavender still remembers how to bloom.\n\nPlant a little, sell a little, and mend what you can. Rome was not built in a day, and neither was any farm worth keeping.\n\nWith love, Marcus"), 230)
	UiKit.button(col, tr("Begin"), func(): Settings.set_value("intro_seen", true); p.queue_free(); _open(_companions))
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH


func _show_away(summary: Dictionary) -> void:
	var p := PanelContainer.new()
	_root.add_child(p)
	var col := UiKit.column(p)
	var hours := float(summary.get("seconds", 0)) / 3600.0
	var lines := [tr("While you were away"), "(%s)" % ((tr("%.1f hours") % hours) if hours >= 1.0 else (tr("%d minutes") % int(hours * 60)))]
	if int(summary.get("harvested", 0)) > 0:
		lines.append(tr("Harvested  %d") % int(summary["harvested"]))
	if int(summary.get("made", 0)) > 0:
		lines.append(tr("Made in the workshops  %d") % int(summary["made"]))
	if int(summary.get("earned", 0)) > 0:
		lines.append(tr("Earned  %d sestertii") % int(summary["earned"]))
	if int(summary.get("ready", 0)) > 0:
		lines.append(tr("%d plants are ready to harvest") % int(summary["ready"]))
	if summary.get("storage_full", false):
		lines.append(tr("The storehouse is full"))
	for line in lines:
		UiKit.label(col, line)
	UiKit.button(col, tr("Lovely"), p.queue_free)
	# Centred on whatever the view is, so it fits the desktop strip as well as the full window.
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH


## The small bar shown in the desktop strip instead of the full panels.
func _build_compact() -> void:
	_compact = PanelContainer.new()
	_root.add_child(_compact)
	var row := UiKit.row(_compact)
	_compact_label = UiKit.label(row)
	UiKit.button(row, tr("Sell"), func(): Game.send_cart())
	UiKit.button(row, tr("Expand"), func(): Windowing.toggle_strip())
	# Top-left, where the strip shows only sky or desktop, so it never covers the cart or the plots.
	_compact.position = Vector2(4, 4)
	_compact.visible = false


func _build_debug() -> void:
	_debug = PanelContainer.new()
	_debug.position = Vector2(4, 70)
	_debug.visible = false
	_root.add_child(_debug)
	var col := UiKit.column(_debug)
	UiKit.label(col, "Debug (F1)")
	for s in [1, 10, 60]:
		UiKit.button(col, "Speed x%d" % s, func(): Game.speed = s; toast("Time speed x%d" % s))
	UiKit.button(col, "Skip 1 hour", func(): _show_away(Game.simulate_offline(3600)))
	UiKit.button(col, "+1000 sestertii", func(): Game.coins += 1000)
	UiKit.button(col, "+10 materials", func(): for m in ["stone", "timber", "tiles"]: Game.add_item(m, 10, true))
	UiKit.button(col, "Rain", func(): Game.calendar.weather_left = 0.0; Game.calendar.weather = "rain"; Game.calendar.wet_left = 240.0)
	UiKit.button(col, "Next day", func(): Game.calendar.next_day(); Game.market.new_day())
	UiKit.button(col, "Save now", func(): Saves.save_game(); toast("Saved"))
	UiKit.button(col, "Reset farm", func(): Saves.reset(); get_tree().reload_current_scene())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_debug.visible = not _debug.visible
	elif event.is_action_pressed("close_panel") and close_windows():
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_journal"):
		_open(_journal)
		get_viewport().set_input_as_handled()

