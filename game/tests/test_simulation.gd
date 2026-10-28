extends SceneTree
## Headless checks of the estate rules: run with Godot --headless --script res://tests/test_simulation.gd

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	var data_file: Node = root.get_node("Balance")
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
	_check(game.coins == 100 and int(summary["earned"]) == 100, "time away keeps a quarter of what the farm earns")

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

	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
	else:
		print("ok: " + what)
