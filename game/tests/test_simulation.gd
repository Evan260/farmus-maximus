extends "res://tests/test_case.gd"
## Headless checks of the estate rules, run by run_tests.gd.


func test_rules() -> void:
	var game: Node = root.get_node("Game")
	var data_file: Node = root.get_node("Data")
	var secs := func(path: String) -> float: return float(data_file.get_value(path, 0)) + 1.0
	game.new_game()
	game.day_time = 8.0
	game.rng.seed = 7
	_check(game.coins == 20, "starts with 20 sestertii")
	_check(game.try_plant(0), "plants lavender in an unlocked plot")
	_check(not game.try_plant(5), "cannot plant in a locked plot")
	_check(game.plot_visual(0) == "stage0", "new planting shows as a cutting")
	game.calendar.wet_left = 9999.0
	game.advance(10.0)
	_check(not game.is_ready(0), "the farm's first plant is not ready after 10 seconds")
	game.advance(3.0)
	_check(game.is_ready(0), "the farm's first plant blooms after about 12 seconds")
	_check(game.try_plant(1) and not game.plots[1].get("first", false), "only the farm's very first plant grows quickly")
	game.advance(30.0)
	_check(not game.is_ready(1), "a later plant is not ready after 30 seconds")
	game.advance(40.0)
	_check(game.is_ready(1), "a later plant is ready after about a minute in watered spring soil")
	game.dig_up(1)
	game.coins += 3
	_check(game.try_harvest(0), "harvests a ready plant")
	_check(game.stored_total() == 1 and game.count_item("lavender") == 1, "harvest goes into the storehouse")
	_check(game.plot_visual(0) == "harvested", "plant shows as trimmed after harvest")
	var key: String = game.storage.keys()[0]
	var expected: int = game.market.cart_price(key)
	_check(game.send_cart(), "sends the cart with goods")
	_check(game.stored_total() == 0, "cart empties the storehouse")
	var before: int = game.coins
	game.advance(31.0)
	_check(game.coins == before + expected, "cart returns with the cart's price")
	_check(game.market.cart_price("lavender") < game.market.price("lavender"), "the cart sells for less than the stalls")
	game.add_item("bread", 3, true)
	game.add_item("lavender", 2, true)
	game.set_for_sale("bread", false)
	game.send_cart()
	_check(game.count_item("bread") == 3 and game.count_item("lavender") == 0, "the trader leaves goods marked to keep in the storehouse")
	game.advance(60.0)

	# The trader sells only the extras: provisions for the villa's next stage and what open orders ask for stay home.
	game.new_game()
	game.day_time = 8.0
	game.villa_stage = 3
	game.levels["storage"] = 3
	game.helpers["trader"] = 1
	game.add_item("bread", 6, true)
	game.add_item("honey", 5, true)
	game.add_item("lavender", 2, true)
	game.market.orders = [{"who": "", "role": "", "item": "honey", "amount": 3, "coins": 10, "aureus": 0, "seed": "", "text": ""}]
	game.send_cart()
	_check(game.count_item("bread") == int(game.villa_next_price()["provisions"]), "the trader leaves the villa's provisions at home")
	_check(game.count_item("honey") == 3 and game.count_item("lavender") == 0, "the trader leaves what an order asks for and sells the rest")
	game.advance(60.0)
	game.market.orders = [{"who": "", "role": "", "item": "honey", "amount": 999, "coins": 10, "aureus": 0, "seed": "", "text": ""}]
	game.add_item("honey", game.storage_capacity(), true)
	_check(game.sellable_goods().get("honey", 0) >= game.count_item("honey") - game.storage_capacity() / 2, "what the player needs never holds back more than half the storehouse")

	# Qualities: each quality is its own storage key, recipes take the plainest first.
	game.new_game()
	game.day_time = 8.0
	game.add_item("lavender", 2)
	game.add_item("lavender@2", 1)
	_check(game.count_item("lavender") == 3, "counts every quality of a good together")
	_check(game.base_price("lavender@2") > game.base_price("lavender"), "excellent goods are worth more")
	_check(is_equal_approx(game.take_items({"lavender": 2}), 0.0) and game.storage.has("lavender@2"), "takes common goods before excellent ones")
	_check(game.journal.has("quality:lavender:2"), "the journal records a first excellent good")

	# Uncle Marcus's advice never goes back: a step once done stays done, as when a working building is being upgraded.
	game.new_game()
	_check(String(game.journal.tutorial_step().get("id", "")) == "plant", "the tutorial starts by asking to plant")
	game.stats["planted"] = 1
	_check(String(game.journal.tutorial_step().get("id", "")) != "plant", "planting moves the tutorial on")
	game.stats["planted"] = 0
	_check(String(game.journal.tutorial_step().get("id", "")) != "plant", "a step once done stays done")
	game.stats["guide_seen"] = 2
	_check(game.journal.tutorial_step().is_empty(), "a finished tutorial gives no more advice")

	# A farm left with no coins for a seed and nothing growing or to sell is given enough to start again.
	game.new_game()
	game.coins = 1
	game.advance(1.0)
	_check(game.coins == 1 + int(data_file.get_value("start.rescue_coins", 10)), "a stranded farm is sent coins to start again")
	game.coins = 3
	game.try_plant(0)
	game.coins = 0
	game.advance(1.0)
	_check(game.coins == 0, "a farm with something growing is left to earn its own way")
	game.dig_up(0)
	game.coins = int(data_file.get_value("crops.wheat.plant_cost", 2))
	game.advance(1.0)
	_check(game.coins > int(data_file.get_value("crops.lavender.plant_cost", 3)), "a farm that can only afford wheat is helped too, since a new player looks for lavender")
	game.coins = 0
	game.add_item("lavender", 1, true)
	game.advance(1.0)
	_check(game.coins == 0 and game.short_of_seed(), "a farm with goods to sell is told to sell them rather than given coins")

	# Growth depends on the season, water and manure.
	game.new_game()
	game.day_time = 8.0
	game.calendar.day = 12
	game.calendar.wet_left = 0.0
	game.calendar.weather = "sun"
	# Past the farm's quick first plant, which ignores the season and the water.
	game.stats["planted"] = 1
	game.try_plant(0)
	var winter_rate: float = game.growth_rate(0)
	game.calendar.day = 4
	_check(game.growth_rate(0) > winter_rate, "lavender grows faster in summer than winter")
	var dry: float = game.growth_rate(0)
	game.levels["channels"] = 1
	_check(game.growth_rate(0) > dry, "aqueduct channels water the home farm")
	game.add_item("manure", 1)
	game.plots[1]["unlocked"] = true
	game.try_plant(1)
	_check(game.plots[1]["manured"] and game.count_item("manure") == 0, "planting uses manure when there is some")

	# A farmhand harvests and replants once hired.
	game.new_game()
	game.day_time = 8.0
	game.coins = 10000
	game.selected_seed = "wheat"
	_check(not game.hire_helper("farmhand"), "the farmhand needs the restored farmhouse")
	game.villa_stage = 2
	_check(game.hire_helper("farmhand"), "hires the farmhand")
	game.try_plant(0)
	game.calendar.wet_left = 9999.0
	game.advance(40.0)
	game.advance(10.0)
	_check(game.plots[0]["crop"] == "wheat" and game.count_item("wheat") == 2, "the farmhand harvests and replants wheat")
	game.live_helpers["farmhand"] = true
	game.plots[1]["unlocked"] = true
	game.plots[1]["crop"] = "lavender"
	game.plots[1]["growth"] = 999.0
	game.advance(20.0)
	_check(game.is_ready(1), "a farmhand walking about on screen does not harvest by timer")
	_check(game.helper_harvest("farmhand", 1) and not game.is_ready(1), "the farmhand harvests the plant they reach")
	_check(not game.helper_harvest("beekeeper", 0), "a helper only picks their own crops")
	game.live_helpers = {}
	game.selected_seed = "lavender"
	for i in 4:
		game.plots[i]["crop"] = ""
		game.try_plant(i)
	game.storage = {}
	var summary: Dictionary = game.simulate_offline(3600.0 * 5)
	_check(game.stored_total() == game.holding_capacity(), "offline harvesting stops once the storehouse and the parked cart are full")
	_check(game.holding_capacity() == game.storage_capacity() + game.cart_capacity(), "a parked cart adds its space to the storehouse's")
	_check(game.in_storehouse() == game.storage_capacity() and game.on_cart() == game.cart_capacity(), "the storehouse fills first, the rest waits on the cart")
	game.send_cart()
	_check(game.holding_capacity() == game.storage_capacity(), "while the cart is on the road only the storehouse holds goods")
	_check(game.on_cart() == 0, "nothing waits on a cart that is away")
	_check(bool(summary["storage_full"]), "summary reports the full storehouse")
	game.new_game()
	game.day_time = 8.0
	game.coins = 0
	game.cart = {"away": true, "time_left": 10.0, "items": 4, "value": 400, "load": []}
	summary = game.simulate_offline(20.0)
	_check(game.coins == 400 and int(summary["earned"]) == 400, "a cart already on the road when the game closed pays its full value")
	game.new_game()
	game.day_time = 8.0
	game.coins = 0
	game.cart = {"away": true, "time_left": 10.0, "items": 4, "value": 400, "load": []}
	game.helpers["trader"] = 1
	game.add_item("lavender", 12, true)
	var sold_before: Dictionary = game.market.sold_today.duplicate()
	var trip_value := 0
	for n in 12:
		trip_value += game.market.cart_price("lavender")
		game.market.note_sold("lavender", 1)
	game.market.sold_today = sold_before
	var sent := []
	var note_trip := func(_items: int, value: int) -> void: sent.append(value)
	game.cart_left.connect(note_trip)
	game.simulate_offline(15.0 + game.cart_trip_seconds())
	game.cart_left.disconnect(note_trip)
	var share := float(data_file.get_value("offline.earnings_share", 0.25))
	_check(int(game.stats["cart_trips"]) == 1 and game.coins == 400 + int(trip_value * share), "time away keeps a share of what the farm earns while away")
	_check(sent.is_empty(), "a cart sent off during a catch-up makes no sound or message of its own")

	# A whole busy day caught up at once tells the scene nothing while it runs; the scene redraws once it is over.
	_maxed_farm(game, data_file)
	game.keep_goods = {}
	var heard := []
	var ears := {}
	for sig in game.get_script().get_script_signal_list():
		var ear := (func(signal_name: String) -> void: heard.append(signal_name)).bind(String(sig["name"]))
		if sig["args"].size() > 0:
			ear = ear.unbind(sig["args"].size())
		ears[String(sig["name"])] = ear
		game.connect(String(sig["name"]), ear)
	var busy: Dictionary = game.simulate_offline(2.0 * game.day_seconds())
	for signal_name in ears:
		game.disconnect(signal_name, ears[signal_name])
	_check(int(busy["harvested"]) > 0 and int(game.stats.get("cart_trips", 0)) > 0 and heard.is_empty(), "a catch-up sends the scene no signals while it runs: %s" % ", ".join(PackedStringArray(heard)))

	# Catching up a maxed farm whose storehouse is full takes moments, so opening the game never stalls on it.
	_maxed_farm(game, data_file)
	for item in data_file.get_value("items", {}):
		if String(data_file.get_value("items.%s.kind" % item, "good")) == "good":
			for q in 3:
				game.add_item(game.item_key(item, q), 2, true)
	game.add_item("lavender", game.holding_capacity() - game.stored_total(), true)
	var started := Time.get_ticks_msec()
	var jammed: Dictionary = game.simulate_offline(3.0 * 3600.0)
	var took := Time.get_ticks_msec() - started
	_check(bool(jammed["storage_full"]) and took < 6000, "three hours away on a full maxed farm are caught up in a few seconds (%d ms)" % took)

	# A farm stranded while away is helped once the player is back, with the gift kept in full and not counted as earnings.
	game.new_game()
	game.day_time = 8.0
	game.coins = 2
	var rescue := int(data_file.get_value("start.rescue_coins", 10))
	var gifts := []
	var note_gift := func(gift: int) -> void: gifts.append(gift)
	game.rescued.connect(note_gift)
	var stranded: Dictionary = game.simulate_offline(60.0)
	_check(game.coins == 2 and int(stranded["earned"]) == 0 and int(game.stats.get("earned", 0)) == 0 and gifts.is_empty(), "Uncle Marcus's gift waits until the catch-up is over")
	game.advance(0.1)
	game.rescued.disconnect(note_gift)
	_check(game.coins == 2 + rescue and gifts == [rescue] and int(game.stats.get("earned", 0)) == 0, "and then comes in full, with word of it, without counting as earnings")

	# The estate: deeds need the villa, buildings need materials, and workshops refine goods once loaded.
	game.new_game()
	game.day_time = 8.0
	game.coins = 9000
	var grove_plot := -1
	for i in game.plots.size():
		if game.plots[i]["zone"] == "grove":
			grove_plot = i
			break
	_check(not game.buy_zone("grove"), "the grove deed waits for the restored farmhouse")
	game.villa_stage = 2
	_check(game.buy_zone("grove") and game.plots[grove_plot]["unlocked"], "buying the grove deed opens its plots")
	game.selected_seed = "olives"
	_check(game.try_plant(grove_plot) and game.plots[grove_plot]["crop"] == "olives", "grove plots grow olive trees")
	game.selected_seed = "lavender"
	game.plots[grove_plot + 1]["unlocked"] = true
	_check(game.try_plant(grove_plot + 1) and game.plots[grove_plot + 1]["crop"] == "lavender", "lavender can be planted in the grove for the bees")
	game.villa_stage = 3
	game.buy_zone("yard")
	_check(game.do_building_action("drying_shed") and game.buildings["drying_shed"]["state"] == "owned", "buying a ruin")
	_check(not game.do_building_action("drying_shed"), "repairs need materials")
	game.add_item("timber", 2, true)
	_check(game.do_building_action("drying_shed") and game.buildings["drying_shed"]["state"] == "repairing", "repairing a ruin takes time")
	game.advance(secs.call("buildings.drying_shed.repair_seconds"))
	_check(game.buildings["drying_shed"]["state"] == "working", "repairs finish on their own")
	game.storage = {"lavender": 6, "wheat": 3}
	_check("lavender" in game.reserved_items(), "a working building's ingredients are reserved")
	_check(game.load_building("drying_shed") == 2 and game.count_item("lavender") == 2, "loading fills the queue from the storehouse")
	game.simulate_offline(2.0 * secs.call("buildings.drying_shed.recipes.0.seconds"))
	_check(game.count_item("dried_lavender") == 2, "the drying shed works through its queue, even offline")
	game.send_cart()
	_check(game.count_item("lavender") == 2 and game.count_item("wheat") == 0, "the cart leaves reserved ingredients and sells the rest")
	game.cart = game._empty_cart()
	_check(game.do_building_action("drying_shed") and game.buildings["drying_shed"]["state"] == "upgrading", "upgrading a working building brings the builders")
	_check(int(game.buildings["drying_shed"]["level"]) == 0, "an upgrade is not finished straight away")
	game.day_time = 8.0
	game.advance(game.building_upgrade_seconds("drying_shed") + 1.0)
	_check(int(game.buildings["drying_shed"]["level"]) == 1 and game.buildings["drying_shed"]["state"] == "working", "the builders finish the upgrade")
	var holds: int = game.storage_capacity()
	game.coins += 1000
	_check(game.buy_upgrade("storage") and game.projects.has("storage") and game.storage_capacity() == holds, "enlarging the storehouse takes builders and time")
	game.day_time = 8.0
	game.advance(game.upgrade_seconds("storage") + 1.0)
	_check(not game.projects.has("storage") and game.storage_capacity() > holds, "the bigger storehouse is ready once the work is done")
	game.buildings["beehives"]["state"] = "working"
	game.buildings["beehives"]["busy"] = true
	game.buildings["beehives"]["progress"] = 1.0
	game.day_time = 23.0
	game.advance(30.0)
	_check(is_equal_approx(float(game.buildings["beehives"]["progress"]), 1.0), "the bees rest at night")
	game.day_time = 8.0
	_check(game.building_queue_max("drying_shed") == 3, "an upgrade lets a building queue more")

	# Mills make two goods; bakeries can switch recipes; bees need nobody.
	game.buildings["mill"]["state"] = "working"
	game.storage = {"wheat": 3}
	game.load_building("mill")
	game.advance(secs.call("buildings.mill.recipes.0.seconds"))
	_check(game.count_item("flour") == 2 and game.count_item("straw") == 1, "the mill makes flour and straw")
	game.buildings["beehives"]["state"] = "working"
	game.zones_owned["grove"] = true
	game.advance(secs.call("buildings.beehives.recipes.0.seconds"))
	_check(game.count_item("honey") + game.count_item("lavender_honey") >= 1 and game.count_item("wax") >= 1, "the hives make honey and wax on their own")

	# A helper keeps their buildings loaded.
	game.villa_stage = 3
	game.storage = {"wheat": 12}
	game.hire_helper("miller")
	game.simulate_offline(8.0 * secs.call("buildings.mill.recipes.0.seconds"))
	_check(game.count_item("wheat") == 0 and game.count_item("flour") >= 6, "the miller keeps the mill going")
	game.storage = {"wheat": 3}
	game.buildings["mill"]["queue"] = []
	game.buildings["mill"]["busy"] = false
	game.day_time = 23.0
	game.advance(1.0)
	_check(game.buildings["mill"]["queue"].is_empty(), "nothing is loaded at night while the miller is indoors")
	game.day_time = 8.0
	game.live_helpers["miller"] = true
	game.advance(1.0)
	_check(game.buildings["mill"]["queue"].is_empty() and game.load_need("mill") == "wheat", "the miller on screen carries the wheat over by hand")
	game.live_helpers = {}
	game.advance(1.0)
	_check(game.buildings["mill"]["busy"] and game.count_item("wheat") == 0, "out of sight, the miller loads the mill at once")

	# The cellar ages wine, and the barn turns feed into eggs, milk and manure.
	game.new_game()
	game.day_time = 8.0
	game.coins = 9000
	game.villa_stage = 4
	game.levels["storage"] = 4
	for id in ["cellar", "barn"]:
		game.buildings[id]["state"] = "working"
	game.zones_owned["vineyard"] = true
	game.zones_owned["pasture"] = true
	game.add_item("young_wine", 2)
	_check(game.load_building("cellar") == 2, "young wine goes into casks")
	game.advance(100.0)
	_check(game.draw_wine() == 0, "wine must rest before it can be drawn")
	game.simulate_offline(secs.call("buildings.cellar.aging.2"))
	_check(game.draw_wine() == 2 and game.count_item("aged_wine") == 2 and game.storage.has("aged_wine@2"), "long-rested wine comes out excellent")
	_check(game.journal.has("milestone:excellent_wine"), "an excellent wine is a milestone")
	_check(game.market.buy("chicken") and game.market.buy("goat"), "buys animals for a working barn")
	game.add_item("straw", 4)
	_check(game.load_building("barn") == 4, "feed goes into the barn")
	game.advance(secs.call("buildings.barn.cycle_seconds"))
	_check(game.count_item("eggs") == 1 and game.count_item("milk") == 1 and game.count_item("manure") == 1, "animals make eggs, milk and manure")
	var cycle: float = secs.call("buildings.barn.cycle_seconds")
	game.storage = {}
	game.add_item("lavender", game.holding_capacity(), true)
	game.buildings["barn"]["feed"] = 5
	game.advance(cycle)
	_check(int(game.buildings["barn"]["feed"]) == 5 and game.count_item("eggs") == 0, "the barn keeps its feed while there is no room for the eggs and milk")
	game.remove_key("lavender", 2)
	game.advance(1.0)
	_check(int(game.buildings["barn"]["feed"]) == 4 and game.count_item("eggs") == 1 and game.count_item("manure") == 0, "and uses it once they fit, with no room needed for manure")
	game.storage = {}
	game.buildings["barn"]["level"] = 3
	game.advance(cycle)
	_check(game.storage.has("eggs@1") and game.storage.has("milk@1"), "a fully built barn makes fine eggs and milk")
	game.storage["manure"] = game.manure_cap()
	game.advance(cycle)
	_check(game.count_item("manure") == game.manure_cap(), "the storehouse keeps no more manure than the cap")
	game.storage.erase("manure")
	game.use_manure = false
	game.advance(cycle)
	_check(game.count_item("manure") == 0 and game.count_item("eggs") > 1, "with manure switched off, the barn keeps none")
	game.use_manure = true
	var clogged: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))
	clogged["storage"]["manure"] = game.storage_capacity()
	game.from_dict(clogged)
	_check(game.count_item("manure") == game.manure_cap(), "a save clogged with manure keeps only the cap when it loads")
	var with_pool: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))
	with_pool["furnishings"] = {"fire": true, "water": true}
	with_pool["coins"] = 100
	game.from_dict(with_pool)
	_check(game.coins == 15100 and game.furnishings.keys() == ["fire"], "a farm that bought the rain pool gets its price back and keeps its other furnishings")
	game.stats = {"planted": 1, "harvested": 1}
	game.from_dict(JSON.parse_string(JSON.stringify(game.to_dict())))
	_check(int(game.stats.get("cart_trips", 0)) == 0, "loading a farm that has harvested but never sent the cart counts no trip")

	# A batch keeps the recipe it was loaded with when the player picks another, through saves and from old saves too.
	game.new_game()
	game.day_time = 8.0
	game.buildings["bakery"]["state"] = "working"
	game.add_item("flour", 4, true)
	game.add_item("herbs", 2, true)
	_check(game.load_building("bakery") == 2, "the bakery loads two batches of bread")
	game.set_recipe("bakery", 1)
	game.advance(1.0)
	_check(is_equal_approx(game.batch_seconds("bakery"), float(data_file.get_value("buildings.bakery.recipes.0.seconds", 0))), "a running batch takes its own recipe's time")
	game.advance(2.0 * secs.call("buildings.bakery.recipes.0.seconds"))
	_check(game.count_item("bread") == 2 and game.count_item("herb_bread") == 0 and game.count_item("herbs") == 2, "bread loaded before the recipe changed comes out as bread")
	var old_save: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))
	var old_bakery: Dictionary = old_save["buildings"]["bakery"]
	old_bakery.erase("batch_recipe")
	old_bakery.merge({"recipe": 0, "busy": true, "progress": 10.0, "batch_q": 0.0, "queue": [0.0, 1.0]}, true)
	game.from_dict(old_save)
	game.advance(3.0 * secs.call("buildings.bakery.recipes.0.seconds"))
	_check(game.count_item("bread") == 5 and game.storage.has("bread@1"), "an old save's batches, kept as plain numbers, load and are baked")
	game.add_item("flour", 2, true)
	game.set_recipe("bakery", 1)
	game.load_building("bakery")
	game.from_dict(JSON.parse_string(JSON.stringify(game.to_dict())))
	game.set_recipe("bakery", 0)
	game.advance(secs.call("buildings.bakery.recipes.1.seconds"))
	_check(game.count_item("herb_bread") == 1 and game.count_item("bread") == 5, "a queued batch keeps its recipe through a save")
	game.buildings["mill"]["state"] = "working"
	game.buildings["mill"]["queue"] = [1.0]
	game.advance(secs.call("buildings.mill.recipes.0.seconds"))
	_check(game.storage.has("flour@1"), "a batch given as a plain number is still made")

	# Catch-up makes as much as play: work past a batch's end goes on to the next, and so does the cart's time on the road.
	var shed_run := func(offline: bool) -> int:
		game.new_game()
		game.day_time = 8.0
		game.levels["storage"] = 4
		game.buildings["drying_shed"]["state"] = "working"
		game.buildings["drying_shed"]["level"] = 3
		game.helpers["perfumer"] = 1
		game.add_item("lavender", 100, true)
		if offline:
			game.simulate_offline(300.0)
		else:
			for k in 3000:
				game.advance(0.1)
		return game.count_item("dried_lavender")
	var shed_live: int = shed_run.call(false)
	var shed_away: int = shed_run.call(true)
	_check(shed_live > 0 and absi(shed_away - shed_live) <= 2, "a fast workshop makes as much while away as in play (%d and %d)" % [shed_away, shed_live])
	var cart_run := func(offline: bool) -> int:
		game.new_game()
		game.day_time = 8.0
		game.levels["cart_speed"] = 3
		game.helpers["trader"] = 1
		game.add_item("wheat", 2000, true)
		if offline:
			game.simulate_offline(70.0)
		else:
			for k in 700:
				game.advance(0.1)
		return int(game.stats.get("cart_trips", 0))
	var trips_live: int = cart_run.call(false)
	var trips_away: int = cart_run.call(true)
	_check(trips_live > 5 and absi(trips_away - trips_live) <= 1, "the trader makes as many trips while away as in play (%d and %d)" % [trips_away, trips_live])

	# A plant whose whole crop does not fit stays ripe until there is room, and the player is told the storehouse is full.
	game.new_game()
	game.day_time = 8.0
	game.zones_owned["grove"] = true
	var tree := -1
	for i in game.plots.size():
		if game.plots[i]["zone"] == "grove" and tree < 0:
			tree = i
	game.plots[tree].merge({"unlocked": true, "crop": "olives", "growth": 9999.0}, true)
	game.add_item("lavender", game.holding_capacity() - 1, true)
	var warned := []
	var note_full := func() -> void: warned.append(true)
	game.storage_full.connect(note_full)
	_check(not game.try_harvest(tree) and game.is_ready(tree) and warned.size() == 1 and game.count_item("olives") == 0, "olives that do not all fit stay on the tree")
	game.storage_full.disconnect(note_full)
	game.helpers["presser"] = 1
	game.advance(5.0)
	_check(game.is_ready(tree) and game.count_item("olives") == 0, "a helper also waits for room for the whole crop")
	game.remove_key("lavender", 2)
	_check(game.try_harvest(tree) and game.count_item("olives") == int(data_file.get_value("crops.olives.yield", 0)), "and picks it once it fits")

	# The soil starts to dry when the rain stops, however long it rained.
	game.new_game()
	var damp := float(data_file.get_value("calendar.wet_seconds", 0))
	game.calendar.weather = "rain"
	game.calendar.weather_left = 9999.0
	game.calendar.wet_left = damp
	game.calendar.advance(2.0 * damp)
	game.calendar.weather = "sun"
	game.calendar.advance(damp - 1.0)
	_check(game.calendar.wet(), "the soil stays damp for a while after a long rain")
	game.calendar.advance(2.0)
	_check(not game.calendar.wet(), "and then dries")

	# Every decoration waits for the villa with portico, and for the land its spot is on.
	var zone_list: Array = data_file.get_value("estate.zones", [])
	var misplaced := []
	for id in data_file.get_value("decorations", {}):
		var d: Dictionary = data_file.get_value("decorations." + id, {})
		var land := ""
		for z in zone_list:
			if float(d.get("x", 0)) >= float(z["x"]):
				land = String(z["id"])
		if int(d.get("requires_villa", 0)) < 4 or String(d.get("zone", "home")) != land:
			misplaced.append(id)
	_check(misplaced.is_empty(), "every decoration needs the villa with portico and the land it stands on: %s" % ", ".join(PackedStringArray(misplaced)))
	game.new_game()
	game.villa_stage = 4
	game.journal.add("festival:vinalia")
	_check(game.decoration_block("pergola") != "", "the vine pergola waits for the pasture")
	game.zones_owned["pasture"] = true
	_check(game.decoration_block("pergola") == "", "and is on sale once the pasture is bought")

	# A computer that sleeps with the game open catches up on waking, by the wall clock, just as a closed game does.
	game.new_game()
	game.day_time = 8.0
	game.coins = 0
	game.cart = {"away": true, "time_left": 10.0, "items": 4, "value": 400, "load": []}
	var settings: Node = root.get_node("Settings")
	var saves: Node = root.get_node("Saves")
	var offline_setting: bool = settings.offline_progress
	var had_farm: bool = saves.has_farm
	var real_clock: Callable = game.wall_clock
	settings.offline_progress = true
	saves.has_farm = true
	var clock := [1000000.0]
	game.wall_clock = func() -> float: return clock[0]
	var woke := []
	var note_woke := func(s: Dictionary) -> void: woke.append(s)
	game.caught_up.connect(note_woke)
	var frame := func(seconds: float) -> void:
		clock[0] += seconds
		game._process(minf(seconds, 0.133))
	frame.call(0.016)
	frame.call(3.0 * game.day_seconds())
	_check(game.calendar.day >= 3 and woke.size() == 1 and is_equal_approx(float(woke[0]["seconds"]), 3.0 * game.day_seconds()), "a long sleep moves the calendar on day by day, with a summary")
	_check(game.coins == 400, "and the cart on the road when it slept pays in full")
	frame.call(120.0)
	frame.call(0.016)
	_check(woke.size() == 1, "the frame after a catch-up only sets the clock going again")
	game.speed = 500.0
	var day_before: int = game.calendar.day
	var hour_before: float = game.day_time
	frame.call(0.016)
	game.speed = 1.0
	_check(woke.size() == 1 and (game.calendar.day > day_before or game.day_time > hour_before), "a fast debug speed runs the estate faster without counting as time away")
	game.from_dict(JSON.parse_string(JSON.stringify(game.to_dict())))
	frame.call(600.0)
	_check(woke.size() == 1, "the first frame after a farm loads is not time away")
	frame.call(15.0)
	_check(woke.size() == 2 and is_equal_approx(float(woke[1]["seconds"]), 15.0), "a short sleep is caught up too, so the scene can redraw")
	settings.offline_progress = false
	day_before = game.calendar.day
	frame.call(3.0 * game.day_seconds())
	_check(woke.size() == 2 and game.calendar.day == day_before, "with offline progress off, a sleep is not caught up")
	settings.offline_progress = true
	saves.has_farm = false
	frame.call(0.016)
	frame.call(3.0 * game.day_seconds())
	_check(woke.size() == 2 and game.calendar.day == day_before, "the empty farm behind the title screen is never caught up")
	game.caught_up.disconnect(note_woke)
	game.wall_clock = real_clock
	settings.offline_progress = offline_setting
	saves.has_farm = had_farm

	# Every page in the journal can be filled: no good is listed at a quality the estate's rules cannot make.
	var wrong := []
	for item in data_file.get_value("items", {}):
		if data_file.get_value("items.%s.no_quality" % item, false):
			continue
		if _best_quality(item, data_file, {}) != int(data_file.get_value("items.%s.best_quality" % item, 2)):
			wrong.append(item)
	for page in game.journal.catalogue():
		var page_id := String(page["id"])
		if page_id.begins_with("quality:") and int(page_id.get_slice(":", 2)) > _best_quality(page_id.get_slice(":", 1), data_file, {}):
			wrong.append(page_id)
	_check(wrong.is_empty(), "every quality page in the journal can be reached: %s" % ", ".join(PackedStringArray(wrong)))
	var pages: Array = game.journal.catalogue().map(func(e): return e["id"])
	_check("quality:eggs:1" in pages and not "quality:eggs:2" in pages and not "quality:honey:2" in pages and "quality:cheese:2" in pages, "eggs and honey have a fine page but no excellent one, while cheese has both")

	# The market: demand, favourites, orders and the shop.
	game.new_game()
	game.day_time = 8.0
	game.add_item("lavender", 60, true)
	game.market.favourites = []
	var fresh: int = game.market.price("lavender")
	game.market.sell("lavender", 50)
	_check(game.market.price("lavender") < fresh, "selling a lot lowers today's price")
	game.market.new_day()
	game.market.favourites = ["lavender"]
	_check(game.market.price("lavender") > fresh, "a daily favourite sells for more")
	game.market.add_order()
	var order: Dictionary = game.market.orders[0]
	game.add_item(order["item"], int(order["amount"]), true)
	var coins_before: int = game.coins
	_check(game.market.deliver(0) and game.coins == coins_before + int(order["coins"]), "filling an order pays its reward")
	game.coins = 100
	_check(game.market.buy("seed_violet") and game.crop_unlocked("lavender_violet"), "buying cuttings unlocks a lavender variety")
	_check(not game.market.buy("seed_violet"), "cuttings are bought once")
	game.storage = {"lavender": 5}
	game.cart = {"away": true, "time_left": 10.0, "items": 4, "value": 40, "load": []}
	game.market.pack_cart()
	_check(game.market.brought_total() == 0 and game.market.sell("lavender", 5) == 0, "with the cart on the road, nothing is brought to the stalls")
	game.market.unpack_cart()
	game.cart = game._empty_cart()
	game.market.pack_cart()
	_check(game.market.brought_total() == 5, "a parked cart brings the goods marked for sale to the stalls")
	game.market.unpack_cart()

	# The calendar: seasons, weather and festivals.
	game.new_game()
	game.day_time = 8.0
	game.calendar.day = 0
	game.day_time = 23.99
	game.advance(5.0)
	_check(game.calendar.day == 1 and game.calendar.festival().get("id", "") == "cerealia", "Cerealia falls on the second day of spring")
	_check(game.journal.has("festival:cerealia"), "a festival is recorded in the journal")
	game.add_item("bread", 1)
	var festive: int = game.market.price("bread")
	game.calendar.day = 2
	_check(festive > game.market.price("bread"), "festival goods sell for more")
	game.calendar.day = 4
	_check(game.calendar.season_id() == "summer", "four days make a season")

	# The lararium and the villa.
	game.new_game()
	game.day_time = 8.0
	game.coins = 9000
	game.villa_stage = 4
	game.buildings["lararium"]["state"] = "working"
	game.add_item("bread", 1)
	_check(game.offer("ceres") and game.blessed("ceres"), "an offering of bread brings Ceres's blessing")
	_check(not game.offer("mercury"), "only one blessing at a time")
	game.advance(1801.0)
	_check(game.blessing.is_empty(), "blessings wear off")
	game.villa_stage = 2
	_check(not game.upgrade_villa(), "the villa rustica needs materials")
	game.add_item("stone", 6, true)
	game.add_item("timber", 4, true)
	game.add_item("tiles", 4, true)
	game.day_time = 8.0
	_check(game.upgrade_villa(), "pays coins and materials for the next villa stage")
	_check(game.villa_build["active"] and game.villa_stage == 2, "the villa is under construction, not finished instantly")
	game.day_time = 22.0
	game.advance(60.0)
	_check(game.villa_build["active"] and is_equal_approx(float(game.villa_build["time_left"]), secs.call("villa.stages.2.build_seconds") - 1.0), "building work stops for the night")
	# Building only goes on by day, so a night may fall in the middle of it.
	game.simulate_offline(secs.call("villa.stages.2.build_seconds") + game.day_seconds())
	_check(not game.villa_build["active"] and game.villa_stage == 3, "construction finishes while the game is closed")
	game.villa_stage = 4
	_check(game.missing({"provisions": 2}) != "", "provisions are bread or wine")
	game.add_item("young_wine", 1)
	game.add_item("bread", 1)
	_check(game.missing({"provisions": 2}) == "", "bread and wine both count as provisions")

	# Decorations, the dog and the journal.
	game.coins = 9000
	_check(game.buy_decoration("statue") and game.decorations.has("statue"), "buys a decoration")
	_check(not game.buy_decoration("golden_statue"), "the golden statue waits for the grand estate")
	var plain: float = game.helper_interval("farmhand")
	_check(game.buy_furnishing("fire") and game.furnishings.has("fire"), "buys a furnishing for the farmhouse")
	_check(not game.buy_furnishing("fire"), "a furnishing is bought only once")
	_check(game.helper_interval("farmhand") < plain, "a more comfortable home makes the helpers quicker")
	game.villa_stage = 1
	_check(game.furnishing_block("lamps") != "", "a ruined farmhouse cannot be furnished")
	game.villa_stage = 4
	game.dog_timer = 0.0
	var find: String = game.dog_dig()
	_check(find != "" and game.journal.has("find:" + find), "the dog digs something up now and then")
	_check(game.dog_dig() == "", "and then rests before the next find")
	game.stats["harvested"] = 1
	game.check_achievements()
	_check(game.journal.achievements.has("first_harvest"), "achievements unlock from stats")
	_check(game.journal.catalogue().size() > 80, "the journal has pages for everything")

	# Saving round trip.
	game.calendar.day = 9
	game.helpers["miller"] = 1
	game.buildings["cellar"]["casks"] = [120.0]
	var data: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))
	var coins: int = game.coins
	var stored: int = game.stored_total()
	var stage: int = game.villa_stage
	var hour: float = game.day_time
	game.new_game()
	game.day_time = 8.0
	game.from_dict(data)
	_check(game.coins == coins and game.stored_total() == stored and game.villa_stage == stage and is_equal_approx(game.day_time, hour), "save data round-trips")
	game.farm_name = "Villa Probe"
	game.intro_seen = false
	var named: Dictionary = JSON.parse_string(JSON.stringify(game.to_dict()))
	game.new_game()
	game.from_dict(named)
	_check(game.farm_name == "Villa Probe" and not game.intro_seen, "a farm keeps its name and whether it has been welcomed")
	named.erase("intro_seen")
	game.from_dict(named)
	_check(game.intro_seen, "a farm saved before the welcome was kept per farm counts as welcomed")
	_check(game.calendar.day == 9 and game.helpers.has("miller") and game.decorations.has("statue"), "calendar, helpers and decorations round-trip")
	_check(game.furnishings.has("fire"), "the farmhouse's furnishings round-trip")
	_check(game.buildings["cellar"]["casks"].size() == 1 and game.journal.has("find:" + find), "casks and the journal round-trip")
	var old := {"levels": {"farmhand": 2}, "coins": 5}
	game.from_dict(old)
	_check(int(game.helpers.get("farmhand", 0)) == 2, "an old save's farmhand upgrade becomes the hired farmhand")

	_dog_coats()



## Everything at its top level, as on the debug "maxed" farm, with every bed planted and ripe and every good kept.
func _maxed_farm(game: Node, data_file: Node) -> void:
	game.new_game()
	game.rng.seed = 3
	game.day_time = 8.0
	game.villa_stage = game.villa_stages().size()
	for z in game.zones_owned:
		game.zones_owned[z] = true
	for id in game.buildings:
		game.buildings[id]["state"] = "working"
		game.buildings[id]["level"] = game.building_info(id).get("levels", []).size()
	for kind in ["chicken", "goat"]:
		game.buildings["barn"]["animals"][kind] = game.animal_capacity(kind)
	game.buildings["barn"]["feed"] = 40
	for h in data_file.get_value("helpers", {}):
		game.helpers[h] = game.helper_info(h).get("costs", [0]).size()
	for u in game.levels:
		game.levels[u] = data_file.get_value("upgrades.%s.values" % u, [0]).size() - 1
	var crops := {"home": ["lavender", "lavender_violet", "lavender_bluegrey", "lavender_white", "wheat"], "grove": ["olives", "herbs"], "vineyard": ["grapes"]}
	for i in game.plots.size():
		var p: Dictionary = game.plots[i]
		var list: Array = crops[p["zone"]]
		p["unlocked"] = true
		p["crop"] = list[i % list.size()]
		p["growth"] = game.time_to_ready(p)
	for item in data_file.get_value("items", {}):
		game.keep_goods[item] = true


## The best quality the estate's rules can make a good at, worked out from the crops, the cellar, the barn and the recipes.
func _best_quality(item: String, data_file: Node, seen: Dictionary) -> int:
	if data_file.get_value("items.%s.no_quality" % item, false) or seen.has(item):
		return 0
	seen[item] = true
	var best := 0
	for c in data_file.get_value("crops", {}):
		if String(data_file.get_value("crops.%s.item" % c, c)) == item:
			best = 2
	var all: Dictionary = data_file.get_value("buildings", {})
	for id in all:
		var info: Dictionary = all[id]
		var top := 0
		for level in info.get("levels", []):
			top = maxi(top, int(level.get("quality", 0)))
		if info.get("kind", "") == "cellar" and item == "aged_wine":
			best = 2
		if item in info.get("makes", {}).values():
			best = maxi(best, top)
		for r in info.get("recipes", []):
			var outs: Array = r.get("out", {}).keys()
			if r.get("lavender_honey", false) and "honey" in outs:
				outs.append("lavender_honey")
			if not item in outs:
				continue
			var sum := 0.0
			var counted := 0
			for input in r.get("in", {}):
				if not data_file.get_value("items.%s.no_quality" % input, false):
					sum += _best_quality(String(input), data_file, seen.duplicate()) * int(r["in"][input])
					counted += int(r["in"][input])
			best = maxi(best, mini(2, int(round(sum / counted if counted > 0 else 0.0)) + top))
	return best


## Every dog breed comes in at least three coats, each its own look, and a saved "natural" coat still draws the breed as painted.
func _dog_coats() -> void:
	for breed in Coats.BREEDS["dog"]:
		var coats: Dictionary = Coats.options("dog", breed)
		_check(coats.size() >= 3, "the %s comes in at least three coats" % breed)
		var picture: Texture2D = load(Coats.breed_dir("dog", breed) + "sit_east/frame_08.png")
		var first: String = coats.keys()[0]
		_check(Coats.recolour(picture, "dog", first, breed) == picture, "a %s in its first coat looks as it is painted" % breed)
		for coat in coats.keys().slice(1):
			_check(Coats.recolour(picture, "dog", coat, breed) != picture, "the %s's %s coat is a look of its own" % [breed, coat])
		if breed != "hound":
			_check(first == "natural", "a %s saved in its natural coat keeps that look" % breed)
			# The headless renderer cannot read a made texture back, so the coats are compared pixel by pixel here.
			var source := picture.get_image()
			source.convert(Image.FORMAT_RGBA8)
			var looks := {}
			for coat in coats:
				var out := PackedColorArray()
				for y in source.get_height():
					for x in source.get_width():
						out.append(Coats.breed_pixel(breed, coat, source.get_pixel(x, y)))
				looks[str(out).hash()] = coat
			_check(looks.size() == coats.size(), "each of the %s's coats looks different" % breed)


func _check(ok: bool, what: String) -> void:
	check(ok, what)
