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
	main.queue_free()
	await process_frame
