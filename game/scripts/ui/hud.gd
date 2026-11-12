extends CanvasLayer
## The interface over the estate: the farm's numbers, the zone bar, the windows, messages, tips and the debug panel.

signal zone_chosen(zone_id: String)
signal town_requested
signal house_requested
## The strip's controls ask the estate to look one zone along, -1 to the left and 1 to the right.
signal strip_pan_requested(step: int)

const WindowPanel := preload("res://scripts/ui/window_panel.gd")
const TitleScreen := preload("res://scripts/ui/title_screen.gd")
const BuildingPanel := preload("res://scripts/ui/building_panel.gd")
const StorePanel := preload("res://scripts/ui/store_panel.gd")
const HelpersPanel := preload("res://scripts/ui/helpers_panel.gd")
const JournalPanel := preload("res://scripts/ui/journal_panel.gd")
const SettingsPanel := preload("res://scripts/ui/settings_panel.gd")
const UpgradesPanel := preload("res://scripts/ui/upgrades_panel.gd")
const CompanionsPanel := preload("res://scripts/ui/companions_panel.gd")
const AchievementPopup := preload("res://scripts/ui/achievement_popup.gd")
const UncleGuide := preload("res://scripts/ui/uncle_guide.gd")
const StripControls := preload("res://scripts/ui/strip_controls.gd")
## The id the building panel uses for the farmhouse.
const VILLA := "villa"
## Lavender varieties share one icon, so each seed slot is tinted towards its flower colour.
const SEED_TINTS := {"lavender_violet": Color(0.82, 0.62, 1.0), "lavender_bluegrey": Color(0.72, 0.84, 1.0), "lavender_white": Color(1.15, 1.15, 1.15)}
## Bedtime: the sleep button shows from evening until shortly before dawn, and sleeping runs on until this morning hour.
const SLEEP_FROM := 19.5
const WAKE_AT := 6.5
const SHORT_ZONES := {"grove": "Grove", "home": "Farm", "yard": "Yard", "vineyard": "Vines", "pasture": "Pasture"}

var _root: Control
var _coins: Label
var _storage: Label
var _cart: Label
var _calendar: Label
## The tool in hand: "harvest", "seed" (the seed is Game.selected_seed) or "dig".
var tool := "harvest"
var _toolbar: PanelContainer
## The title screen while it is showing.
var _title: Control
var _tool_row: HBoxContainer
var _tool_buttons := {}
var _tool_signature := ""
var _sleep_button: Button
## Seconds since the farmer went to sleep, or below zero while awake.
var _slept := -1.0
var _info: Label
var _toast: Label
var _toast_tween: Tween
var _toast_queue: Array = []
var _achievements: Control
var _uncle: Control
## Something Uncle Marcus has to say outside the tutorial, such as the coins he gives a stranded farm, as an id and text.
var _notice := {}
## The tutorial step he was last on, so finishing one that has a word of praise brings that praise first.
var _last_step := {}
var _tip: Label
var _debug: PanelContainer
var _stats_panel: PanelContainer
var _buttons: VBoxContainer
var _compact: PanelContainer
var _strip_controls: PanelContainer
var _compact_label: Label
var _compact_market: Button
var _zone_bar: HBoxContainer
var _zone_buttons := {}
var _windows: Array = []
var _building: WindowPanel
var _store: WindowPanel
var _helpers: WindowPanel
var _journal: WindowPanel
var _settings: WindowPanel
var _upgrades: WindowPanel
var _companions: WindowPanel
## The summary of time away on screen, and what it adds up to, so a second catch-up joins it rather than stacking another.
var _away: PanelContainer
var _away_summary := {}
## Cards in the middle of the screen that wait for their one button, such as the summary of time away.
var _cards: Array = []
## Set while Start has handed a gamepad the interface's own buttons on the estate.
var _bar_armed := false
## The title screen's button that opened a window over it, which takes the focus back when the window closes.
var _title_focus := {}
var _debug_layer: CanvasLayer


func _ready() -> void:
	# Above the scene, the firefly glow and the weather.
	layer = 10
	_root = Control.new()
	# Clicks on empty parts of the interface pass through to the farm.
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.build()
	add_child(_root)
	Windowing.view_changed.connect(_fit)
	_fit()
	KeyNav.wanted.connect(_on_key_nav)

	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(4, 4)
	_root.add_child(_stats_panel)
	var col := Ui.column(_stats_panel)
	_coins = Ui.label(col)
	_storage = Ui.label(col)
	_cart = Ui.label(col)
	_calendar = Ui.label(col)
	_sleep_button = Ui.button(col, tr("Sleep until morning"), _start_sleep)

	_buttons = VBoxContainer.new()
	_root.add_child(_buttons)
	# Anchored to the top-right corner and growing leftwards.
	_buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_buttons.offset_top = 4
	_buttons.offset_right = -4
	_top_button(_buttons, "Upgrades", load("res://assets/sprites/icons/ui/upgrades.png"), func(): _open(_upgrades))
	_top_button(_buttons, "Storehouse", load("res://assets/sprites/icons/ui/storehouse.png"), func(): _open(_store))
	_top_button(_buttons, "Helpers", load("res://assets/sprites/icons/ui/helpers.png"), func(): _open(_helpers))
	_top_button(_buttons, "Journal", load("res://assets/sprites/icons/ui/journal.png"), func(): _open(_journal))
	_top_button(_buttons, "Settings", load("res://assets/sprites/icons/ui/settings.png"), func(): _open(_settings))
	var house: Texture2D = load("res://assets/sprites/icons/ui/title.png")
	var home := _top_button(_buttons, "Save and go back to the title", house, back_to_title)
	home.name = "TitleButton"

	_info = Ui.label(_root, "", true)
	_info.visible = false
	_tip = Ui.label(_root, "", true)
	_toast = Ui.label(_root, "", true)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Drawn over the windows, so a message about one is never hidden behind it.
	_toast.z_index = 1
	_toast.modulate.a = 0.0

	_build_zone_bar()
	_building = _add_window(BuildingPanel.new("Building"))
	_store = _add_window(StorePanel.new())
	_helpers = _add_window(HelpersPanel.new())
	_journal = _add_window(JournalPanel.new())
	_settings = _add_window(SettingsPanel.new())
	_upgrades = _add_window(UpgradesPanel.new())
	_companions = _add_window(CompanionsPanel.new())
	add_to_group("hud")
	_build_compact()
	_strip_controls = StripControls.new()
	_strip_controls.pan_requested.connect(func(step): strip_pan_requested.emit(step))
	_strip_controls.visible = false
	_root.add_child(_strip_controls)
	_build_toolbar()
	_build_debug()
	_uncle = UncleGuide.new()
	_root.add_child(_uncle)
	_achievements = AchievementPopup.new()
	_achievements.below = _buttons
	_achievements.window_open = func(): return _any_window() or not _open_cards().is_empty()
	_root.add_child(_achievements)
	visibility_changed.connect(_hold_news)
	Settings.changed.connect(_apply_text_size)
	_apply_text_size()
	Game.message.connect(func(text): toast(tr(text)); Audio.play("nope", -6.0))
	Game.storage_full.connect(func(): toast(tr("The storehouse and the cart are full: send the cart to market")))
	Game.caught_up.connect(_on_caught_up)
	Game.achievement_unlocked.connect(_on_achievement)
	Game.discovered.connect(_on_discovered)
	Game.festival_started.connect(_on_festival)
	Game.season_changed.connect(func(_s): toast(tr("%s has come to the estate") % tr(Game.calendar.season_name())))
	Game.dog_found.connect(func(_id, text): toast(tr(text)))
	Game.rescued.connect(func(gift):
		_notice = {"id": "rescue_%d" % Time.get_ticks_msec(), "text": tr("Here are %d sestertii to start again, my dear heir. Plant something, and mind the shovel!") % gift}
		Audio.play("coins"))
	Game.planted.connect(func(_i): _notice = {})
	Game.blessing_started.connect(func(god): Audio.play("shrine_bell"); toast(tr("%s blesses the estate") % tr(String(Game.gods()[god]["name"]))))
	Game.helper_hired.connect(func(id): toast(tr("%s has joined the household") % tr(String(Game.helper_info(id).get("name", "")))))
	Game.helper_trained.connect(func(id, level): toast(tr("%s is now level %d") % [tr(String(Game.helper_info(id).get("name", ""))), level]))
	Game.order_added.connect(func(): toast(tr("A new request is pinned to the market's notice board")))
	if _wants_title():
		_show_title()
	else:
		_after_title()


## The title screen opens once when the game starts normally; runs started with development flags, the desktop strip
## and players who turned it off go straight to the farm.
func _wants_title() -> bool:
	if Saves.title_done or Windowing.strip:
		return false
	var args := OS.get_cmdline_user_args()
	return "--title" in args or Dev.get_arg("screen") == "title" or (args.is_empty() and Settings.show_title)


func _show_title() -> void:
	_title = TitleScreen.new()
	_title.open_window = open_window
	_root.add_child(_title)
	# Behind the windows, so the settings open over it.
	_root.move_child(_title, 0)
	_hold_news()
	_title.closed.connect(func():
		_title = null
		_hold_news()
		_after_title())


## Achievement cards and messages wait while the interface is hidden, in the market or the farmhouse, then play in order.
func _hold_news() -> void:
	_achievements.hold = _title != null or not visible
	if visible and not (_toast_tween and _toast_tween.is_running()) and not _toast_queue.is_empty():
		_show_toast(_toast_queue.pop_front())


## Saves the farm and lays the title screen over it again, where the farm list can switch to another farm.
func back_to_title() -> void:
	Saves.save_game()
	# A language change or deleting this farm reloads the scene, which must open on the title again.
	Saves.title_done = false
	close_windows()
	if _title == null:
		_show_title()


func title_open() -> bool:
	return _title != null


## True while the title screen covers the estate, so clicks and keys leave the farm alone.
func modal_open() -> bool:
	return _title != null


## Once the farm is on screen: on a new farm, or one left before its pets were chosen, the player chooses their dog
## and cat, after which Uncle Marcus welcomes them; otherwise, what happened while the player was away.
func _after_title() -> void:
	# A farmer who already has harvests behind them was welcomed long ago.
	if not Game.intro_seen and int(Game.stats.get("harvested", 0)) > 0:
		Game.intro_seen = true
	if not Game.intro_seen or not Game.pets_chosen:
		Game.intro_seen = true
		Saves.save_game()
		_choose_pets()
	elif not Saves.pending_summary.is_empty() or not _away_summary.is_empty():
		_show_away(Saves.pending_summary)
		Saves.pending_summary = {}


func _process(delta: float) -> void:
	_update_sleep(delta)
	_place_info()
	var in_strip := Windowing.strip
	# The title screen stands alone over the estate, without the farm's own panels.
	var titled := _title != null
	_stats_panel.visible = not in_strip and not titled
	_buttons.visible = not in_strip and not titled
	_zone_bar.visible = not in_strip and not titled
	_compact.visible = in_strip
	# The title screen waits behind the strip, which offers only the way back to it.
	for card in _open_cards():
		card.visible = not titled
	if titled:
		_title.visible = not in_strip
		if not _any_window():
			Ui.pad_focus(_title, _title_focus)
	elif visible and not _any_window() and not _open_cards().is_empty():
		Ui.pad_focus(_cards.back())
	if _bar_armed and not _bar_focused():
		_pad_bar(false)
	if _compact_market.visible == titled:
		_compact_label.visible = not titled
		_compact_market.visible = not titled
		_compact.reset_size()
	# The strip may not be made narrower than its two bars side by side, with a little room between them.
	Windowing.strip_min_width = int((_compact.size.x + _strip_controls.size.x + 24.0) * Windowing.ui_scale)
	if in_strip:
		for w in _windows:
			w.visible = false
	_compact_label.text = "%d   %d/%d" % [Game.coins, Game.stored_total(), Game.holding_capacity()]
	_coins.text = tr("Sestertii  %d") % Game.coins + (("   " + tr("Aurei  %d") % Game.aureus) if Game.aureus > 0 else "")
	_storage.text = tr("Storehouse  %d / %d") % [Game.in_storehouse(), Game.storage_capacity()]
	if Game.cart["away"]:
		_cart.text = tr("Trader back in  %s") % Ui.duration(float(Game.cart["time_left"]))
	elif Game.helpers.has("trader"):
		_cart.text = tr("Trader's cart  %d / %d") % [Game.on_cart(), Game.cart_capacity()]
	else:
		_cart.text = tr("Cart  %d / %d") % [Game.on_cart(), Game.cart_capacity()]
	# The farm's own running day count leads, the number players share; the weather is left to the sky to show.
	var cal := "%s   %s" % [tr("Day %d") % (Game.calendar.day + 1), tr(Game.calendar.season_name())]
	var festival: Dictionary = Game.calendar.festival()
	if not festival.is_empty():
		cal += "  " + tr(String(festival["name"]))
	if not Game.blessing.is_empty():
		cal += "\n" + tr("Blessing of %s") % tr(String(Game.gods()[Game.blessing["god"]]["name"]))
	_calendar.text = cal
	_update_toolbar()
	_update_tip()


## The interface is drawn at its own whole-number scale, laid out in the window's size divided by that scale.
func _fit() -> void:
	scale = Vector2(Windowing.ui_scale, Windowing.ui_scale)
	_root.position = Vector2.ZERO
	_root.size = (get_viewport().get_visible_rect().size / Windowing.ui_scale).floor()
	if _debug_layer:
		_debug_layer.scale = scale


## Everything of the interface showing over the strip: its bars, a message, a speech bubble or a window such as the
## summary of time away. On Windows the outline that lets clicks through the see-through strip also cuts away what is
## drawn outside it, so all of these must be inside it.
func strip_bar_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var whole := Rect2(Vector2.ZERO, _root.size)
	for child in _root.get_children():
		var c := child as Control
		if c == null or not c.is_visible_in_tree() or c.modulate.a < 0.01:
			continue
		var r := c.get_global_rect()
		# A full-screen layer, such as the title screen's, is not a piece of interface floating over the farm.
		if r.has_area() and not r.encloses(whole):
			rects.append(r)
	# The achievement cards' layer covers the screen, but the card sliding along it is interface over the farm.
	var card: Rect2 = _achievements.card_rect()
	if card.has_area():
		rects.append(card)
	return rects


## True while a window, a card waiting for its button or the interface's own buttons have the gamepad, so the estate
## leaves the d-pad and the A button to them.
func window_open() -> bool:
	return _any_window() or not _open_cards().is_empty() or (_bar_armed and _bar_focused())


func _any_window() -> bool:
	for w in _windows:
		if w.visible:
			return true
	return false


func _open_cards() -> Array:
	_cards = _cards.filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion())
	return _cards


## The interface's own buttons on the estate, which a gamepad reaches with Start: the toolbar, the windows' buttons,
## the zone bar, the sleep button and Uncle Marcus's buttons.
func _bar_buttons() -> Array:
	var all: Array = [_sleep_button]
	for row in [_tool_row, _buttons, _zone_bar]:
		all.append_array(row.get_children())
	all.append_array(_uncle.find_children("*", "Button", true, false))
	return all


func _bar_focused() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and f in _bar_buttons()


## Start hands a gamepad the interface's buttons, starting from the tool in hand, and Start or B hands it back to the estate.
func _pad_bar(on: bool) -> void:
	if not on and _bar_focused():
		get_viewport().gui_release_focus()
	_bar_armed = on
	for b in _bar_buttons():
		b.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
	if on:
		var current := "seed:" + Game.selected_seed if tool == "seed" else tool
		var start: Button = _tool_buttons.get(current, _tool_buttons.values()[0])
		start.grab_focus()


## The keyboard reaches the newest window first, then the title, then a card waiting for its button; on the farm Tab
## hands it the toolbar, as Start does a gamepad, while the arrow keys keep moving over the estate.
func _on_key_nav(event: InputEvent) -> void:
	var had := get_viewport().gui_get_focus_owner() != null
	var target: Control = null
	for w in _windows:
		if w.visible:
			target = w
	if target == null and _title != null and _title.visible:
		target = _title
	if target == null and not _open_cards().is_empty():
		target = _cards.back()
	if target != null:
		Ui.pad_focus(target)
	elif visible and not Windowing.strip and not had and (event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev")):
		_pad_bar(true)
	else:
		return
	if not had and get_viewport().gui_get_focus_owner() != null:
		get_viewport().set_input_as_handled()


func close_windows() -> bool:
	var any := false
	for w in _windows:
		if w.visible:
			w.close()
			any = true
	return any


func show_building(id: String) -> void:
	_building.id = id
	# Uncle Marcus's advice to look at the house is followed once its window has been opened.
	if id == VILLA:
		Game.add_stat("villa_viewed", 1)
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


## Steps inside the farmhouse, from its window.
func request_house() -> void:
	close_windows()
	house_requested.emit()


func open_window(name: String) -> void:
	var w: WindowPanel = {"store": _store, "helpers": _helpers, "journal": _journal, "settings": _settings, "upgrades": _upgrades, "companions": _companions}.get(name)
	if _title:
		_title_focus = Ui.focus_hint(_title)
	if w and not w.visible:
		_open(w)


## Highlights the zone the camera is looking at in the zone bar.
func set_zone(zone_id: String) -> void:
	for id in _zone_buttons:
		_zone_buttons[id].button_pressed = id == zone_id


## Hover text for what is under the pointer on the estate.
func set_info(text: String) -> void:
	_info.visible = text != ""
	_info.text = text
	_place_info()


## The hover text sits just above the pointer, so it never hides the plants along the bottom of the field.
func _place_info() -> void:
	if not _info.visible:
		return
	var at := get_viewport().get_mouse_position() / Windowing.ui_scale
	var size := _info.get_minimum_size()
	_info.position = (at + Vector2(8, -size.y - 6)).clamp(Vector2(2, 2), _root.size - size - Vector2(2, 2)).round()


func toast(text: String) -> void:
	# Messages from the farm loading behind the title screen are not news to the player yet.
	if _title != null:
		return
	# Messages that arrive together wait their turn; a long wait keeps the newest four, a repeated one moving to the back.
	if not visible or (_toast_tween and _toast_tween.is_running() and _toast.text != text):
		_toast_queue.erase(text)
		_toast_queue.append(text)
		if _toast_queue.size() > 4:
			_toast_queue.pop_front()
		return
	_show_toast(text)


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	var view := _root.size
	# A long message wraps within the screen, a little in from its edges.
	_toast.position = Vector2(8, roundf(view.y * 0.2))
	_toast.size = Vector2(view.x - 16, 0)
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
	_toast_tween.tween_callback(func(): if visible and not _toast_queue.is_empty(): _show_toast(_toast_queue.pop_front()))


## A speech bubble above someone on the estate, which stays over them; spot returns where it points, in estate pixels
## relative to the view's corner.
func say(spot: Callable, text: String) -> void:
	var on_screen := func() -> Vector2: return (spot.call() * Windowing.scale / Windowing.ui_scale).round()
	Ui.speech(_root, on_screen.call(), text, on_screen)


## Text that floats up from a spot on screen; pos is in estate pixels relative to the view's corner.
func float_text(pos: Vector2, text: String) -> void:
	var l := Ui.label(_root, text, true)
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
			Audio.play("page_turn")
		w.open()


func _add_window(w: WindowPanel) -> WindowPanel:
	_root.add_child(w)
	_windows.append(w)
	return w


func _apply_text_size() -> void:
	for l in [_info, _toast, _tip]:
		l.add_theme_font_size_override("font_size", UiTheme.text_size() * (2 if Settings.large_text else 1))


## Uncle Marcus gives the next piece of advice once the farm is settled in: after the choice of pets,
## and never over the title screen or the strip. When every step is done he says goodbye, once. At any time, even
## after the tutorial, he comes back when the farm is short of money: with coins if it has no way to earn, or with
## a word to sell what is in the storehouse first. A step with praise, such as restoring the farmhouse, earns that
## praise before his next advice.
func _update_tip() -> void:
	_tip.visible = false
	_uncle.position = Vector2.ZERO
	var settled := not Windowing.strip and _title == null and Game.pets_chosen
	var ready := settled and Settings.show_tutorial
	# He steps aside while a window is open, so his advice never covers it, and returns without sliding in again.
	if settled and _any_window():
		_uncle.visible = false
		return
	if not _notice.is_empty() and _uncle.dismissed() == String(_notice["id"]):
		_notice = {}
	var step: Dictionary = Game.journal.tutorial_step() if ready else {}
	if ready and step != _last_step:
		if _last_step.has("praise") and Game.journal.met(_last_step["done"]):
			_notice = {"id": "praise " + String(_last_step["id"]), "text": tr(String(_last_step["praise"]))}
		_last_step = step
	var notice := _notice
	if notice.is_empty() and ready and Game.short_of_seed() and Game.stored_total() > 0 and not Game.cart["away"]:
		notice = {"id": "sell_first", "text": tr("Your purse is empty, but the storehouse is not. Send the cart to market, then plant again.")}
	if settled and not notice.is_empty():
		_uncle.show_advice(String(notice["id"]), String(notice["text"]))
		return
	if not step.is_empty():
		Game.stats["guide_seen"] = 1
		_uncle.show_advice(String(step["id"]), tr(String(step["text"])), true)
	elif ready and int(Game.stats.get("guide_seen", 0)) == 1:
		# The goodbye stays a while, then he is gone for good.
		if _uncle.showing() != "farewell":
			_uncle.show_advice("farewell", tr(String(Data.get_value("tutorial_farewell", ""))))
			get_tree().create_timer(14.0).timeout.connect(func(): Game.stats["guide_seen"] = 2)
	else:
		_uncle.show_advice("", "")


func _on_discovered(id: String) -> void:
	var kind := id.get_slice(":", 0)
	if kind in ["quality", "item", "building", "helper", "crop", "festival"]:
		return
	for e in Game.journal.catalogue():
		if e["id"] == id:
			toast(tr("New in the journal: %s") % tr(String(e["name"])))
			return


func _on_festival(id: String) -> void:
	for f in Data.get_value("calendar.festivals", []):
		if f["id"] == id:
			toast(tr("%s! %s") % [tr(String(f["name"])), tr(String(f.get("about", "")))])


func _build_zone_bar() -> void:
	_zone_bar = HBoxContainer.new()
	_root.add_child(_zone_bar)
	for z in Game.zones():
		var id: String = z["id"]
		var b := Ui.button(_zone_bar, tr(SHORT_ZONES.get(id, id)), func(): zone_chosen.emit(id))
		b.toggle_mode = true
		_zone_buttons[id] = b
	_zone_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_zone_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_zone_bar.offset_top = 4


## On a new farm the player names the dog and cat; however the window goes away, even hidden by another, the pets then come home.
func _choose_pets() -> void:
	_open(_companions)
	_companions.visibility_changed.connect(_pets_chosen)


## Once the pets are home the uncle can start with his advice.
func _pets_chosen() -> void:
	if _companions.visible:
		return
	_companions.visibility_changed.disconnect(_pets_chosen)
	if not Game.pets_chosen:
		Game.pets_chosen = true
		Game.pets_changed.emit()
	_update_tip()


func _on_achievement(a: Dictionary) -> void:
	if a.get("special", false):
		_triumph()
		return
	_achievements.add(a)


## Earning every achievement is celebrated like a Roman triumph: a fanfare, rose petals thrown over the whole view, and
## a word of honour, while a golden laurel wreath is hung above the villa door.
func _triumph() -> void:
	Audio.play("triumph")
	var petals := CPUParticles2D.new()
	var view := _root.size
	petals.position = Vector2(view.x / 2.0, -6)
	petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	petals.emission_rect_extents = Vector2(view.x / 2.0, 2)
	petals.amount = 26 if Settings.reduced_motion else 90
	petals.lifetime = 9.0
	petals.one_shot = true
	petals.explosiveness = 0.0
	petals.direction = Vector2.DOWN
	petals.spread = 25.0
	petals.initial_velocity_min = 26.0
	petals.initial_velocity_max = 44.0
	petals.gravity = Vector2(5, 16)
	petals.texture = _petal_texture()
	petals.angular_velocity_min = -160.0
	petals.angular_velocity_max = 160.0
	petals.scale_amount_min = 2.0
	petals.scale_amount_max = 3.0
	var colours := Gradient.new()
	colours.colors = PackedColorArray([Color(0.86, 0.22, 0.3), Color(0.95, 0.55, 0.62), Color(0.98, 0.84, 0.4)])
	petals.color_initial_ramp = colours
	_root.add_child(petals)
	petals.emitting = true
	get_tree().create_timer(12.0).timeout.connect(petals.queue_free)
	var p := PanelContainer.new()
	_root.add_child(p)
	var col := Ui.column(p)
	var head := Ui.label(col, tr("Triumph!"))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_color_override("font_color", Color(0.62, 0.2, 0.14))
	var wreath := TextureRect.new()
	wreath.texture = load("res://assets/sprites/icons32/laurel.png")
	wreath.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	wreath.custom_minimum_size = Vector2(32, 32)
	col.add_child(wreath)
	Ui.para(col, tr("Every achievement on the estate is yours. Rome honours you with a triumph, and a golden laurel wreath now hangs above the villa door."), 200)
	Ui.button(col, tr("Ave!"), p.queue_free)
	_centre_card(p)
	Ui.fade_in(p, 0.6)


## A rose petal a few pixels across, white so the particles can colour it.
func _petal_texture() -> Texture2D:
	var img := Image.create(4, 3, false, Image.FORMAT_RGBA8)
	for p in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 2), Vector2i(2, 2)]:
		img.set_pixelv(p, Color(1, 1, 1, 1) if p.y < 2 else Color(0.8, 0.8, 0.8, 1))
	return ImageTexture.create_from_image(img)


## The farm catches up after every pause in play, but only a real absence is worth a summary.
func _on_caught_up(summary: Dictionary) -> void:
	if float(summary.get("seconds", 0)) >= float(Data.get_value("offline.min_seconds_for_summary", 30)):
		_show_away(summary)


## What happened while the player was away. It waits while the title screen is up, and a second catch-up adds its time
## and harvests to the summary showing; how the farm stands now comes from the newer one.
func _show_away(news: Dictionary) -> void:
	var summary := _away_summary.merged(news, true)
	for key in ["seconds", "harvested", "made", "earned"]:
		summary[key] = _away_summary.get(key, 0) + news.get(key, 0)
	_away_summary = summary
	if _title != null:
		return
	if is_instance_valid(_away):
		_away.queue_free()
	var p := PanelContainer.new()
	_away = p
	_root.add_child(p)
	var col := Ui.column(p)
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
		lines.append(tr("The storehouse and the cart are full"))
	for line in lines:
		Ui.label(col, line)
	Ui.button(col, tr("Lovely"), func():
		p.queue_free()
		_away_summary = {})
	_centre_card(p)


## A card that waits for its one button, centred on whatever the view is, so it fits the desktop strip as well as the
## full window; a gamepad presses its button with A, or with B.
func _centre_card(p: PanelContainer) -> void:
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	_cards.append(p)


## The small bar shown in the desktop strip instead of the full panels.
func _build_compact() -> void:
	_compact = PanelContainer.new()
	_root.add_child(_compact)
	var row := Ui.row(_compact)
	_compact_label = Ui.label(row)
	_compact_market = Ui.button(row, tr("Market"), func(): Windowing.toggle_strip(); town_requested.emit())
	Ui.button(row, tr("Expand"), func(): Windowing.toggle_strip())
	# Top-left, where the strip shows only sky or desktop, so it never covers the cart or the plots.
	_compact.position = Vector2(4, 4)
	_compact.visible = false


func _build_debug() -> void:
	# The debug panel has a layer of its own above everything, so it also opens inside the farmhouse and in the town,
	# where the rest of the interface is hidden.
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 30
	_debug_layer.scale = scale
	add_child.call_deferred(_debug_layer)
	var holder := Control.new()
	holder.theme = UiTheme.build()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_debug_layer.add_child(holder)
	_debug = PanelContainer.new()
	_debug.position = Vector2(4, 70)
	_debug.visible = false
	holder.add_child(_debug)
	var col := Ui.column(_debug)
	Ui.label(col, "Debug (F1)")
	for s in [1, 10, 60]:
		Ui.button(col, "Speed x%d" % s, func(): Game.speed = s; toast("Time speed x%d" % s))
	Ui.button(col, "Skip 1 hour", func(): _show_away(Game.simulate_offline(3600)))
	Ui.button(col, "+10000 sestertii", func(): Game.coins += 10000)
	Ui.button(col, "+10 materials", func(): for m in ["stone", "timber", "tiles", "bread"]: Game.add_item(m, 10, true))
	Ui.button(col, "Rain", func(): Game.calendar.weather_left = 0.0; Game.calendar.weather = "rain"; Game.calendar.wet_left = 240.0)
	Ui.button(col, "Next day", func(): Game.calendar.next_day(); Game.market.new_day())
	Ui.button(col, "Save now", func(): Saves.save_game(); toast("Saved"))
	Ui.button(col, "Reset farm", func(): Saves.reset(); get_tree().reload_current_scene())


func _unhandled_input(event: InputEvent) -> void:
	# A window opened over the title screen, such as the settings, closes with Escape or B like any other.
	if event.is_action_pressed("close_panel") and _go_back():
		get_viewport().set_input_as_handled()
		return
	if modal_open():
		return
	# The farm's own keys wait while the interface is hidden in the market or the farmhouse, or shrunk to the strip.
	var on_farm := visible and not Windowing.strip
	# The debug panel, with its free coins and farm reset, only opens in development builds, never for players.
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1 and OS.is_debug_build():
		_debug.visible = not _debug.visible
	elif on_farm and event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var slots := _tool_buttons.keys()
		var k := int(event.keycode - KEY_1)
		if k < slots.size():
			select_tool(String(slots[k]))
			get_viewport().set_input_as_handled()
	elif on_farm and event.is_action_pressed("open_journal"):
		_open(_journal)
		get_viewport().set_input_as_handled()
	elif on_farm and event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START and (_bar_armed or not window_open()):
		_pad_bar(not _bar_armed)
		get_viewport().set_input_as_handled()


## Escape or B closes what is open, the newest first: a window, then a step of the title's menu, then a card waiting
## for its button, then the gamepad's turn on the interface's buttons. True if there was something to close.
func _go_back() -> bool:
	if close_windows():
		return true
	if _title and _title.go_back():
		return true
	if not _open_cards().is_empty():
		var button: Button = _cards.back().find_children("*", "Button", true, false)[0]
		button.pressed.emit()
		return true
	if _bar_armed:
		_pad_bar(false)
		return true
	return false



## Sleeping runs the night by in a few seconds instead of skipping it, so the sky and the light can be seen changing.
func _start_sleep() -> void:
	_slept = 0.0
	close_windows()
	toast(tr("Good night..."))


func _update_sleep(delta: float) -> void:
	var night := Game.day_time >= SLEEP_FROM or Game.day_time < WAKE_AT - 1.5
	_sleep_button.visible = night and _slept < 0.0
	if _slept < 0.0:
		return
	_slept += delta
	var left := fposmod(WAKE_AT - Game.day_time, 24.0) / 24.0 * Game.day_seconds()
	# The night shrinks to a sliver of its length every second, easing in at the start and out towards dawn.
	Game.speed = maxf(1.0, left * 0.9 * minf(1.0, _slept / 0.8))
	if left < 20.0 or _slept > 12.0:
		Game.speed = 1.0
		_slept = -1.0


## The toolbar along the bottom: harvest, a seed for every crop the estate has, and the spade for digging plants up.
func _build_toolbar() -> void:
	_toolbar = PanelContainer.new()
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.33, 0.2, 0.13)
	frame.border_color = Color(0.22, 0.13, 0.09)
	frame.set_border_width_all(1)
	frame.set_content_margin_all(2)
	_toolbar.add_theme_stylebox_override("panel", frame)
	_root.add_child(_toolbar)
	_tool_row = Ui.row(_toolbar)
	_tool_row.add_theme_constant_override("separation", 1)


## Small picture buttons for the estate's main windows, matching the illustrated controls in Fishus Maximus.
func _top_button(parent: Node, label: String, picture: Texture2D, action: Callable) -> Button:
	var b := Ui.button(parent, "", action)
	b.name = label.replace(" ", "") + "Button"
	Ui.tip_on(b, label)
	b.custom_minimum_size = Vector2(20, 20)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	var image := TextureRect.new()
	image.name = "Picture"
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture = picture
	image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = 2
	image.offset_top = 2
	image.offset_right = -2
	image.offset_bottom = -2
	b.add_child(image)
	return b


func _update_toolbar() -> void:
	_toolbar.visible = _title == null
	var sig := JSON.stringify(Game.crops_unlocked)
	if sig != _tool_signature:
		_tool_signature = sig
		Ui.clear(_tool_row)
		_tool_buttons = {}
		_tool_slot("harvest", load("res://assets/sprites/icons/tool_harvest.png"), tr("Harvest: click ripe plants to pick them"), Color.WHITE)
		for crop in Data.get_value("seeds", []):
			if not Game.crop_unlocked(crop):
				continue
			var info := Game.crop_info(crop)
			var item := String(info.get("item", crop))
			var path := "res://assets/sprites/icons/%s.png" % item
			var tint: Color = SEED_TINTS.get(crop, Color.WHITE)
			var text := tr("Plant %s: %d sestertii") % [Ui.mid(tr(String(info.get("name", crop)))), int(info.get("plant_cost", 0))]
			_tool_slot("seed:" + crop, load(path) if ResourceLoader.exists(path) else null, text, tint)
		_tool_slot("dig", load("res://assets/sprites/icons/tool_dig.png"), tr("Dig up: clear a plant from its bed"), Color.WHITE)
	var current := "seed:" + Game.selected_seed if tool == "seed" else tool
	for id in _tool_buttons:
		_tool_buttons[id].button_pressed = id == current
	_toolbar.position = Vector2(roundf((_root.size.x - _toolbar.size.x) / 2.0), _root.size.y - _toolbar.size.y - 2)


func _tool_slot(id: String, icon: Texture2D, text: String, tint: Color) -> void:
	var b := Button.new()
	b.icon = icon
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(18, 18)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var box := StyleBoxFlat.new()
		var chosen: bool = state.contains("pressed")
		box.bg_color = Color(0.98, 0.92, 0.78) if chosen else (Color(0.9, 0.8, 0.62) if state == "hover" else Color(0.83, 0.71, 0.52))
		box.border_color = Color(0.7, 0.38, 0.25) if chosen else Color(0.55, 0.4, 0.28)
		box.set_border_width_all(1)
		box.set_content_margin_all(0)
		# The slot a gamepad is on is ringed in cream over its own look, as the interface's other buttons are.
		if state == "focus":
			box.draw_center = false
			box.border_color = UiTheme.CREAM
		b.add_theme_stylebox_override(state, box)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(state, tint)
	# A gamepad that has chosen its tool goes straight back to the field to use it.
	b.pressed.connect(func():
		select_tool(id)
		if _bar_armed:
			_pad_bar(false))
	Ui.tip_on(b, text)
	_tool_row.add_child(b)
	_tool_buttons[id] = b


func select_tool(id: String) -> void:
	Audio.play("tab", -6.0)
	if id.begins_with("seed:"):
		tool = "seed"
		Game.selected_seed = id.get_slice(":", 1)
	else:
		tool = id
	_update_toolbar()


## The row just above the toolbar, where messages about the pointer and tips are shown.
func _above_toolbar() -> float:
	return _toolbar.position.y if _toolbar and _toolbar.visible else _root.size.y
