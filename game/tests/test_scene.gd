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
	game.advance(60.0)
	await process_frame
	_check(main._plot_at(empty.position + Vector2(14, -20)) == empty, "a grown plant responds where its leaves are")
	main._click_plot(i)
	_check(game.stored_total() == 1, "clicking a blooming plot harvests it")
	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
