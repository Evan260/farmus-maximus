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
