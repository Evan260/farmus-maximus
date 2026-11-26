extends "res://tests/test_case.gd"
## Checks of interface behaviour that needs no farm scene: achievement cards, the default interface size and the demo's
## wishlist button.


func test_an_achievement_waits_for_an_open_window() -> void:
	var popup: Control = load("res://scripts/ui/achievement_popup.gd").new()
	popup.theme = UiTheme.build()
	var windows := {"open": true}
	popup.window_open = func(): return windows["open"]
	root.add_child(popup)
	popup.add({"name": "First harvest", "desc": "Harvest a crop"})
	await create_timer(0.3).timeout
	check(popup._card == null, "a card earned with a window open waits rather than covering it")
	windows["open"] = false
	await create_timer(0.3).timeout
	check(popup._card != null, "and slides in once the window has closed")
	popup.free()


func test_an_achievement_stays_on_a_short_screen() -> void:
	var holder := Control.new()
	holder.size = Vector2(606, 270)
	root.add_child(holder)
	var buttons := Control.new()
	buttons.position = Vector2(570, 14)
	buttons.size = Vector2(29, 194)
	holder.add_child(buttons)
	var bar := Control.new()
	bar.position = Vector2(200, 14)
	bar.size = Vector2(212, 29)
	holder.add_child(bar)
	var popup: Control = load("res://scripts/ui/achievement_popup.gd").new()
	popup.below = buttons
	popup.clear_of = [bar]
	holder.add_child(popup)
	var card := Vector2(170, 64)
	var spot: Vector2 = popup._rest(card)
	var screen := Rect2(Vector2.ZERO, holder.size).grow(-popup.MARGIN)
	check(screen.encloses(Rect2(spot, card)), "on a phone's short screen the whole card stays on screen (%s)" % spot)
	check(not Rect2(spot, card).intersects(buttons.get_rect()) and not Rect2(spot, card).intersects(bar.get_rect()), "beside the corner buttons and clear of the zone bar")
	holder.size = Vector2(640, 360)
	check(popup._rest(card).y == buttons.get_rect().end.y + popup.MARGIN, "a taller screen keeps it just below the buttons")
	holder.free()


func test_small_screens_get_a_bigger_default_interface() -> void:
	var w: GDScript = load("res://scripts/autoload/windowing.gd")
	check(w.ui_scale_for(Vector2i(1280, 720), 0) == 2, "a 1280x720 window shows the interface at twice its size")
	check(w.ui_scale_for(Vector2i(1280, 800), 0) == 2, "and so does the Steam Deck's screen")
	check(w.ui_scale_for(Vector2i(1280, 800), -1) == 1, "where Smaller is still smaller")
	check(w.ui_scale_for(Vector2i(1920, 1080), 0) == 3, "a 1080p screen keeps its size")
	check(w.ui_scale_for(Vector2i(2560, 1440), 0) == 4, "and so does a 1440p screen")
	check(w.ui_scale_for(Vector2i(640, 400), 2) == 1, "the smallest window never outgrows its room")


func test_the_demo_offers_the_wishlist_once_the_game_has_an_app_id() -> void:
	var data: Node = root.get_node("Data")
	var demo: Dictionary = data.data["demo"]
	var holder := VBoxContainer.new()
	Game.acts_as_demo = true
	check(Ui.wishlist_button(holder) == null, "the demo hides the wishlist button while the full game has no app id")
	demo["full_game_app_id"] = 480
	data._found = {}
	check(Ui.wishlist_button(holder) != null, "and shows it once the app id is set")
	check(Awards.store_url() == "https://store.steampowered.com/app/480/", "which opens the web store without Steam running")
	Game.acts_as_demo = false
	check(Ui.wishlist_button(holder) == null, "the full game never shows it")
	demo["full_game_app_id"] = 0
	data._found = {}
	holder.free()


## The game's copy of the full game's app id is the one the Steam uploads use.
func test_the_wishlist_app_id_matches_the_steam_settings() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/steam/steam.json")
	var steam: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(steam is Dictionary, "tools/steam/steam.json can be read")
	if steam is Dictionary:
		var game_id := int(steam["targets"]["game"]["app_id"])
		check(game_id == int(Data.get_value("demo.full_game_app_id", -1)), "demo.full_game_app_id in balance.json is the game's app id in steam.json")


func test_rich_presence_tells_steam_only_what_changed() -> void:
	Game.new_game()
	Game.villa_stage = 3
	Game.calendar.day = 41
	var awards: Node = root.get_node("Awards")
	check(awards.presence() == {"stage": "3", "day": "42", "steam_display": "#Estate"}, "on the estate friends see the villa's stage and the day")
	awards.update_presence()
	check(awards._presence.is_empty(), "nothing is sent while Steam is not running")
	var steam := FakeSteam.new()
	awards._steam = steam
	awards.update_presence()
	awards.update_presence()
	check(steam.sent.size() == 3, "each key is sent once while it stays the same")
	Game.calendar.day = 42
	awards.update_presence()
	check(steam.sent.size() == 4 and steam.sent[3] == ["day", "43"], "a new day sends only the day")
	awards._steam = null
	awards._presence = {}
	Game.new_game()


## Every status the game shows is in the rich presence file Steamworks is given, in all fourteen languages.
func test_the_rich_presence_file_has_every_token() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../tools/steam/rich_presence.vdf")
	var text := FileAccess.get_file_as_string(path)
	for language in ["english", "french", "german", "spanish", "italian", "brazilian", "polish", "turkish", "russian",
			"ukrainian", "japanese", "koreana", "schinese", "tchinese"]:
		var start := text.find("\"%s\"" % language)
		check(start >= 0, "rich_presence.vdf has %s" % language)
		var end := text.find("\n\t}", start)
		var block := text.substr(start, end - start)
		for token in ["#Estate", "#Town", "#Inside", "#Title"]:
			check(block.contains("\"%s\"" % token), "%s has %s" % [language, token])
		for n in Game.villa_stages().size():
			check(block.contains("\"#Villa_%d\"" % (n + 1)), "%s names villa stage %d" % [language, n + 1])



func test_a_gamepad_presses_and_backs_out_of_buttons() -> void:
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	a.pressed = true
	check(a.is_action_pressed("ui_accept"), "A presses the chosen button")
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_B
	b.pressed = true
	check(b.is_action_pressed("ui_cancel"), "and B backs out")


func test_the_gamepad_scrolls_the_open_list() -> void:
	var holder := Control.new()
	holder.size = Vector2(300, 200)
	root.add_child(holder)
	var list := Ui.scroll(holder, Vector2(200, 80))
	var first := Ui.button(list, "First", func(): pass)
	first.focus_mode = Control.FOCUS_ALL
	for k in 30:
		Ui.label(list, "Line %d" % k)
	await process_frame
	await process_frame
	first.grab_focus()
	var scroll: ScrollContainer = list.get_parent().get_parent()
	check(KeyNav.open_list() == scroll, "the list around the chosen button is the one the gamepad scrolls")
	var rb := InputEventJoypadButton.new()
	rb.button_index = JOY_BUTTON_RIGHT_SHOULDER
	rb.pressed = true
	KeyNav._input(rb)
	check(scroll.scroll_vertical > 40, "a shoulder button scrolls it a page")
	var glyph := Ui.pad_glyph(holder, JOY_BUTTON_Y)
	KeyNav._set_pad(false)
	check(not glyph.visible, "button pictures hide while the keyboard or mouse is in use")
	KeyNav._set_pad(true)
	check(glyph.visible, "and show once the gamepad is used")
	KeyNav._set_pad(KeyNav.pad_connected())
	first.release_focus()
	holder.free()


func test_the_shoulder_buttons_turn_the_journal() -> void:
	Game.new_game()
	var journal: Control = load("res://scripts/ui/journal_panel.gd").new()
	root.add_child(journal)
	journal.open()
	await process_frame
	var rb := InputEventJoypadButton.new()
	rb.button_index = JOY_BUTTON_RIGHT_SHOULDER
	rb.pressed = true
	journal._input(rb)
	check(journal.section == "Goods", "the right shoulder turns to the next section")
	journal.free()


func test_a_phones_journal_tabs_are_a_fingertip_tall_and_scroll() -> void:
	Game.new_game()
	var was := [Windowing.phone, Windowing.phone_preview]
	Windowing.phone = true
	Windowing.phone_preview = true
	var journal: Control = load("res://scripts/ui/journal_panel.gd").new()
	root.add_child(journal)
	journal.open()
	await process_frame
	await process_frame
	var tabs: Array = journal.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text in journal.SECTIONS.map(func(s): return tr(s)))
	var finger := Windowing.touch_px()
	check(tabs.size() == journal.SECTIONS.size() and tabs.all(func(b: Button) -> bool: return b.size.y >= finger), "every section's tab is a fingertip tall on a phone (%d tabs, fingertip %d)" % [tabs.size(), finger])
	var list: Node = tabs[0].get_parent().get_parent() if tabs.size() > 0 else null
	check(list is ScrollContainer and list.size.y <= journal.PAGE_H + journal.STACK + 1, "and they scroll beside the book rather than making it taller")
	journal.free()
	Windowing.phone = was[0]
	Windowing.phone_preview = was[1]


func test_a_phones_sliders_have_a_knob_a_finger_can_hold() -> void:
	var theme: GDScript = load("res://scripts/ui/ui_theme.gd")
	check(theme.knob_size(0) == Vector2i(5, 9), "a computer keeps the small knob")
	var k: Vector2i = theme.knob_size(29)
	check(k.y >= 18 and k.x >= 9, "a phone's knob is most of a fingertip tall and wide enough to see: %s" % k)
	check(theme.track_half(29) > theme.track_half(0), "and its track is thicker")


class FakeSteam:
	var sent: Array = []

	func setRichPresence(key: String, value: String) -> bool:
		sent.append([key, value])
		return true


## The boot splash is the logo at a whole-number scale, unfiltered at its own size, and the game's first frames repeat it.
func test_the_boot_splash_is_the_crisp_logo() -> void:
	var image: Texture2D = load(String(ProjectSettings.get_setting("application/boot_splash/image")))
	var logo: Texture2D = load("res://tools/trailer/logo.png")
	check(image != null and image.get_width() % logo.get_width() == 0 and image.get_height() / logo.get_height() == image.get_width() / logo.get_width(),
		"the boot splash is the logo enlarged by a whole number")
	check(not ProjectSettings.get_setting("application/boot_splash/use_filter"), "and is drawn without smoothing")
	check(int(ProjectSettings.get_setting("application/boot_splash/stretch_mode")) == 0, "at its own size")
	var cover: CanvasLayer = load("res://scripts/ui/boot_cover.gd").new()
	root.add_child(cover)
	var rect: ColorRect = cover.get_child(0)
	check(rect.color == ProjectSettings.get_setting("application/boot_splash/bg_color"), "the first frame is the splash's colour")
	cover.free()


func test_a_click_held_for_a_moment_still_presses_a_button_that_takes_focus() -> void:
	var b := Button.new()
	b.text = "Go"
	b.focus_mode = Control.FOCUS_ALL
	b.position = Vector2(10, 10)
	b.size = Vector2(60, 20)
	root.add_child(b)
	var hits := [0]
	b.pressed.connect(func(): hits[0] += 1)
	await process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = b.get_global_rect().get_center()
	down.global_position = down.position
	root.push_input(down)
	# A finger rests a few frames before it lifts, as a real tap does.
	for i in 4:
		await process_frame
	var up: InputEventMouseButton = down.duplicate()
	up.pressed = false
	root.push_input(up)
	await process_frame
	check(hits[0] == 1, "a click held over a few frames still presses a button that takes the focus (%d presses)" % hits[0])
	check(root.gui_get_focus_owner() != b, "and the button lets the focus go once the click is over")
	b.free()


func test_phones_draw_the_interface_as_large_as_it_fits() -> void:
	var w: GDScript = load("res://scripts/autoload/windowing.gd")
	check(w.phone_ui_scale(Vector2i(2424, 1080), 0) == 4, "a Pixel 9a draws the interface at four times, not three")
	check(w.phone_ui_scale(Vector2i(2424, 1080), 2) == 4, "Larger can't push it past what fits")
	check(w.phone_ui_scale(Vector2i(2424, 1080), -1) == 3, "Smaller still makes it smaller")


func test_phone_corner_panels_clear_the_camera_and_rounded_corners() -> void:
	var w: GDScript = load("res://scripts/autoload/windowing.gd")
	var insets: Array = w.phone_insets(Vector2i(2424, 1080), Rect2i(136, 0, 2288, 1080), 4)
	check(insets[0] == Vector2(34, 10), "the left clears the camera cutout and the top clears the corner: %s" % insets[0])
	check(insets[1] == Vector2(10, 10), "the right and bottom clear the rounded corners: %s" % insets[1])


func test_a_fingertip_target_is_about_seven_millimetres() -> void:
	var w: GDScript = load("res://scripts/autoload/windowing.gd")
	check(w.touch_px_for(420.0, 4) == 29, "a Pixel 9a's fingertip is 29 interface pixels at four times: %d" % w.touch_px_for(420.0, 4))
	check(w.touch_px_for(420.0, 3) > w.touch_px_for(420.0, 4), "a smaller interface needs more of its pixels for the same finger")


func test_a_finger_held_still_asks_rather_than_taps() -> void:
	check(not Touch.is_hold(0.2, 0.0, 30.0), "a quick touch is a tap")
	check(Touch.is_hold(0.5, 10.0, 30.0), "a finger resting in place for half a second is held")
	check(not Touch.is_hold(0.5, 60.0, 30.0), "a finger that slid away is not held")
	check(Touch.is_tap(5.0, 30.0, false), "a short touch that stayed put taps")
	check(not Touch.is_tap(5.0, 30.0, true), "lifting a held finger does not tap as well")
	check(not Touch.is_tap(60.0, 30.0, false), "a finger slid away does not tap")


func test_the_back_gesture_closes_the_newest_thing_first() -> void:
	check(Touch.back_step(true, true, false) == "close", "an open window closes before anything else")
	check(Touch.back_step(false, true, false) == "leave", "then the market or the farmhouse is left")
	check(Touch.back_step(false, false, false) == "title", "then the farm goes back to the title")
	check(Touch.back_step(false, false, true) == "background", "and on the title the game is put away")
