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
