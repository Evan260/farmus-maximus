extends SceneTree
## Plays the estate like a keen player who checks in every few seconds, and prints when each milestone arrives.
## Run: Godot --headless --path game --script res://tests/pacing_bot.gd -- --hours=8

var game: Node
var seen := {}
var t := 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.rng.seed = 1
	var hours := 6.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hours="):
			hours = float(arg.trim_prefix("--hours="))
	var step := 2.0
	while t < hours * 3600.0:
		_act()
		game.advance(step)
		t += step
		_milestones()
	print("storage ", game.storage, " cap ", game.storage_capacity(), " sellable ", game.sellable_goods(), " cart ", game.cart, " keep ", game.reserved_amounts())
	print("after %.1f hours: %d sestertii, villa stage %d, %d buildings working, %d helpers, journal %d%%" % [hours, game.coins, game.villa_stage, game.working_buildings(), game.helpers.size(), int(game.journal.share() * 100)])
	quit()


func _note(id: String, text: String) -> void:
	if not seen.has(id):
		seen[id] = true
		print("%8s  %s" % [_clock(t), text])


func _clock(s: float) -> String:
	return "%d:%02d:%02d" % [int(s) / 3600, (int(s) % 3600) / 60, int(s) % 60]


func _milestones() -> void:
	if int(game.stats.get("harvested", 0)) > 0:
		_note("harvest", "first harvest")
	if int(game.stats.get("earned", 0)) > 0:
		_note("sale", "first sale")
	for stage in range(2, 8):
		if game.villa_stage >= stage:
			_note("villa%d" % stage, "villa stage %d: %s" % [stage, game.villa_stages()[stage - 1]["name"]])
	for z in game.zones_owned:
		if game.zones_owned[z] and z != "home":
			_note("zone_" + z, "bought the %s" % z)
	for id in game.buildings:
		if game.buildings[id]["state"] == "working":
			_note("b_" + id, "%s working" % id)
	for h in game.helpers:
		_note("h_" + h, "hired the %s" % h)
	for key in game.storage:
		if game.item_quality(key) == 2:
			_note("excellent", "first excellent good (%s)" % key)


## A greedy but sensible player: harvest, plant, sell, then spend on whatever unlocks the most.
func _act() -> void:
	for i in game.plots.size():
		if game.is_ready(i):
			game.try_harvest(i)
		elif game.plots[i]["unlocked"] and game.plots[i]["crop"] == "":
			var zone := String(game.plots[i]["zone"])
			game.selected_seed = "wheat" if zone == "home" and i % 3 == 2 else "lavender"
			if not zone in game.crop_zones(game.selected_seed):
				for crop in root.get_node("Balance").get_value("crops", {}):
					if game.crop_zones(crop)[0] == zone and game.crop_unlocked(crop):
						game.selected_seed = crop
						break
			game.try_plant(i)
	for id in game.buildings:
		game.load_building(id)
		if game.building_kind(id) == "cellar":
			game.draw_wine(id)
	# Until the trader is hired, the player rides to market and sells at the stalls whenever the storehouse fills up.
	if not game.helpers.has("trader") and game.stored_total() >= game.storage_capacity() - 2:
		var goods: Dictionary = game.sellable_goods()
		for key in goods:
			game.market.sell(key, int(goods[key]))
	# Spending, most important first; materials are bought as needed.
	var reserve := 0
	var price: Dictionary = game.villa_next_price()
	if not price.is_empty():
		_buy_materials(price)
		if game.upgrade_villa():
			return
		reserve = int(price.get("coins", 0)) / 2
	for z in game.zones():
		var id := String(z["id"])
		if not game.zone_owned(id) and game.zone_block(id) == "" and game.coins - int(z.get("deed", 0)) >= reserve / 2:
			game.buy_zone(id)
	for id in game.buildings:
		var act: Dictionary = game.building_action(id)
		if act.is_empty() or game.building_block(id) != "":
			continue
		_buy_materials(act["cost"])
		if game.coins - int(act["cost"].get("coins", 0)) >= reserve / 2:
			game.do_building_action(id)
	for h in root.get_node("Balance").get_value("helpers", {}):
		if game.helper_block(h) == "" and game.helper_cost(h) >= 0 and game.coins - game.helper_cost(h) >= reserve:
			game.hire_helper(h)
	for u in ["storage", "cart_capacity", "cart_speed", "channels"]:
		if game.upgrade_cost(u) >= 0 and game.coins - game.upgrade_cost(u) >= reserve:
			game.buy_upgrade(u)
	for i in game.plots.size():
		if not game.plots[i]["unlocked"] and game.plots[i]["zone"] == "home" and game.coins - game.unlock_cost() >= reserve:
			game.try_unlock(i)
	for entry in game.market.catalog():
		if entry.has("unlock_crop") and game.market.catalog_block(entry) == "" and game.coins - int(entry.get("price", 0)) >= reserve:
			game.market.buy(String(entry["id"]))
	if game.buildings["barn"]["state"] == "working":
		for kind in ["chicken", "goat"]:
			if game.coins > reserve + 200:
				game.market.buy(kind)


func _buy_materials(cost: Dictionary) -> void:
	for m in ["stone", "timber", "tiles"]:
		var short: int = int(cost.get(m, 0)) - game.count_item(m)
		if short > 0 and game.coins >= int(cost.get("coins", 0)) + short * 15:
			game.market.buy(m, short)
