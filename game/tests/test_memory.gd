extends "res://tests/test_case.gd"
## Opening and closing every window, the market town and the farmhouse again and again leaves no objects behind.

## The estate sizes its picture itself as the window is made, which the engine warns about.
const EXPECTS_ERRORS := true
const WINDOWS := ["journal", "helpers", "store", "settings", "upgrades", "companions"]
const ROUNDS := 6
## Travellers, wild animals and builders come and go on their own, a few dozen objects at a time, while a window left
## behind would leave hundreds every round.
const SPARE := 60


func test_open_and_close_leave_nothing_behind() -> void:
	var game: Node = root.get_node("Game")
	var settings: Node = root.get_node("Settings")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	game.day_time = 10.0
	game.villa_stage = 3
	var motion: bool = settings.reduced_motion
	# Without motion the town and the farmhouse open and close at once rather than dissolving.
	settings.reduced_motion = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	if main.hud.title_open():
		main.hud._title.go_back()
		main.hud._title.queue_free()
		main.hud._title = null
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
