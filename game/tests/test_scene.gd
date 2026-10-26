extends SceneTree
## Headless checks that the farm scene builds and every plot answers clicks in its own spot.

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.coins = 1000
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	_check(main.plot_views.size() == game.plots.size(), "one view per plot")
	await process_frame
	for v in main.plot_views:
		var hit: Node2D = main._plot_at(v.position + Vector2(14, -1))
		_check(hit == v, "plot %d is clicked at its own soil patch" % v.index)
	var empty: Node2D = main._view(0)
	_check(main._plot_at(empty.position + Vector2(14, -20)) != empty, "an empty plot does not respond above its soil")
	var i := 0
	main._click_plot(i)
	_check(game.plots[i]["crop"] == "lavender", "clicking an empty plot plants lavender")
	game.calendar.wet_left = 9999.0
	game.advance(60.0)
	await process_frame
	_check(main._plot_at(empty.position + Vector2(14, -20)) == empty, "a grown plant responds where its leaves are")
	main._click_plot(i)
	_check(game.stored_total() == 1, "clicking a blooming plot harvests it")
	game.add_item("stone", 3, true)
	game.add_item("tiles", 3, true)
	var top: Vector2 = main._villa_rect().position + Vector2(main._villa_rect().size.x / 2, 10)
	main._click(top)
	_check(main.hud._building.visible and main.hud._building.id == "villa", "clicking the farmhouse opens its panel")
	main.hud._building._action.pressed.emit()
	_check(game.villa_build["active"], "the farmhouse panel starts the restoration")
	for b in main.building_views:
		var r: Rect2 = b.world_rect()
		var point: Vector2 = r.position + Vector2(r.size.x / 2.0, 8)
		_check(main._plot_at(point) == null and main._building_at(point) == b, "a gamepad can pick the %s" % b.id)
	for s in main.signs:
		var r: Rect2 = s.world_rect()
		# The ground strip's top edge wanders between rows 229 and 235.
		_check(r.end.y > 236, "the %s sign stands in the ground" % s.zone_id)
	await _check_steady_size(main.hud._settings, func(w, t): w.tab = t; w.show_page(), ["Sound", "Display", "Play", "Keys"])
	var pages := ["Crops", "Goods", "Buildings", "Helpers", "Animals", "Finds", "Sightings", "Festivals", "Milestones", "Achievements",
		"item:olive_oil", "crop:lavender", "achievement:first_harvest"]
	await _check_steady_size(main.hud._journal, _show_journal_page, pages)
	var journal: Control = main.hud._journal
	journal.open()
	_show_journal_page(journal, "Goods")
	await process_frame
	await process_frame
	var lists: Array = journal.find_children("*", "ScrollContainer", true, false)
	var grid: ScrollContainer = lists[lists.size() - 1]
	grid.scroll_vertical = 40
	_show_journal_page(journal, "item:olive_oil")
	await process_frame
	await process_frame
	lists = journal.find_children("*", "ScrollContainer", true, false)
	_check(lists[lists.size() - 1].scroll_vertical == 40, "choosing a journal entry keeps the list where it was")
	journal.close()
	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


func _show_journal_page(journal: Control, page: String) -> void:
	if ":" in page:
		journal.selected = page
		journal.refresh()
	else:
		journal.section = page
		journal.selected = ""
		journal.show_page()


## A window with tabs keeps one size whichever tab it shows.
func _check_steady_size(window: Control, show: Callable, tabs: Array) -> void:
	window.open()
	var sizes := {}
	for t in tabs:
		show.call(window, t)
		await process_frame
		await process_frame
		sizes[str(window.size)] = t
	_check(sizes.size() == 1, "the %s window keeps one size on every tab: %s" % [window.name, sizes])
	window.close()


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
