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

	# The estate: land deeds open zones, and buildings go from ruin to working and refine goods.
	game.new_game()
	game.coins = 5000
	var grove_plot := -1
	for i in game.plots.size():
		if game.plots[i]["zone"] == "grove":
			grove_plot = i
			break
	_check(not game.plots[grove_plot]["unlocked"], "grove plots start locked")
	_check(game.buy_zone("grove") and game.plots[grove_plot]["unlocked"], "buying the grove deed opens its plots")
	_check(game.try_plant(grove_plot) and game.plots[grove_plot]["crop"] == "olives", "grove plots grow olive trees")
	_check(not game.do_building_action("mill"), "a building in land you do not own cannot be bought")
	game.buy_zone("yard")
	_check(game.do_building_action("drying_shed") and game.buildings["drying_shed"]["state"] == "owned", "buying a ruin")
	_check(game.do_building_action("drying_shed") and game.buildings["drying_shed"]["state"] == "repairing", "repairing a ruin takes time")
	game.advance(31.0)
	_check(game.buildings["drying_shed"]["state"] == "working", "repairs finish on their own")
	game.storage = {"lavender": 4, "wheat": 3}
	_check("lavender" in game.reserved_items(), "a working building's ingredients are reserved")
	game.send_cart()
	_check(int(game.storage.get("lavender", 0)) == 4 and not game.storage.has("wheat"), "the cart leaves reserved ingredients and sells the rest")
	game.cart = game._empty_cart()
	game.simulate_offline(60.0)
	_check(int(game.storage.get("dried_lavender", 0)) == 2 and not game.storage.has("lavender"), "the drying shed turns lavender into dried lavender, even offline")
	_check(game.do_building_action("drying_shed") and int(game.buildings["drying_shed"]["level"]) == 1, "upgrading a working building")

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
	game.zones_owned["yard"] = true
	game.buildings["mill"]["state"] = "working"
	data = JSON.parse_string(JSON.stringify(game.to_dict()))
	game.new_game()
	game.from_dict(data)
	_check(game.coins == coins and game.stored_total() == stored and game.villa_stage == stage and is_equal_approx(game.day_time, hour), "save data round-trips")
	_check(game.zone_owned("yard") and game.buildings["mill"]["state"] == "working", "zones and buildings round-trip")

	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
	else:
		print("ok: " + what)
