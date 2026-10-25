extends SceneTree
## Headless checks of the farm rules: run with Godot --headless --script res://tests/test_simulation.gd

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.new_game()
	_check(game.coins == 20, "starts with 20 sestertii")
	_check(game.try_plant(0), "plants lavender in an unlocked plot")
	_check(not game.try_plant(5), "cannot plant in a locked plot")
	_check(game.plot_visual(0) == "stage0", "new planting shows as a cutting")
	game.advance(30.0)
	_check(not game.is_ready(0), "not ready after 30 seconds")
	game.advance(30.0)
	_check(game.is_ready(0), "ready after 60 seconds")
	_check(game.try_harvest(0), "harvests a ready plant")
	_check(game.stored_total() == 1, "harvest goes into the storeroom")
	_check(game.plot_visual(0) == "harvested", "plant shows as trimmed after harvest")
	_check(game.send_cart(), "sends the cart with goods")
	_check(game.stored_total() == 0, "cart empties the storeroom")
	var before: int = game.coins
	game.advance(31.0)
	_check(game.coins == before + 6, "cart returns with the sale price")

	# Offline: a farmhand keeps harvesting until the storeroom fills, then everything waits.
	game.new_game()
	game.coins = 10000
	for i in 4:
		game.try_plant(i)
	game.buy_upgrade("farmhand")
	var summary: Dictionary = game.simulate_offline(3600.0 * 5)
	_check(game.stored_total() == game.storage_capacity(), "offline harvesting stops at a full storeroom")
	_check(int(summary["harvested"]) == game.storage_capacity(), "summary counts offline harvests")
	_check(bool(summary["storage_full"]), "summary reports the full storeroom")

	# Saving round trip.
	var data: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))
	var coins: int = game.coins
	game.new_game()
	game.from_dict(data)
	_check(game.coins == coins and game.stored_total() == game.storage_capacity(), "save data round-trips")

	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
	else:
		print("ok: " + what)
