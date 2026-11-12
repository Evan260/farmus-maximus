extends "res://tests/test_case.gd"
## Opening and closing every window, the market town and the farmhouse again and again leaves no objects behind, and so
## does turning the journal's pages.

const WINDOWS := ["journal", "helpers", "store", "settings", "upgrades", "companions"]
const ROUNDS := 6
## Travellers, wild animals and builders come and go on their own, a few dozen objects at a time, while a window left
## behind would leave hundreds every round.
const SPARE := 60


func test_open_and_close_leave_nothing_behind() -> void:
	var settings: Node = root.get_node("Settings")
	var motion: bool = settings.reduced_motion
	# Without motion the town and the farmhouse open and close at once rather than dissolving.
	settings.reduced_motion = true
	var main: Node2D = await _estate()
	# The first round loads every window's pictures and fills every cache, so counting starts after it.
	await _round(main)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for k in ROUNDS:
		await _round(main)
	var grown := Performance.get_monitor(Performance.OBJECT_COUNT) - objects
	check(grown < SPARE, "opening and closing every window %d more times leaves no objects behind (%d more)" % [ROUNDS, grown])
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) <= orphans, "no nodes are left out of the tree")
	settings.reduced_motion = motion
	main.queue_free()
	await process_frame


func test_turning_pages_leaves_nothing_behind() -> void:
	var main: Node2D = await _estate()
	main.hud.open_window("journal")
	var journal: Node = main.hud._journal
	await _settle()
	# The first two rounds load every section's pictures, so counting starts after them.
	for k in 2:
		await _turns(journal)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for k in 2:
		await _turns(journal)
	check(journal.find_children("*", "SubViewport", true, false).is_empty(), "every page's picture is freed once its leaf lands or is cut short")
	check(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) <= nodes, "turning more pages leaves no extra nodes (%d before, %d after)" % [nodes, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) <= orphans, "and no nodes out of the tree")
	check(Performance.get_monitor(Performance.OBJECT_COUNT) - objects < SPARE, "and no objects behind (%d more)" % (Performance.get_monitor(Performance.OBJECT_COUNT) - objects))
	main.hud.close_windows()
	main.queue_free()
	await process_frame


## Three sections turned to and back, then two turns cut short by the journal laying its pages out again, as a new entry
## does, one of them before its new page is pictured.
func _turns(journal: Node) -> void:
	for to in ["Goods", "Buildings", "Crops"]:
		journal._turn_to(to)
		await _landed(journal)
	for wait in [0, 3]:
		journal._turn_to("Goods" if journal.section == "Crops" else "Crops")
		for i in wait:
			await process_frame
		journal._signature = ""
		journal.refresh()
		await _landed(journal)
		check(not journal._turning, "a journal whose pages are laid out again mid-turn can turn again")


func _landed(journal: Node) -> void:
	while journal._turning:
		await process_frame
	await _settle()


## A fresh estate with the title closed, as a player sees it once a farm is loaded.
func _estate() -> Node2D:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	game.day_time = 10.0
	game.villa_stage = 3
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	if main.hud.title_open():
		main.hud._title.go_back()
		main.hud._title.queue_free()
		main.hud._title = null
	return main


func _round(main: Node2D) -> void:
	for w in WINDOWS:
		main.hud.open_window(w)
		await _settle()
		check(main.hud.close_windows(), "the %s window opens" % w)
		await _settle()
	for id in ["villa", "mill", "cellar"]:
		main.hud.show_building(id)
		await _settle()
		main.hud.close_windows()
		await _settle()
	main.go_to_town()
	await _settle()
	check(main.market.visible, "the market town opens")
	main.market.leave()
	await _settle()
	main.go_inside()
	await _settle()
	check(main.interior.visible, "the farmhouse opens")
	main.interior.leave()
	await _settle()


## A few frames, so closed windows finish fading and freed nodes are gone.
func _settle() -> void:
	for i in 4:
		await process_frame
