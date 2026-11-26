extends "res://tests/test_case.gd"
## Notifications and achievements on a phone: what the farm tells the player while the game is put away, and the link
## to the phone's own services, which does nothing until the native plugin is in the build.

const NOTICES := "res://scripts/game/phone_notices.gd"


func _farm() -> Node:
	var game: Node = root.get_node("Game")
	game.new_game()
	game.day_time = 8.0
	game.calendar.wet_left = 9999.0
	return game


func _plan(game: Node) -> Dictionary:
	var by_id := {}
	var notices: GDScript = load(NOTICES) if ResourceLoader.exists(NOTICES) else null
	if notices == null:
		return by_id
	for n in notices.plan(game):
		by_id[n["id"]] = n
	return by_id


func _phone() -> Node:
	return root.get_node_or_null("PhoneServices")


func _step() -> float:
	return float(Data.get_value("notifications.step_seconds", 60))


func test_the_cart_on_the_road_is_announced_when_it_comes_home() -> void:
	var game := _farm()
	game.cart = {"away": true, "time_left": 15.0, "items": 10, "value": 120, "load": ["lavender"]}
	var plan := _plan(game)
	check(plan.has("cart") and is_equal_approx(float(plan["cart"]["seconds"]), 15.0), "the cart's return is planned for when it gets home")
	check(plan.has("cart") and String(plan["cart"]["text"]).contains("120"), "and says what it brings")
	check(plan.has("cart") and plan["cart"]["title"] == tr("The cart is home"), "under a title of its own")
	game.cart = game._empty_cart()
	check(not _plan(game).has("cart"), "a cart standing in the yard is not announced")
	game.new_game()


func test_builders_finishing_are_announced() -> void:
	var game := _farm()
	game.villa_build = {"active": true, "time_left": 300.0}
	game.projects["storage"] = 120.0
	game.buildings["mill"]["state"] = "repairing"
	game.buildings["mill"]["time_left"] = 200.0
	var plan := _plan(game)
	for job in [["build_villa", 300.0], ["build_storage", 120.0], ["build_mill", 200.0]]:
		var at: float = float(plan[job[0]]["seconds"]) if plan.has(job[0]) else -1.0
		check(at >= job[1] and at <= job[1] + _step(), "%s is announced when the builders finish (%.0f s)" % [job[0], at])
	check(plan.has("build_villa") and plan["build_villa"]["title"] == tr(String(game.villa_stages()[1]["name"])), "the farmhouse's notice names the stage being built")
	check(plan.has("build_mill") and plan["build_mill"]["title"] == tr("Mill") and plan["build_mill"]["text"] == tr("The work is finished"), "and a building's names the building")
	game = _farm()
	game.day_time = 23.0
	check(game.is_night(), "11 at night is dark")
	game.villa_build = {"active": true, "time_left": 60.0}
	var dawn: float = game.seconds_until_day()
	plan = _plan(game)
	var at: float = float(plan["build_villa"]["seconds"]) if plan.has("build_villa") else -1.0
	check(at >= dawn + 60.0 - _step(), "builders resting at night finish after the night (%.0f s, dawn in %.0f s)" % [at, dawn])
	game.new_game()


func test_a_storehouse_filling_up_is_announced() -> void:
	var game := _farm()
	game.villa_stage = 2
	game.helpers["farmhand"] = 1
	for i in game.plots.size():
		var p: Dictionary = game.plots[i]
		if p["unlocked"] and p["zone"] == "home":
			p["crop"] = "lavender"
			p["growth"] = game.time_to_ready(p)
	game.add_item("bread", game.holding_capacity() - 8, true)
	var plan := _plan(game)
	var at: float = float(plan["full"]["seconds"]) if plan.has("full") else -1.0
	check(at > 0.0 and at <= 600.0, "the farmhand filling the storehouse and cart is announced (%.0f s)" % at)
	check(plan.has("full") and plan["full"]["text"] == tr("The storehouse and the cart are full: send the cart to market"), "and says to send the cart")
	game.add_item("bread", 8, true)
	check(not _plan(game).has("full"), "a farm left already full is not announced again")
	game.new_game()
	game.day_time = 8.0
	check(not _plan(game).has("full"), "nor is a farm with nothing filling it")
	game.new_game()


func test_a_slowly_filling_storehouse_is_reckoned_from_its_pace() -> void:
	var game := _farm()
	game.villa_stage = 2
	game.helpers["farmhand"] = 1
	game.levels["storage"] = 4
	for i in game.plots.size():
		var p: Dictionary = game.plots[i]
		if p["unlocked"] and p["zone"] == "home":
			p["crop"] = "lavender"
			p["growth"] = game.time_to_ready(p)
	var notices: GDScript = load(NOTICES) if ResourceLoader.exists(NOTICES) else null
	if notices == null:
		check(false, "the notices can be planned")
		return
	var most := float(Data.get_value("offline.max_hours", 12)) * 3600.0
	var at: float = notices.fills_in(game, most)
	# The same farm played out step by step, as the catch-up plays it.
	game.quiet = true
	var played := 0.0
	while played < most and not notices.full(game):
		game.advance(float(Data.get_value("offline.step_seconds", 5)))
		played += float(Data.get_value("offline.step_seconds", 5))
	game.quiet = false
	check(played > float(Data.get_value("notifications.sample_seconds", 1200)), "this farm takes longer to fill than the part played out (%.0f s)" % played)
	check(absf(at - played) <= played * 0.25, "and the reckoning lands near when it fills (%.0f s reckoned, %.0f s played)" % [at, played])
	game.new_game()


func test_nothing_is_planned_past_the_offline_limit() -> void:
	var game := _farm()
	var most := float(Data.get_value("offline.max_hours", 12)) * 3600.0
	game.cart = {"away": true, "time_left": most + 100.0, "items": 10, "value": 120, "load": ["lavender"]}
	game.villa_build = {"active": true, "time_left": most}
	game.projects["channels"] = 90.0
	var plan := _plan(game)
	check(not plan.has("cart") and not plan.has("build_villa"), "what happens after the farm stops counting time away is not announced")
	check(plan.has("build_channels"), "while what happens before it is")
	check(plan.values().all(func(n): return float(n["seconds"]) <= most), "nothing is planned past %d hours" % int(most / 3600.0))
	game.new_game()


func test_planning_leaves_the_farm_as_it_was() -> void:
	var game := _farm()
	game.villa_stage = 2
	game.helpers["farmhand"] = 1
	game.projects["storage"] = 120.0
	game.villa_build = {"active": true, "time_left": 300.0}
	game.cart = {"away": true, "time_left": 15.0, "items": 10, "value": 120, "load": ["lavender"]}
	for i in game.plots.size():
		if game.plots[i]["unlocked"]:
			game.plots[i]["crop"] = "lavender"
	var before := JSON.stringify(game.to_dict())
	var coins: int = game.coins
	_plan(game)
	check(JSON.stringify(game.to_dict()) == before and game.coins == coins, "working out the notices plays a copy of the farm, never the farm itself")
	game.new_game()


func test_each_kind_can_be_turned_off() -> void:
	var game := _farm()
	game.cart = {"away": true, "time_left": 15.0, "items": 10, "value": 120, "load": ["lavender"]}
	game.projects["storage"] = 120.0
	var settings: Node = root.get_node("Settings")
	check("notify_cart" in settings.PLAY and "notify_full" in settings.PLAY and "notify_builders" in settings.PLAY, "the choices are kept with the other settings")
	settings.notify_cart = false
	check(not _plan(game).has("cart") and _plan(game).has("build_storage"), "turning off the cart's notice leaves the builders'")
	settings.notify_cart = true
	settings.notify_builders = false
	check(_plan(game).has("cart") and not _plan(game).has("build_storage"), "and the other way round")
	settings.notify_builders = true
	settings.offline_progress = false
	check(_plan(game).is_empty(), "with progress while closed off the farm waits, so nothing is announced")
	settings.offline_progress = true
	game.new_game()


func test_the_phone_link_does_nothing_without_the_plugin() -> void:
	var phone := _phone()
	check(phone != null, "PhoneServices is an autoload")
	if phone == null:
		return
	check(not Engine.has_singleton("SlowSundayPhone") and not phone.available(), "there is no native plugin in this build")
	check(not phone.notifications_allowed(), "so notifications count as not allowed")
	phone.schedule("cart", 10.0, "The cart is home", "Back")
	phone.cancel_all()
	phone.open_notification_settings()
	phone.unlock_achievement("CgkI")
	phone.sign_in()
	phone.put_away()
	phone.came_back()
	check(not phone._away, "and every call does nothing at all")


func test_putting_the_game_away_schedules_what_the_farm_will_need() -> void:
	var phone := _phone()
	if phone == null:
		check(false, "PhoneServices is an autoload")
		return
	var game := _farm()
	game.cart = {"away": true, "time_left": 15.0, "items": 10, "value": 120, "load": ["lavender"]}
	var settings: Node = root.get_node("Settings")
	var fake := FakePhone.new()
	phone._phone = fake
	fake.allowed = true
	settings.reminders = false
	phone._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	check(fake.calls.filter(func(c): return c[0] == "schedule").is_empty(), "nothing is sent before the player taps Allow, even on a phone that allows notifications from the start")
	phone._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	fake.calls.clear()
	settings.reminders = true
	phone._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(fake.calls.is_empty(), "a game that only loses the focus, under the notification shade or beside another app, plans nothing")
	phone._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	var scheduled: Array = fake.calls.filter(func(c): return c[0] == "schedule")
	check(not fake.calls.is_empty() and fake.calls[0] == ["cancel_all"], "putting the game away first clears what was planned before")
	check(scheduled.size() == 1 and scheduled[0][1] == "cart" and scheduled[0][2] == 15 and scheduled[0][3] == tr("The cart is home"), "then plans the cart's return: %s" % str(scheduled))
	phone._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	check(fake.calls.filter(func(c): return c[0] == "schedule").size() == 1, "pausing twice plans only once")
	fake.calls.clear()
	phone._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	check(fake.calls == [["cancel_all"]], "coming back clears them")
	check(phone.notifications_allowed(), "the phone says whether notifications are allowed")
	settings.reminders = false
	phone.allow()
	check(fake.calls.has(["request_notifications"]) and settings.reminders and settings.cfg.get_value("phone", "reminders", false), "Allow turns the notices on, asks the phone, and the choice is kept")
	settings.reminders = false
	settings.cfg.erase_section("phone")
	phone._phone = null
	game.new_game()


func test_an_iphone_has_no_notifications_tab_until_it_has_a_plugin_for_them() -> void:
	var phone := _phone()
	var was := [Windowing.phone, Windowing.phone_preview]
	Windowing.phone = true
	Windowing.phone_preview = true
	check(phone.can_remind() == (phone.available() or not OS.has_feature("mobile")), "a phone can be sent notifications only through the plugin, which an iPhone lacks")
	var panel: Control = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.open()
	await process_frame
	check(_buttons(panel).any(func(b: Button) -> bool: return b.text == tr("Notifications")) == phone.can_remind(), "the tab shows only where notifications can be sent")
	panel.free()
	Windowing.phone = was[0]
	Windowing.phone_preview = was[1]


func test_every_achievement_has_a_google_play_entry() -> void:
	var ids: Array = Data.get_value("achievements", []).map(func(a): return String(a["id"]))
	var play: Dictionary = Data.get_value("play_games.achievements", {})
	check(not play.is_empty() and ids.all(func(id): return play.has(id)), "every achievement has an entry for its Google Play id in balance.json")
	check(play.keys().all(func(id): return id in ids), "and nothing else does")
	check(play.values().all(func(v): return v is String), "each id is text, blank until the Play Console gives it")


func test_an_achievement_reaches_google_play_once_it_has_an_id() -> void:
	var phone := _phone()
	var data: Node = root.get_node("Data")
	var play: Dictionary = data.data.get("play_games", {}).get("achievements", {})
	if phone == null or not play.has("first_harvest") or not Awards.has_method("send_to_play_games"):
		check(false, "Awards sends achievements to Google Play through PhoneServices")
		return
	var fake := FakePhone.new()
	phone._phone = fake
	var was: String = play["first_harvest"]
	play["first_harvest"] = ""
	data._found = {}
	Awards.send_to_play_games("first_harvest")
	check(fake.calls.is_empty(), "an achievement without a Google Play id yet is skipped")
	play["first_harvest"] = "CgkIexample"
	data._found = {}
	Awards.send_to_play_games("first_harvest")
	check(fake.calls == [["unlock_achievement", "CgkIexample"]], "one with an id is unlocked by that id")
	play["first_harvest"] = was
	data._found = {}
	phone._phone = null


func test_phones_get_a_notifications_tab() -> void:
	var settings: Node = root.get_node("Settings")
	var was := [Windowing.phone, Windowing.phone_preview]
	Windowing.phone = false
	var panel: Control = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.open()
	await process_frame
	check(not _buttons(panel).any(func(b: Button) -> bool: return b.text == tr("Notifications")), "a computer has no notifications tab")
	panel.free()
	Windowing.phone = true
	Windowing.phone_preview = true
	panel = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.tab = "Notifications"
	panel.open()
	await process_frame
	check(_buttons(panel).any(func(b: Button) -> bool: return b.text == tr("Notifications")), "a phone has one")
	var toggle := _setting(panel, "The cart is home")
	check(toggle != null and toggle.text == tr("On"), "with a switch for the cart's return")
	check(_setting(panel, "The storehouse is full") != null and _setting(panel, "The builders have finished") != null, "and for the storehouse and the builders")
	if toggle:
		toggle.pressed.emit()
		check(not settings.notify_cart, "which turns its notices off")
		settings.notify_cart = true
	check(_buttons(panel).any(func(b: Button) -> bool: return b.text == tr("Allow")), "a phone not allowing notifications offers to ask for them")
	# A pressed button rebuilds its window a frame later, which must happen before the window is freed.
	await process_frame
	panel.free()
	Windowing.phone = was[0]
	Windowing.phone_preview = was[1]


func test_phones_link_the_privacy_policy_in_the_settings() -> void:
	var was := [Windowing.phone, Windowing.phone_preview]
	Windowing.phone = false
	Windowing.phone_preview = false
	var panel: Control = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.tab = "Gameplay"
	panel.open()
	await process_frame
	check(_setting(panel, "Privacy policy") == null, "a computer's settings look as they always have, with no privacy policy")
	panel.free()
	Windowing.phone = true
	Windowing.phone_preview = true
	panel = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.tab = "Gameplay"
	panel.open()
	await process_frame
	var opened := []
	panel.open_url = func(url: String) -> void: opened.append(url)
	var link := _setting(panel, "Privacy policy")
	check(link != null and link.text == tr("Open"), "a phone's gameplay settings link the privacy policy, as the stores ask")
	if link:
		link.pressed.emit()
	check(opened == ["https://evan260.github.io/slowsunday/privacy.html"], "which opens the policy's page (%s)" % [opened])
	await process_frame
	panel.free()
	Windowing.phone = was[0]
	Windowing.phone_preview = was[1]


func _buttons(panel: Control) -> Array:
	return panel.find_children("*", "Button", true, false)


## The button beside a setting's label.
func _setting(panel: Control, text: String) -> Button:
	for l in panel.find_children("*", "Label", true, false):
		if l.text == tr(text):
			for b in l.get_parent().get_children():
				if b is Button:
					return b
	return null


class FakePhone:
	var calls: Array = []
	var allowed := false

	func schedule(id: String, seconds: int, title: String, text: String) -> void:
		calls.append(["schedule", id, seconds, title, text])

	func cancel_all() -> void:
		calls.append(["cancel_all"])

	func notifications_allowed() -> bool:
		return allowed

	func request_notifications() -> void:
		calls.append(["request_notifications"])

	func open_notification_settings() -> void:
		calls.append(["open_notification_settings"])

	func unlock_achievement(id: String) -> void:
		calls.append(["unlock_achievement", id])

	func sign_in() -> void:
		calls.append(["sign_in"])


## The choice of pets opens a new farm, so on a phone it must show whole, with nothing to find by scrolling.
func test_the_choice_of_pets_fits_a_phone_without_scrolling() -> void:
	var was := [Windowing.phone, Windowing.phone_preview, Windowing.safe_top_left, Windowing.safe_bottom_right]
	var locale := TranslationServer.get_locale()
	Windowing.phone = true
	Windowing.phone_preview = true
	# A Pixel 9a held sideways at four screen pixels to the interface pixel, with its camera on the left.
	Windowing.safe_top_left = Vector2(34, 10)
	Windowing.safe_bottom_right = Vector2(10, 10)
	root.get_node("Game").new_game()
	for loc in ["en", "de", "ru", "ja"]:
		TranslationServer.set_locale(loc)
		var screen := Control.new()
		screen.size = Vector2(606, 270)
		screen.theme = UiTheme.build()
		root.add_child(screen)
		var panel: Control = load("res://scripts/ui/companions_panel.gd").new()
		screen.add_child(panel)
		panel.open()
		for i in 3:
			await process_frame
		var scroll: ScrollContainer = panel._scroll
		check(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and Rect2(Vector2.ZERO, screen.size).encloses(panel.get_rect()),
			"in %s every pet and button shows at once (%s in %s)" % [loc, panel.get_rect(), screen.size])
		screen.free()
	TranslationServer.set_locale(locale)
	Windowing.phone = was[0]
	Windowing.phone_preview = was[1]
	Windowing.safe_top_left = was[2]
	Windowing.safe_bottom_right = was[3]
