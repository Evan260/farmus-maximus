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

	# Wheat is an annual: harvesting empties the plot, and a farmhand replants it.
	game.new_game()
	game.coins = 1000
	game.selected_seed = "wheat"
	_check(game.try_plant(0) and game.plots[0]["crop"] == "wheat", "plants the selected seed")
	game.advance(45.0)
	_check(game.try_harvest(0), "harvests ripe wheat")
	_check(game.plots[0]["crop"] == "" and int(game.storage.get("wheat", 0)) == 2, "wheat leaves the plot empty and yields two sheaves")
	game.try_plant(0)
	game.buy_upgrade("farmhand")
	game.advance(45.0)
	game.advance(6.0)
	_check(game.plots[0]["crop"] == "wheat" and int(game.storage.get("wheat", 0)) == 4, "the farmhand harvests and replants wheat")

	# The villa takes time to build and finishes on its own, even offline.
	game.new_game()
	game.coins = 1000
	_check(game.upgrade_villa(), "pays for the villa upgrade")
	_check(game.villa_build["active"] and game.villa_stage == 1, "villa is under construction, not finished instantly")
	_check(game.villa_next_cost() == -1, "cannot pay twice while building")
	game.simulate_offline(50.0)
	_check(not game.villa_build["active"] and game.villa_stage == 2, "construction finishes while the game is closed")

	# The day clock moves and wraps around midnight.
	game.day_time = 23.9
	game.advance(60.0)
	_check(game.day_time < 23.9, "the day wraps past midnight")

	# Saving round trip.
	var data: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))
	var coins: int = game.coins
	var stored: int = game.stored_total()
	var stage: int = game.villa_stage
	var hour: float = game.day_time
	game.new_game()
	game.from_dict(data)
	_check(game.coins == coins and game.stored_total() == stored and game.villa_stage == stage and is_equal_approx(game.day_time, hour), "save data round-trips")

	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
	else:
		print("ok: " + what)
