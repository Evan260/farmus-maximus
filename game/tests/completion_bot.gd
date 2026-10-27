extends "res://tests/pacing_bot.gd"
## Plays on past the pacing bot's goals towards 100%: it also takes every building to its top level, buys every
## decoration and pets the dog now and then, and prints when each achievement unlocks, when the journal passes each
## quarter, and at the end what is still missing. Sightings that only happen on screen, such as the fox or a rainbow,
## cannot be seen here, so they are listed as missing and estimated separately.
## Run: Godot --headless --path game --script res://tests/completion_bot.gd -- --hours=40


var _last_day := -1


func _milestones() -> void:
	game.check_achievements()
	super()
	for a in game.journal.achievements:
		_note("ach_" + String(a), "achievement: %s" % a)
	for q in [25, 50, 75, 90, 100]:
		if game.journal.share() * 100.0 >= q:
			_note("journal%d" % q, "journal %d%% full" % q)
	var all_top := true
	for id in game.buildings:
		var levels: Array = game.building_info(id).get("levels", [])
		if game.buildings[id]["state"] != "working" or int(game.buildings[id]["level"]) < levels.size():
			all_top = false
	if all_top:
		_note("all_top", "every building at its top level")
	if game.decorations.size() >= root.get_node("Balance").get_value("decorations", {}).size():
		_note("all_decor", "every decoration bought")


func _act() -> void:
	# Sow something not yet grown wherever it will grow, before the usual planting fills the rest.
	var balance := root.get_node("Balance")
	for i in game.plots.size():
		var p: Dictionary = game.plots[i]
		if not p["unlocked"] or p["crop"] != "":
			continue
		for crop in balance.get_value("crops", {}):
			if game.crop_unlocked(crop) and not game.journal.has("crop:" + crop) and String(p["zone"]) in game.crop_zones(crop):
				game.selected_seed = crop
				game.try_plant(i)
				break
	super()
	if game.dog_timer <= 0.0:
		game.dog_dig()
	for i in range(game.market.orders.size() - 1, -1, -1):
		if game.market.can_deliver(i):
			game.market.deliver(i)
	# Once a game day the player rides the cart to town and sells what it carries.
	if game.calendar.day != _last_day:
		_last_day = game.calendar.day
		game.add_stat("market_visits", 1)
		game.market.pack_cart()
		for key in game.market.brought.keys():
			game.market.sell(key, int(game.market.brought[key]))
		game.market.unpack_cart()
		if game.buildings.has("lararium") and game.buildings["lararium"]["state"] == "working":
			for god in balance.get_value("blessings.gods", {}):
				if game.offer(god):
					break
	for id in game.buildings:
		_buy_materials(game.building_action(id).get("cost", {}))
		game.do_building_action(id)
	for id in root.get_node("Balance").get_value("decorations", {}):
		game.buy_decoration(id)
	for id in root.get_node("Balance").get_value("interior.furnishings", {}):
		if game.furnishing_block(id) == "" and game.coins >= int(game.furnishing_info(id).get("price", 0)):
			game.buy_furnishing(id)
	# A player stops to pet the dog every so often.
	if randf() < 0.002:
		game.add_stat("pets", 1)


func _report() -> void:
	var missing := []
	for a in root.get_node("Balance").get_value("achievements", []):
		if not game.journal.achievements.has(a["id"]):
			missing.append(a["id"])
	var pages := []
	for e in game.journal.catalogue():
		if not game.journal.has(e["id"]):
			pages.append(e["id"])
	print("missing achievements: ", missing)
	print("missing decorations: ", root.get_node("Balance").get_value("decorations", {}).keys().filter(func(d): return not game.decorations.has(d)), " aurei ", game.aureus)
	print("missing journal pages: ", pages)
