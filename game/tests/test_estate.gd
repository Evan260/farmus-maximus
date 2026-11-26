extends "res://tests/test_case.gd"
## The estate builds and resizes without the engine writing anything to the log; run_tests.gd fails a test that does.


func test_building_and_resizing_write_no_warnings() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	var windowing: Node = root.get_node("Windowing")
	windowing.view_changed.emit()
	await process_frame
	var view: Vector2 = main.get_viewport().get_visible_rect().size
	var want := Vector2i((view / windowing.scale).ceil()) + Vector2i(1, 0)
	check(main._viewport.size == want, "the estate's picture is one pixel wider than the window and fills its height (%s, want %s)" % [main._viewport.size, want])
	main.queue_free()
	await process_frame


func test_a_phone_shows_every_bed_of_a_zone_and_the_parked_cart_across_its_screen() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var windowing: Node = root.get_node("Windowing")
	var was: bool = windowing.phone
	windowing.phone = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	windowing.phone = was
	var home: Vector2 = main._beds_span("home")
	# The cart's body is its first 38 pixels; its shafts and the donkey reach on past it.
	var reach: float = main.CART_HOME_X + 38.0 - home.x
	check(reach <= windowing.PHONE_WIDTH, "the home farm's beds and the parked cart fit across a phone (%d)" % int(reach))
	for z in game.zones():
		var beds: Vector2 = main._beds_span(z["id"])
		check(beds.y - beds.x <= windowing.PHONE_WIDTH, "and so do the beds of the %s (%d)" % [z["id"], int(beds.y - beds.x)])
	var rows := {}
	for v in main.plot_views:
		if game.plots[v.index]["zone"] == "home":
			rows[roundi(v.position.y / 11.0)] = true
	check(rows.size() == 3, "the home farm's beds stand in three rows on a phone (%d)" % rows.size())
	main.queue_free()
	await process_frame


func test_screen_changes_write_no_errors_when_headless() -> void:
	var settings: Node = root.get_node("Settings")
	var motion: bool = settings.reduced_motion
	settings.reduced_motion = false
	var changed := [false]
	Dissolve.play(root, func(): changed[0] = true)
	check(changed[0], "the screen still changes when there is no picture of it to dissolve")
	settings.reduced_motion = motion
	await process_frame


func test_a_card_waits_behind_the_title() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	if main.hud.title_open():
		main.hud._title._continue()
		await create_timer(0.7).timeout
	main.hud._show_away({"seconds": 7200.0, "harvested": 3})
	var card: Control = main.hud._away
	main.hud.back_to_title()
	await process_frame
	check(not card.is_visible_in_tree(), "the summary of time away does not cover the title")
	main.hud._title._continue()
	await create_timer(0.7).timeout
	check(is_instance_valid(main.hud._away) and main.hud._away.is_visible_in_tree(), "and shows again once the farm is back")
	main.queue_free()
	await process_frame


func test_the_journal_turns_to_the_last_section_asked_for() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	main.hud.open_window("journal")
	var journal: Node = main.hud._journal
	await process_frame
	journal._turn_to("Buildings")
	journal._turn_to("Goods")
	journal._turn_to("Buildings")
	await create_timer(2.0).timeout
	check(journal.section == "Buildings", "a section chosen again while its page turns cancels the one asked for before (%s)" % journal.section)
	journal._turn_to("Crops")
	journal._turn_to("Goods")
	journal._signature = ""
	journal.refresh()
	await create_timer(0.2).timeout
	journal._turn_to("Animals")
	await create_timer(2.0).timeout
	check(journal.section == "Animals", "a turn cut short forgets the one waiting after it (%s)" % journal.section)
	main.hud.close_windows()
	main.queue_free()
	await process_frame


func test_the_farm_list_does_not_cover_the_title_name() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	main.hud.back_to_title()
	var title: Control = main.hud._title
	title._open_farms()
	for i in 3:
		await process_frame
	var farms: Control = title._farms
	var crossed := title.find_children("*", "Label", true, false).filter(func(l: Label) -> bool:
		return l.is_visible_in_tree() and l.name != "Version" and not farms.is_ancestor_of(l) and l.get_global_rect().intersects(farms.get_global_rect()))
	check(crossed.is_empty(), "nothing on the title shows through the farm list (%s)" % ", ".join(crossed.map(func(l): return l.text)))
	title._farms.close()
	await process_frame
	main.queue_free()
	await process_frame


func test_a_reload_from_the_title_comes_back_to_the_title() -> void:
	var game: Node = root.get_node("Game")
	var saves: Node = root.get_node("Saves")
	saves.enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	var done: bool = saves.title_done
	saves.title_done = true
	main.hud.back_to_title()
	check(not saves.title_done, "a language changed or the farm deleted from the title rebuilds the scene onto the title again")
	main.hud._title.queue_free()
	main.hud._title = null
	saves.title_done = done
	main.queue_free()
	await process_frame


func test_hiring_a_helper_is_told_in_the_players_language() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	if main.hud.title_open():
		main.hud._title._continue()
		await create_timer(0.7).timeout
	var locale := TranslationServer.get_locale()
	TranslationServer.set_locale("ru")
	game.villa_stage = 2
	game.coins = 100000
	game.hire_helper("farmhand")
	var told: Array = [main.hud._toast.text] + main.hud._toast_queue
	check(told.any(func(t: String) -> bool: return "Гай" in t), "a new helper is named in the player's language (%s)" % ", ".join(told))
	main.hud._toast_queue.clear()
	main.hud._toast.text = ""
	game.hire_helper("farmhand")
	told = [main.hud._toast.text] + main.hud._toast_queue
	var joined := tr("%s has joined the household") % tr("Gaius")
	check(not joined in told and told.any(func(t: String) -> bool: return "Гай" in t and "2" in t),
		"training a helper tells of their new level, not of them joining again (%s)" % ", ".join(told))
	TranslationServer.set_locale(locale)
	game.live_helpers = {}
	main.queue_free()
	await process_frame


func test_news_waits_while_a_window_is_open_and_answers_keep_off_its_buttons() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	if main.hud.title_open():
		main.hud._title._continue()
		await create_timer(0.7).timeout
	var hud: CanvasLayer = main.hud
	if hud._toast_tween:
		hud._toast_tween.kill()
	hud._toast_queue.clear()
	hud._queued_news.clear()
	hud._toast.text = ""
	hud.open_window("journal")
	await process_frame
	hud.news("Fresh news")
	await process_frame
	check(hud._toast.text == "" and "Fresh news" in hud._toast_queue, "news waits while a window is open")
	hud.toast("An answer")
	await process_frame
	var covered: Array = hud._journal.find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
		return b.is_visible_in_tree() and b.get_global_rect().intersects(hud._toast.get_global_rect()))
	check(hud._toast.text == "An answer" and covered.is_empty(), "an answer to the player shows at once, clear of the window's buttons (%d covered)" % covered.size())
	hud._toast_tween.kill()
	hud.close_windows()
	await process_frame
	await process_frame
	check(hud._toast.text == "Fresh news", "and the news shows once the window has closed (%s)" % hud._toast.text)
	var locale := TranslationServer.get_locale()
	for loc in ["en", "de", "ru"]:
		TranslationServer.set_locale(loc)
		game.coins = 999999999
		game.aureus = 999999999
		await process_frame
		await process_frame
		check(not hud._stats_panel.get_rect().intersects(hud._zone_bar.get_rect()), "in %s the farm's panel keeps clear of the zone bar at the largest purse" % loc)
	TranslationServer.set_locale(locale)
	main.queue_free()
	await process_frame


func test_market_places_cut_off_by_the_window_get_buttons() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	var market: CanvasLayer = main.market
	market.visible = true
	for size in [Vector2(1280, 1024), Vector2(1920, 1080)]:
		market._fit(size)
		market._process(0.0)
		var shown := Rect2(-market._scene.position / market._scene.scale.x, size / market._scene.scale.x)
		var cut: bool = market.SPOTS.any(func(s) -> bool: return not shown.encloses(Rect2(s["rect"])))
		check(market._pad_bar.visible == cut, "on a %s window the row of places shows only when the town hides one (%s)" % [size, cut])
	market.visible = false
	market._fit()
	main.queue_free()
	await process_frame


func test_market_requests_name_the_townsfolk_in_the_players_language() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	var locale := TranslationServer.get_locale()
	TranslationServer.set_locale("ru")
	game.market.orders = [{"who": "Septimus", "role": "baker", "item": "lavender", "amount": 2, "coins": 10, "aureus": 0, "seed": "", "text": "2"}]
	var market: CanvasLayer = main.market
	Ui.clear(market._list)
	market._build_orders()
	var said: Array = market._list.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	TranslationServer.set_locale(locale)
	check(said.any(func(t: String) -> bool: return "Септимий" in t), "a request names who asks in the player's language (%s)" % " | ".join(said))
	main.queue_free()
	await process_frame
