extends Node
## The whole estate's state and the rules that change it. Live play and offline catch-up both run through advance().

const Calendar := preload("res://scripts/game/calendar.gd")
const Market := preload("res://scripts/game/market.gd")
const Journal := preload("res://scripts/game/journal.gd")

signal planted(plot_index: int)
signal dug_up(plot_index: int)
signal unlocked(plot_index: int)
signal harvested(plot_index: int, amount: int)
signal storage_full
signal cart_left(items: int, value: int)
signal cart_returned(coins: int)
signal villa_build_started(stage: int)
signal villa_upgraded(stage: int)
signal message(text: String)
signal zone_bought(zone_id: String)
signal building_changed(building_id: String)
signal building_made(building_id: String, item: String, amount: int)
signal discovered(entry_id: String)
signal achievement_unlocked(achievement: Dictionary)
signal weather_changed(weather: String, before: String)
signal season_changed(season_id: String)
signal festival_started(festival_id: String)
signal order_added
signal dog_found(find_id: String, text: String)
signal blessing_started(god: String)
signal helper_hired(helper_id: String)
signal decoration_bought(decoration_id: String)
signal animal_added(kind: String)
signal pets_changed

var coins := 0
## Gold coins from special orders and festivals, spent on rare decorations.
var aureus := 0
## Goods by storage key; a key like "lavender@2" is an excellent bundle, plain "lavender" a common one.
var storage := {}
var plots: Array = []
var levels := {}
## The crop a click on an empty plot plants.
var selected_seed := "lavender"
var crops_unlocked := {}
var villa_stage := 1
## A villa stage under construction; it finishes on its own, even while the game is closed.
var villa_build := {}
## In-game clock in hours, 0 to 24.
var day_time := 16.0
var cart := {}
## Which parts of the estate are owned; the rest are bought with a land deed.
var zones_owned := {}
## Each building's state: "ruin" (not yet bought), "owned" (bought, still a ruin), "repairing" or "working".
var buildings := {}
## Hired helpers and their level.
var helpers := {}
var helper_timers := {}
## Helpers walking about on screen, who harvest the plant they actually reach instead of on a timer.
var live_helpers := {}
var decorations := {}
## The farm's dog and cat: the names and coats the player chose for them.
var pets := {}
## The lararium's blessing in effect, if any.
var blessing := {}
## When on, every planting and regrowth uses one manure from the storehouse.
var use_manure := true
var stats := {}
var calendar: RefCounted
var market: RefCounted
var journal: RefCounted
var rng := RandomNumberGenerator.new()
var dog_timer := 0.0
var _achievement_timer := 0.0
## Debug-only multiplier for live time; offline catch-up always uses real elapsed time.
var speed := 1.0
## True during offline catch-up, so hundreds of harvests do not each spawn an effect.
var quiet := false


func _ready() -> void:
	new_game()


func _process(delta: float) -> void:
	advance(delta * speed)
	dog_timer -= delta * speed
	_achievement_timer -= delta
	if _achievement_timer <= 0.0:
		_achievement_timer = 1.0
		check_achievements()


func new_game() -> void:
	rng.randomize()
	coins = int(Balance.get_value("start.coins", 20))
	aureus = 0
	storage = {}
	plots = []
	var unlocked_count := int(Balance.get_value("start.unlocked_plots", 4))
	# Home plots come first, so saves from before the estate grew still line up with the same plots.
	for group in Balance.get_value("plots.zones", [{"zone": "home", "count": 17}]):
		for k in int(group["count"]):
			var home: bool = group["zone"] == "home"
			plots.append(_new_plot(String(group["zone"]), home and k < unlocked_count))
	zones_owned = {}
	for z in zones():
		zones_owned[z["id"]] = int(z.get("deed", 0)) == 0
	buildings = {}
	for id in Balance.get_value("buildings", {}):
		buildings[id] = _new_building()
	levels = {"storage": 0, "cart_capacity": 0, "cart_speed": 0, "channels": 0}
	selected_seed = "lavender"
	crops_unlocked = {}
	for c in Balance.get_value("crops", {}):
		if not Balance.get_value("crops.%s.locked" % c, false):
			crops_unlocked[c] = true
	villa_stage = 1
	villa_build = {"active": false, "time_left": 0.0}
	day_time = float(Balance.get_value("time.start_hour", 16))
	cart = _empty_cart()
	helpers = {}
	helper_timers = {}
	decorations = {}
	pets = default_pets()
	blessing = {}
	use_manure = true
	stats = {}
	dog_timer = _next_dog_find()
	calendar = Calendar.new(self)
	market = Market.new(self)
	journal = Journal.new(self)
	market.new_day()
	journal.add("animal:dog")
	journal.add("animal:donkey")


# Items ------------------------------------------------------------------

static func item_key(base: String, quality: int) -> String:
	return base if quality <= 0 else "%s@%d" % [base, quality]


static func item_base(key: String) -> String:
	return key.get_slice("@", 0)


static func item_quality(key: String) -> int:
	return int(key.get_slice("@", 1)) if "@" in key else 0


func item_name(key: String) -> String:
	var name := String(Balance.get_value("items.%s.name" % item_base(key), item_base(key)))
	var q := item_quality(key)
	return name if q == 0 else "%s %s" % [Balance.get_value("quality.names", ["", "Fine", "Excellent"])[q], name.to_lower()]


## The unchanging price of one unit, before the market's daily mood.
func base_price(key: String) -> float:
	var mult: Array = Balance.get_value("quality.price", [1, 1.5, 2.5])
	return float(Balance.get_value("items.%s.price" % item_base(key), 0)) * float(mult[mini(item_quality(key), mult.size() - 1)])


## Kept for older callers: the market's full price for a good today.
func item_price(key: String) -> int:
	return market.price(key)


func count_item(base: String) -> int:
	if base == "provisions":
		var n := 0
		for p in Balance.get_value("provisions", []):
			n += count_item(String(p))
		return n
	var total := 0
	for key in storage:
		if item_base(key) == base:
			total += int(storage[key])
	return total


## Goods in the storehouse; building materials are stacked in the yard and take no room there.
func stored_total() -> int:
	var total := 0
	for key in storage:
		if not is_material(key):
			total += int(storage[key])
	return total


func is_material(key: String) -> bool:
	return Balance.get_value("items.%s.kind" % item_base(key), "good") == "material"


## Puts goods in the storehouse, as many as fit unless forced, and returns how many went in.
func add_item(key: String, amount: int, force := false) -> int:
	if Balance.get_value("items.%s.no_quality" % item_base(key), false):
		key = item_base(key)
	if not force and not is_material(key):
		amount = mini(amount, storage_capacity() - stored_total())
	if amount <= 0:
		return 0
	storage[key] = int(storage.get(key, 0)) + amount
	discover("item:" + item_base(key))
	var q := item_quality(key)
	if q > 0:
		discover("quality:%s:%d" % [item_base(key), q])
		discover("quality:%d" % q)
	return amount


func remove_key(key: String, amount: int) -> void:
	storage[key] = int(storage.get(key, 0)) - amount
	if int(storage[key]) <= 0:
		storage.erase(key)


func has_items(needs: Dictionary) -> bool:
	for base in needs:
		if count_item(String(base)) < int(needs[base]):
			return false
	return true


## Takes goods, the plainest first, and returns their average quality; -1 means not enough.
func take_items(needs: Dictionary) -> float:
	if not has_items(needs):
		return -1.0
	var quality_sum := 0.0
	var counted := 0
	for base in needs:
		var bases: Array = Balance.get_value("provisions", []) if base == "provisions" else [base]
		var left := int(needs[base])
		for q in 3:
			for b in bases:
				var key := item_key(String(b), q)
				var take := mini(left, int(storage.get(key, 0)))
				if take > 0:
					remove_key(key, take)
					left -= take
					if not Balance.get_value("items.%s.no_quality" % b, false):
						quality_sum += q * take
						counted += take
	return quality_sum / counted if counted > 0 else 0.0


## Whether a price can be paid; returns what is missing, or "" when it can.
func missing(cost: Dictionary) -> String:
	if coins < int(cost.get("coins", 0)):
		return "Not enough sestertii"
	if aureus < int(cost.get("aureus", 0)):
		return "Not enough aurei"
	for key in cost:
		if key in ["coins", "aureus"] or int(cost[key]) <= 0:
			continue
		var short := int(cost[key]) - count_item(String(key))
		if short > 0:
			var name := "bread or wine" if key == "provisions" else String(Balance.get_value("items.%s.name" % key, key)).to_lower()
			return "Needs %d more %s" % [short, name]
	return ""


func pay(cost: Dictionary) -> bool:
	var problem := missing(cost)
	if problem != "":
		message.emit(problem)
		return false
	coins -= int(cost.get("coins", 0))
	aureus -= int(cost.get("aureus", 0))
	var goods := {}
	for key in cost:
		if not key in ["coins", "aureus"] and int(cost[key]) > 0:
			goods[key] = int(cost[key])
	take_items(goods)
	return true


func gain_aureus(n: int) -> void:
	aureus += n
	add_stat("aureus_earned", n)


func add_stat(key: String, n: int) -> void:
	stats[key] = int(stats.get(key, 0)) + n


func discover(id: String) -> void:
	if journal and journal.add(id) and not quiet:
		discovered.emit(id)


func check_achievements() -> void:
	for a in journal.check_achievements():
		if not quiet:
			achievement_unlocked.emit(a)


# Crops ------------------------------------------------------------------

func crop_info(crop_id: String) -> Dictionary:
	return Balance.get_value("crops." + crop_id, {})


func crop_unlocked(crop_id: String) -> bool:
	return crops_unlocked.has(crop_id)


func unlock_crop(crop_id: String) -> void:
	crops_unlocked[crop_id] = true


func time_to_ready(plot: Dictionary) -> float:
	var info := crop_info(plot["crop"])
	return float(info.get("regrow_seconds" if int(plot["cycle"]) > 0 else "grow_seconds", 60))


func is_ready(i: int) -> bool:
	var p: Dictionary = plots[i]
	return p["unlocked"] and p["crop"] != "" and float(p["growth"]) >= time_to_ready(p)


func growth_fraction(i: int) -> float:
	var p: Dictionary = plots[i]
	if p["crop"] == "":
		return 0.0
	return clampf(float(p["growth"]) / time_to_ready(p), 0.0, 1.0)


func watered(i: int) -> bool:
	return calendar.wet() or (upgrade_value("channels") > 0.0 and plots[i]["zone"] == "home")


## How fast a plot grows right now: the season, water, manure and the gods all play a part.
func growth_rate(i: int) -> float:
	var p: Dictionary = plots[i]
	var info := crop_info(p["crop"])
	var rate := float(info.get("seasons", {}).get(calendar.season_id(), 1.0))
	if not watered(i):
		rate *= float(Balance.get_value("calendar.dry_growth", 0.8))
	if p.get("manured", false):
		rate *= float(Balance.get_value("calendar.manure_growth", 1.25))
	if info.get("grain", false) and blessed("ceres"):
		rate *= 2.0
	return rate


## Which picture a plot should show: locked, empty, stage0, stage1, stage2, bloom or harvested.
func plot_visual(i: int) -> String:
	var p: Dictionary = plots[i]
	if not p["unlocked"]:
		return "locked"
	if p["crop"] == "":
		return "empty"
	var f := growth_fraction(i)
	if f >= 1.0:
		return "bloom"
	if int(p["cycle"]) > 0:
		return "harvested" if f < 0.5 else "stage2"
	if f < 0.25:
		return "stage0"
	if f < 0.6:
		return "stage1"
	return "stage2"


func unlock_cost() -> int:
	var unlocked_count := 0
	for p in plots:
		if p["unlocked"] and p["zone"] == "home":
			unlocked_count += 1
	var extra := unlocked_count - int(Balance.get_value("start.unlocked_plots", 4))
	var base := float(Balance.get_value("plots.unlock_cost_base", 15))
	return int(round(base * pow(float(Balance.get_value("plots.unlock_cost_growth", 1.3)), maxi(extra, 0))))


## The parts of the estate a crop can be planted in: lavender grows on the farm and in the grove, olives only in the grove.
func crop_zones(crop_id: String) -> Array:
	var info := crop_info(crop_id)
	return info.get("zones", [info.get("zone", "home")])


## The crop an empty plot gets: the chosen seed when it grows in that zone, otherwise the zone's own crop.
func seed_for_plot(i: int) -> String:
	var zone := String(plots[i]["zone"])
	if zone in crop_zones(selected_seed) and crop_unlocked(selected_seed):
		return selected_seed
	for crop in Balance.get_value("crops", {}):
		if crop_zones(crop)[0] == zone and crop_unlocked(crop):
			return crop
	return ""


func try_plant(i: int, crop_id := "") -> bool:
	var p: Dictionary = plots[i]
	if crop_id == "":
		crop_id = seed_for_plot(i)
	if crop_id == "":
		message.emit("Buy cuttings for this land at the market")
		return false
	if not p["unlocked"] or p["crop"] != "":
		return false
	var cost := int(crop_info(crop_id).get("plant_cost", 0))
	if coins < cost:
		message.emit("Not enough sestertii")
		return false
	coins -= cost
	p["crop"] = crop_id
	p["growth"] = 0.0
	p["cycle"] = 0
	p["ready_age"] = 0.0
	_apply_manure(p)
	add_stat("planted", 1)
	discover("crop:" + crop_id)
	planted.emit(i)
	return true


## Clears a plot so something else can be planted there; whatever was growing is lost, but the bed stays dug.
func dig_up(i: int) -> bool:
	var p: Dictionary = plots[i]
	if not p["unlocked"] or p["crop"] == "":
		return false
	p["crop"] = ""
	p["growth"] = 0.0
	p["cycle"] = 0
	p["ready_age"] = 0.0
	p["manured"] = false
	dug_up.emit(i)
	return true


func try_harvest(i: int) -> bool:
	if not is_ready(i):
		return false
	if stored_total() >= storage_capacity():
		storage_full.emit()
		return false
	_harvest(i, true)
	return true


func try_unlock(i: int) -> bool:
	var p: Dictionary = plots[i]
	if p["unlocked"] or not zone_owned(String(p["zone"])):
		return false
	var cost := unlock_cost()
	if coins < cost:
		message.emit("Not enough sestertii")
		return false
	coins -= cost
	p["unlocked"] = true
	add_stat("plots_unlocked", 1)
	unlocked.emit(i)
	return true


func _harvest(i: int, by_hand := false) -> int:
	var p: Dictionary = plots[i]
	var info := crop_info(p["crop"])
	var base := String(info.get("item", p["crop"]))
	var amount := int(info.get("yield", 1))
	if p["crop"] == "olives" and blessed("minerva"):
		amount += 1
	var key := item_key(base, _harvest_quality(i, by_hand))
	amount = add_item(key, amount)
	p["growth"] = 0.0
	p["ready_age"] = 0.0
	p["cycle"] = int(p["cycle"]) + 1
	p["manured"] = false
	# Perennials like lavender regrow from the same plant; annuals like wheat leave the plot empty.
	if not info.get("perennial", false):
		p["crop"] = ""
		p["cycle"] = 0
	else:
		_apply_manure(p)
	add_stat("harvested", amount)
	if not quiet:
		harvested.emit(i, amount)
	return amount


## Care makes better crops: manure, water, a well-timed harvest and Pomona's blessing each raise the odds.
func _harvest_quality(i: int, by_hand: bool) -> int:
	var p: Dictionary = plots[i]
	if Balance.get_value("items.%s.no_quality" % String(crop_info(p["crop"]).get("item", "")), false):
		return 0
	var points := 0.0
	if p.get("manured", false):
		points += 1.0
	if watered(i):
		points += 0.5
	if by_hand and float(p.get("ready_age", 0.0)) <= float(Balance.get_value("quality.timely_seconds", 20)):
		points += 1.0
	if crop_info(p["crop"]).get("fruit", false) and blessed("pomona"):
		points += 1.5
	var roll := points + rng.randf() * 1.5
	return 2 if roll >= 3.4 else (1 if roll >= 2.2 else 0)


func _apply_manure(p: Dictionary) -> void:
	if use_manure and count_item("manure") > 0:
		take_items({"manure": 1})
		p["manured"] = true


# Upgrades and the villa -------------------------------------------------

func upgrade_info(id: String) -> Dictionary:
	return Balance.get_value("upgrades." + id, {})


func upgrade_value(id: String) -> float:
	var values: Array = upgrade_info(id).get("values", [0])
	return float(values[mini(int(levels.get(id, 0)), values.size() - 1)])


## The price of the next level, or -1 when the upgrade is maxed out.
func upgrade_cost(id: String) -> int:
	var costs: Array = upgrade_info(id).get("costs", [])
	var level := int(levels.get(id, 0))
	return int(costs[level]) if level < costs.size() else -1


func storage_capacity() -> int:
	return int(upgrade_value("storage"))


func cart_capacity() -> int:
	return int(upgrade_value("cart_capacity"))


func cart_trip_seconds() -> float:
	return upgrade_value("cart_speed")


func buy_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0:
		return false
	if coins < cost:
		message.emit("Not enough sestertii")
		return false
	coins -= cost
	levels[id] = int(levels.get(id, 0)) + 1
	return true


func villa_stages() -> Array:
	return Balance.get_value("villa.stages", [])


## The price of the next villa stage, or an empty dictionary when the villa is finished or being built.
func villa_next_price() -> Dictionary:
	var stages := villa_stages()
	if villa_build["active"] or villa_stage >= stages.size() or demo_capped_villa():
		return {}
	var cost: Variant = stages[villa_stage].get("cost", 0)
	return cost if cost is Dictionary else {"coins": int(cost)}


## The coins part of the next villa stage, or -1 when there is no next stage to pay for.
func villa_next_cost() -> int:
	var price := villa_next_price()
	return int(price.get("coins", 0)) if not price.is_empty() else -1


func upgrade_villa() -> bool:
	var price := villa_next_price()
	if price.is_empty() or not pay(price):
		return false
	var stage: Dictionary = villa_stages()[villa_stage]
	villa_build = {"active": true, "time_left": float(stage.get("build_seconds", 0))}
	villa_build_started.emit(villa_stage + 1)
	if villa_build["time_left"] <= 0.0:
		_finish_villa()
	return true


func _finish_villa() -> void:
	villa_stage += 1
	villa_build = {"active": false, "time_left": 0.0}
	if not quiet:
		villa_upgraded.emit(villa_stage)


# The cart ---------------------------------------------------------------

func send_cart() -> bool:
	if cart["away"]:
		return false
	var capacity := cart_capacity()
	var loaded := 0
	var value := 0
	var goods := sellable_goods()
	var taken := []
	var keys := goods.keys()
	# The most valuable goods go first, so a small cart makes the best of its trip.
	keys.sort_custom(func(a, b): return market.cart_price(a) > market.cart_price(b))
	for key in keys:
		var take := mini(int(goods[key]), capacity - loaded)
		if take <= 0:
			continue
		for n in take:
			value += market.cart_price(key)
			market.note_sold(key, 1)
		loaded += take
		taken.append(key)
		remove_key(key, take)
	if loaded == 0:
		message.emit("Nothing in the storehouse to sell")
		return false
	cart = {"away": true, "time_left": cart_trip_seconds(), "items": loaded, "value": value, "load": taken.slice(0, 4)}
	add_stat("cart_trips", 1)
	cart_left.emit(loaded, value)
	return true


# Time -------------------------------------------------------------------

## Moves the estate forward by dt seconds and reports what happened.
func advance(dt: float) -> Dictionary:
	var result := {"harvested": 0, "earned": 0, "made": 0}
	calendar.advance(dt)
	market.advance(dt)
	result["made"] = _advance_buildings(dt)
	var before := day_time
	day_time = fmod(day_time + dt * 24.0 / day_seconds(), 24.0)
	if day_time < before:
		calendar.next_day()
		market.new_day()
	if villa_build["active"]:
		villa_build["time_left"] = float(villa_build["time_left"]) - dt
		if villa_build["time_left"] <= 0.0:
			_finish_villa()
	if not blessing.is_empty():
		blessing["time_left"] = float(blessing["time_left"]) - dt
		if blessing["time_left"] <= 0.0:
			blessing = {}
	for i in plots.size():
		var p: Dictionary = plots[i]
		if p["unlocked"] and p["crop"] != "":
			var need := time_to_ready(p)
			if float(p["growth"]) >= need:
				p["ready_age"] = float(p.get("ready_age", 0.0)) + dt
			else:
				p["growth"] = minf(float(p["growth"]) + dt * growth_rate(i), need)
	if cart["away"]:
		cart["time_left"] = float(cart["time_left"]) - dt
		if cart["time_left"] <= 0.0:
			var value := int(cart["value"])
			coins += value
			add_stat("earned", value)
			result["earned"] += value
			cart = _empty_cart()
			if not quiet:
				cart_returned.emit(value)
	result["harvested"] += _advance_helpers(dt)
	return result


## Catches up on time the game was closed, in small steps so every rule applies in order.
func simulate_offline(seconds: float) -> Dictionary:
	var remaining := minf(seconds, float(Balance.get_value("offline.max_hours", 72)) * 3600.0)
	var step := float(Balance.get_value("offline.step_seconds", 5))
	var start_coins := coins
	var summary := {"seconds": remaining, "harvested": 0, "earned": 0, "made": 0}
	quiet = true
	while remaining > 0.0:
		var dt := minf(step, remaining)
		var r := advance(dt)
		summary["harvested"] += r["harvested"]
		summary["made"] += r["made"]
		remaining -= dt
	quiet = false
	summary["earned"] = coins - start_coins
	summary["ready"] = 0
	for i in plots.size():
		if is_ready(i):
			summary["ready"] += 1
	summary["storage_full"] = stored_total() >= storage_capacity()
	return summary


## Real seconds in one in-game day, as the player has set it.
func day_seconds() -> float:
	return float(Settings.day_minutes) * 60.0 if Settings.day_minutes > 0 else float(Balance.get_value("time.day_seconds", 1200))


func blessed(god: String) -> bool:
	return blessing.get("god", "") == god


# Estate -----------------------------------------------------------------

func zones() -> Array:
	return Balance.get_value("estate.zones", [])


func zone_info(zone_id: String) -> Dictionary:
	for z in zones():
		if z["id"] == zone_id:
			return z
	return {}


func zone_owned(zone_id: String) -> bool:
	return bool(zones_owned.get(zone_id, false))


## Why a zone's deed cannot be bought yet, or "" when it can.
func zone_block(zone_id: String) -> String:
	var z := zone_info(zone_id)
	if is_demo() and not zone_id in Balance.get_value("demo.zones", []):
		return "Available in the full game"
	var needs := int(z.get("requires_villa", 0))
	if villa_stage < needs:
		return "Restore the villa first: %s" % String(villa_stages()[needs - 1]["name"]).to_lower()
	return ""


func buy_zone(zone_id: String) -> bool:
	if zone_owned(zone_id):
		return false
	var block := zone_block(zone_id)
	if block != "":
		message.emit(block)
		return false
	if not pay({"coins": int(zone_info(zone_id).get("deed", 0))}):
		return false
	zones_owned[zone_id] = true
	for p in plots:
		if p["zone"] == zone_id:
			p["unlocked"] = true
	zone_bought.emit(zone_id)
	return true


func is_demo() -> bool:
	return OS.has_feature("demo")


func demo_capped_villa() -> bool:
	return is_demo() and villa_stage >= int(Balance.get_value("demo.max_villa", 3))


# Buildings --------------------------------------------------------------

func building_info(id: String) -> Dictionary:
	return Balance.get_value("buildings." + id, {})


func building_kind(id: String) -> String:
	return String(building_info(id).get("kind", "workshop"))


func building_level_info(id: String) -> Dictionary:
	var level := int(buildings[id]["level"])
	var levels_info: Array = building_info(id).get("levels", [])
	return levels_info[level - 1] if level > 0 and level <= levels_info.size() else {}


func building_speed(id: String) -> float:
	var speed_now := float(building_level_info(id).get("speed", 1.0))
	if blessed("lares"):
		speed_now *= 1.5
	if blessed("bacchus") and id in ["wine_press", "olive_press"]:
		speed_now *= 1.5
	return speed_now


func building_batch(id: String) -> int:
	return int(building_level_info(id).get("batch", 1))


func building_queue_max(id: String) -> int:
	return int(building_level_info(id).get("queue", building_info(id).get("queue", 2)))


func working_buildings() -> int:
	return buildings.values().filter(func(b): return b["state"] == "working").size()


## The recipes a building can use now; later villa stages unlock some.
func recipes(id: String) -> Array:
	return building_info(id).get("recipes", []).filter(func(r): return int(r.get("requires_villa", 0)) <= villa_stage)


func current_recipe(id: String) -> Dictionary:
	var list := recipes(id)
	return list[clampi(int(buildings[id]["recipe"]), 0, list.size() - 1)] if not list.is_empty() else {}


func set_recipe(id: String, index: int) -> void:
	buildings[id]["recipe"] = clampi(index, 0, maxi(0, recipes(id).size() - 1))
	building_changed.emit(id)


## The next thing to do with a building and its price: buy, repair, upgrade, or nothing.
func building_action(id: String) -> Dictionary:
	var b: Dictionary = buildings[id]
	var info := building_info(id)
	match b["state"]:
		"ruin":
			return {"action": "buy", "cost": {"coins": int(info.get("buy", 0))}}
		"owned":
			var repair: Variant = info.get("repair", 0)
			return {"action": "repair", "cost": repair if repair is Dictionary else {"coins": int(repair)}}
		"working":
			var levels_info: Array = info.get("levels", [])
			var level := int(b["level"])
			if level < levels_info.size():
				return {"action": "upgrade", "cost": levels_info[level]["cost"]}
	return {}


## Why a building cannot be bought or repaired yet, or "" when nothing stands in the way.
func building_block(id: String) -> String:
	var info := building_info(id)
	if not zone_owned(String(info.get("zone", "home"))):
		return "Buy this land first"
	var needs := int(info.get("requires_villa", 0))
	if villa_stage < needs:
		return "Restore the villa first: %s" % String(villa_stages()[needs - 1]["name"]).to_lower()
	return ""


func do_building_action(id: String) -> bool:
	var act := building_action(id)
	if act.is_empty():
		return false
	var block := building_block(id)
	if block != "":
		message.emit(block)
		return false
	if not pay(act["cost"]):
		return false
	var b: Dictionary = buildings[id]
	match act["action"]:
		"buy":
			b["state"] = "owned"
		"repair":
			b["state"] = "repairing"
			b["time_left"] = float(building_info(id).get("repair_seconds", 30))
		"upgrade":
			b["level"] = int(b["level"]) + 1
	building_changed.emit(id)
	return true


func set_building_paused(id: String, paused: bool) -> void:
	buildings[id]["paused"] = paused
	building_changed.emit(id)


## Goods a working building is waiting to use, which the cart leaves at home instead of selling.
func reserved_items() -> Array:
	return reserved_amounts().keys()


## How much of each good the working buildings need for their next batch; the cart sells only what is beyond that.
func reserved_amounts() -> Dictionary:
	var keep := {}
	for id in buildings:
		var b: Dictionary = buildings[id]
		if b["state"] != "working" or b["paused"]:
			continue
		var needs: Dictionary = current_recipe(id).get("in", {})
		var loads := building_batch(id)
		match building_kind(id):
			"cellar":
				needs = {"young_wine": 1}
			"barn":
				needs = {}
		for item in needs:
			keep[item] = int(keep.get(item, 0)) + int(needs[item]) * loads
	return keep


## Goods the cart may take, by storage key: everything except materials and what the workshops keep back.
## The plainest units are the ones kept, since workshops use those first, so the better ones go to market.
func sellable_goods() -> Dictionary:
	# A nearly full storehouse sells everything, so goods kept for workshops can never jam the farm.
	var keep := reserved_amounts() if stored_total() < storage_capacity() * 0.9 else {}
	var out := {}
	for q in 3:
		for key in storage.keys():
			if item_quality(key) != q or Balance.get_value("items.%s.kind" % item_base(key), "good") != "good":
				continue
			var base := item_base(key)
			var kept := mini(int(keep.get(base, 0)), int(storage[key]))
			keep[base] = int(keep.get(base, 0)) - kept
			if int(storage[key]) - kept > 0:
				out[key] = int(storage[key]) - kept
	return out


## Loads as many batches as the building's queue holds and the storehouse can supply; returns how many.
func load_building(id: String) -> int:
	var b: Dictionary = buildings[id]
	if b["state"] != "working":
		return 0
	match building_kind(id):
		"cellar":
			return _fill_casks(id)
		"barn":
			return _feed_barn(id)
		"shrine":
			return 0
	var r := current_recipe(id)
	var needs := {}
	for item in r.get("in", {}):
		needs[item] = int(r["in"][item]) * building_batch(id)
	var loaded := 0
	while b["queue"].size() < building_queue_max(id) and has_items(needs) and not needs.is_empty():
		b["queue"].append(take_items(needs))
		loaded += 1
	return loaded


func _helper_runs(id: String) -> bool:
	var helper := String(building_info(id).get("helper", ""))
	return helper != "" and helpers.has(helper)


func _advance_buildings(dt: float) -> int:
	var made := 0
	for id in buildings:
		var b: Dictionary = buildings[id]
		if b["state"] == "repairing":
			b["time_left"] = float(b["time_left"]) - dt
			if b["time_left"] <= 0.0:
				b["state"] = "working"
				discover("building:" + id)
				if not quiet:
					building_changed.emit(id)
			continue
		if b["state"] != "working" or b["paused"]:
			continue
		match building_kind(id):
			"cellar":
				made += _advance_cellar(id, dt)
				continue
			"barn":
				made += _advance_barn(id, dt)
				continue
			"shrine":
				continue
		var r := current_recipe(id)
		if r.is_empty():
			continue
		if r.get("in", {}).is_empty():
			# Bees need nobody: hives fill their own queue.
			while b["queue"].size() < building_queue_max(id):
				b["queue"].append(0.0)
		elif _helper_runs(id) and b["queue"].size() < building_queue_max(id):
			load_building(id)
		if not b["busy"]:
			if b["queue"].is_empty():
				continue
			b["batch_q"] = float(b["queue"].pop_front())
			b["busy"] = true
			b["progress"] = 0.0
		var seconds := float(r.get("seconds", 30))
		b["progress"] = minf(float(b["progress"]) + dt * building_speed(id), seconds)
		if b["progress"] < seconds:
			continue
		var out := {}
		for item in r.get("out", {}):
			var name := String(item)
			if name == "honey" and r.get("lavender_honey", false) and _lavender_in_bloom():
				name = "lavender_honey"
			out[name] = int(r["out"][item]) * building_batch(id)
		var amount := 0
		for item in out:
			amount += int(out[item])
		# A finished batch waits in the building until the storehouse has room for it.
		if stored_total() + amount > storage_capacity():
			continue
		var q := clampi(int(round(float(b["batch_q"]))) + int(building_level_info(id).get("quality", 0)), 0, 2)
		for item in out:
			add_item(item_key(item, q), int(out[item]))
			if not quiet:
				building_made.emit(id, item, int(out[item]))
		made += amount
		b["busy"] = false
		b["progress"] = 0.0
	return made


func _lavender_in_bloom() -> bool:
	for i in plots.size():
		if String(plots[i]["crop"]).begins_with("lavender") and is_ready(i):
			return true
	return false


# The cellar -------------------------------------------------------------

func cellar_capacity(id := "cellar") -> int:
	var casks: Array = building_info(id).get("casks", [4])
	return int(casks[mini(int(buildings[id]["level"]), casks.size() - 1)])


## A cask's quality from its age: wine must rest before it can be drawn at all, and improves the longer it rests.
func cask_quality(age: float, id := "cellar") -> int:
	var tiers: Array = building_info(id).get("aging", [300, 1200, 3600])
	if age < float(tiers[0]):
		return -1
	return 2 if age >= float(tiers[2]) else (1 if age >= float(tiers[1]) else 0)


func _fill_casks(id: String) -> int:
	var b: Dictionary = buildings[id]
	var filled := 0
	while b["casks"].size() < cellar_capacity(id) and count_item("young_wine") > 0:
		take_items({"young_wine": 1})
		b["casks"].append(0.0)
		filled += 1
	return filled


## Draws every cask that is ready; with only_best, just the excellent ones, as the presser does.
func draw_wine(id := "cellar", only_best := false) -> int:
	var b: Dictionary = buildings[id]
	var kept := []
	var drawn := 0
	for age in b["casks"]:
		var q := cask_quality(float(age), id)
		if q < 0 or (only_best and q < 2) or stored_total() >= storage_capacity():
			kept.append(age)
			continue
		add_item(item_key("aged_wine", q), 1)
		if q == 2:
			discover("milestone:excellent_wine")
		drawn += 1
	b["casks"] = kept
	if drawn > 0 and not quiet:
		building_made.emit(id, "aged_wine", drawn)
	return drawn


func _advance_cellar(id: String, dt: float) -> int:
	var b: Dictionary = buildings[id]
	var rate := 2.0 if blessed("bacchus") else 1.0
	for k in b["casks"].size():
		b["casks"][k] = float(b["casks"][k]) + dt * rate
	if _helper_runs(id):
		_fill_casks(id)
		return draw_wine(id, true)
	return 0


# The barn ---------------------------------------------------------------

func animal_capacity(kind: String, id := "barn") -> int:
	var caps: Array = building_info(id).get("animals", {}).get(kind, [0])
	return int(caps[mini(int(buildings[id]["level"]), caps.size() - 1)])


func barn_room_block(kind: String, id := "barn") -> String:
	if buildings[id]["state"] != "working":
		return "Needs a working barn"
	if int(buildings[id]["animals"].get(kind, 0)) >= animal_capacity(kind, id):
		return "The barn is full"
	return ""


func add_animal(kind: String, id := "barn") -> void:
	buildings[id]["animals"][kind] = int(buildings[id]["animals"].get(kind, 0)) + 1
	discover("animal:" + kind)
	if not quiet:
		animal_added.emit(kind)


func feed_capacity(id := "barn") -> int:
	var caps: Array = building_info(id).get("feed_max", [20])
	return int(caps[mini(int(buildings[id]["level"]), caps.size() - 1)])


func _feed_barn(id: String) -> int:
	var b: Dictionary = buildings[id]
	var fed := 0
	for feed in building_info(id).get("feed", ["straw", "wheat"]):
		while int(b["feed"]) < feed_capacity(id) and count_item(String(feed)) > 0:
			take_items({String(feed): 1})
			b["feed"] = int(b["feed"]) + 1
			fed += 1
	return fed


func _advance_barn(id: String, dt: float) -> int:
	var b: Dictionary = buildings[id]
	if _helper_runs(id) and int(b["feed"]) < feed_capacity(id) / 2:
		_feed_barn(id)
	var herd := 0
	for kind in b["animals"]:
		herd += int(b["animals"][kind])
	if herd == 0:
		return 0
	b["progress"] = float(b["progress"]) + dt * building_speed(id)
	var cycle := float(building_info(id).get("cycle_seconds", 60))
	if b["progress"] < cycle:
		return 0
	var need := ceili(herd / 3.0)
	# Animals are never hungry in a way that hurts: without feed they simply rest and make nothing.
	if int(b["feed"]) < need:
		b["progress"] = cycle
		return 0
	b["progress"] = 0.0
	b["feed"] = int(b["feed"]) - need
	var made := 0
	var makes: Dictionary = building_info(id).get("makes", {})
	for kind in b["animals"]:
		var item := String(makes.get(kind, ""))
		if item != "" and int(b["animals"][kind]) > 0:
			var n := add_item(item, int(b["animals"][kind]))
			made += n
			if n > 0 and not quiet:
				building_made.emit(id, item, n)
	made += add_item("manure", ceili(herd / 2.0))
	return made


# The lararium -----------------------------------------------------------

func gods() -> Dictionary:
	return Balance.get_value("blessings.gods", {})


func offer(god: String) -> bool:
	if buildings.get("lararium", {}).get("state", "") != "working":
		message.emit("Restore the lararium first")
		return false
	if not blessing.is_empty():
		message.emit("A blessing is already with you")
		return false
	if not pay(gods().get(god, {}).get("offering", {})):
		return false
	blessing = {"god": god, "time_left": float(Balance.get_value("blessings.seconds", 1800))}
	add_stat("blessings", 1)
	blessing_started.emit(god)
	return true


# Helpers ----------------------------------------------------------------

func helper_info(id: String) -> Dictionary:
	return Balance.get_value("helpers." + id, {})


## Why a helper cannot be hired yet, or "" when they can.
func helper_block(id: String) -> String:
	var unlock: Dictionary = helper_info(id).get("unlock", {})
	if unlock.has("villa") and villa_stage < int(unlock["villa"]):
		return "Restore the villa first"
	if unlock.has("building") and buildings[unlock["building"]]["state"] != "working":
		return "Repair the %s first" % String(building_info(String(unlock["building"])).get("name", "")).to_lower()
	if unlock.has("purchase") and not market.purchases.has(unlock["purchase"]):
		return "Buy a second cart at the market"
	return ""


## The price of hiring a helper or raising their level, or -1 when there is nothing more to pay for.
func helper_cost(id: String) -> int:
	var costs: Array = helper_info(id).get("costs", [0])
	var level := int(helpers.get(id, 0))
	return int(costs[level]) if level < costs.size() else -1


func hire_helper(id: String) -> bool:
	var cost := helper_cost(id)
	if cost < 0:
		return false
	var block := helper_block(id)
	if block != "":
		message.emit(block)
		return false
	if not pay({"coins": cost}):
		return false
	helpers[id] = int(helpers.get(id, 0)) + 1
	helper_timers[id] = 0.0
	discover("helper:" + id)
	helper_hired.emit(id)
	return true


func _advance_helpers(dt: float) -> int:
	var harvested_now := 0
	for id in helpers:
		var info := helper_info(id)
		if id == "trader":
			_trader_check()
			continue
		if not info.has("zones") and not info.has("crops"):
			continue
		if live_helpers.has(id) and not quiet:
			continue
		var intervals: Array = info.get("intervals", [5])
		var interval := float(intervals[mini(int(helpers[id]) - 1, intervals.size() - 1)])
		helper_timers[id] = float(helper_timers.get(id, 0.0)) - dt
		while float(helper_timers[id]) <= 0.0:
			var i := _ready_plot_for(info)
			if i < 0 or stored_total() >= storage_capacity():
				# Nothing to do, so the helper waits instead of saving up a burst of harvests.
				helper_timers[id] = 0.0
				break
			var crop := String(plots[i]["crop"])
			harvested_now += _harvest(i)
			# Annual crops are replanted straight away, as long as the seed is affordable.
			if plots[i]["crop"] == "" and coins >= int(crop_info(crop).get("plant_cost", 0)):
				coins -= int(crop_info(crop).get("plant_cost", 0))
				plots[i]["crop"] = crop
				_apply_manure(plots[i])
			helper_timers[id] = float(helper_timers[id]) + interval
	return harvested_now


## A helper on screen harvests the plant they walked to, and returns what they picked; annual crops are replanted straight away.
func helper_harvest(id: String, i: int) -> String:
	var info := helper_info(id)
	if i < 0 or not is_ready(i) or stored_total() >= storage_capacity():
		return ""
	var p: Dictionary = plots[i]
	if not ((info.has("zones") and p["zone"] in info["zones"]) or (info.has("crops") and p["crop"] in info["crops"])):
		return ""
	var crop := String(p["crop"])
	var item := String(crop_info(crop).get("item", crop))
	_harvest(i)
	if p["crop"] == "" and coins >= int(crop_info(crop).get("plant_cost", 0)):
		coins -= int(crop_info(crop).get("plant_cost", 0))
		p["crop"] = crop
		_apply_manure(p)
	return item


## How long a helper takes over each plant, from their level.
func helper_interval(id: String) -> float:
	var intervals: Array = helper_info(id).get("intervals", [5])
	return float(intervals[mini(int(helpers.get(id, 1)) - 1, intervals.size() - 1)])


func _ready_plot_for(info: Dictionary) -> int:
	for i in plots.size():
		if not is_ready(i):
			continue
		if info.has("zones") and plots[i]["zone"] in info["zones"]:
			return i
		if info.has("crops") and plots[i]["crop"] in info["crops"]:
			return i
	return -1


## The trader takes the cart out whenever the storehouse holds enough to make the trip worthwhile.
func _trader_check() -> void:
	if cart["away"]:
		return
	var sellable := 0
	for n in sellable_goods().values():
		sellable += int(n)
	if sellable >= mini(cart_capacity(), int(storage_capacity() * float(Balance.get_value("market.trader_fill", 0.6)))):
		send_cart()


# Decorations and the dog ------------------------------------------------

func decoration_info(id: String) -> Dictionary:
	return Balance.get_value("decorations." + id, {})


## Why a decoration cannot be bought, or "" when it can.
func decoration_block(id: String) -> String:
	var d := decoration_info(id)
	if decorations.has(id):
		return "Owned"
	if villa_stage < int(d.get("requires_villa", 0)):
		return "Restore the villa first: %s" % String(villa_stages()[int(d["requires_villa"]) - 1]["name"]).to_lower()
	if d.has("festival") and calendar.festival().get("id", "") != d["festival"] and not journal.has("festival:" + String(d["festival"])):
		return "Sold during %s" % String(d["festival"]).capitalize()
	return ""


func buy_decoration(id: String) -> bool:
	var block := decoration_block(id)
	if block != "":
		message.emit(block)
		return false
	var d := decoration_info(id)
	if not pay({"coins": int(d.get("price", 0)), "aureus": int(d.get("aureus", 0))}):
		return false
	decorations[id] = true
	decoration_bought.emit(id)
	return true


## Called by the scene when the dog is out and about; now and then it digs something up.
func dog_dig() -> String:
	if dog_timer > 0.0:
		return ""
	dog_timer = _next_dog_find()
	var finds: Array = Balance.get_value("dog.finds", []).filter(func(f): return not (f.get("once", false) and journal.has("find:" + String(f["id"]))))
	var total := 0.0
	for f in finds:
		total += float(f["weight"])
	var roll := rng.randf() * total
	for f in finds:
		roll -= float(f["weight"])
		if roll > 0.0:
			continue
		var text := ""
		if f.has("coins"):
			var n := rng.randi_range(int(f["coins"][0]), int(f["coins"][1]))
			coins += n
			text = "%s dug up an old coin: +%d sestertii" % [pet_name("dog"), n]
		elif f.has("item"):
			add_item(String(f["item"]), 1, true)
			text = "%s found a %s!" % [pet_name("dog"), String(Balance.get_value("items.%s.name" % f["item"], f["item"])).to_lower()]
		elif f.has("unlock_crop"):
			unlock_crop(String(f["unlock_crop"]))
			text = "%s dug up a rare seed: white lavender!" % pet_name("dog")
		add_stat("finds", 1)
		discover("find:" + String(f["id"]))
		dog_found.emit(String(f["id"]), text)
		return String(f["id"])
	return ""


static func default_pets() -> Dictionary:
	return {"dog": {"name": "Fidus", "coat": "golden"}, "cat": {"name": "Mica", "coat": "ginger"}}


func pet_name(kind: String) -> String:
	return String(pets.get(kind, {}).get("name", kind.capitalize()))


func _next_dog_find() -> float:
	var r: Array = Balance.get_value("dog.find_seconds", [240, 600])
	return rng.randf_range(float(r[0]), float(r[1]))


# State ------------------------------------------------------------------

func _new_plot(zone: String, is_unlocked: bool) -> Dictionary:
	return {"zone": zone, "unlocked": is_unlocked, "crop": "", "growth": 0.0, "cycle": 0, "manured": false, "ready_age": 0.0}


func _new_building() -> Dictionary:
	return {
		"state": "ruin", "time_left": 0.0, "level": 0, "busy": false, "progress": 0.0, "paused": false,
		"recipe": 0, "queue": [], "batch_q": 0.0, "casks": [], "feed": 0, "animals": {},
	}


func _empty_cart() -> Dictionary:
	return {"away": false, "time_left": 0.0, "items": 0, "value": 0, "load": []}


func to_dict() -> Dictionary:
	return {
		"coins": coins, "aureus": aureus, "selected_seed": selected_seed, "storage": storage, "plots": plots, "levels": levels,
		"crops_unlocked": crops_unlocked, "villa_stage": villa_stage, "villa_build": villa_build, "day_time": day_time,
		"cart": cart, "zones_owned": zones_owned, "buildings": buildings, "helpers": helpers, "helper_timers": helper_timers,
		"decorations": decorations, "pets": pets, "blessing": blessing, "use_manure": use_manure, "stats": stats, "dog_timer": dog_timer,
		"calendar": calendar.to_dict(), "market": market.to_dict(), "journal": journal.to_dict(),
	}


func from_dict(d: Dictionary) -> void:
	new_game()
	coins = int(d.get("coins", coins))
	aureus = int(d.get("aureus", 0))
	selected_seed = String(d.get("selected_seed", selected_seed))
	storage = {}
	for key in d.get("storage", {}):
		storage[key] = int(d["storage"][key])
	var saved: Array = d.get("plots", [])
	for i in mini(saved.size(), plots.size()):
		var s: Dictionary = saved[i]
		var p := _new_plot(String(plots[i]["zone"]), bool(s.get("unlocked", false)))
		p["crop"] = String(s.get("crop", ""))
		p["growth"] = float(s.get("growth", 0.0))
		p["cycle"] = int(s.get("cycle", 0))
		p["manured"] = bool(s.get("manured", false))
		p["ready_age"] = float(s.get("ready_age", 0.0))
		plots[i] = p
	for id in d.get("levels", {}):
		if levels.has(id):
			levels[id] = int(d["levels"][id])
	for c in d.get("crops_unlocked", {}):
		crops_unlocked[c] = true
	villa_stage = int(d.get("villa_stage", 1))
	var vb: Dictionary = d.get("villa_build", {})
	villa_build = {"active": bool(vb.get("active", false)), "time_left": float(vb.get("time_left", 0.0))}
	day_time = float(d.get("day_time", day_time))
	var c: Dictionary = d.get("cart", {})
	cart = {
		"away": bool(c.get("away", false)), "time_left": float(c.get("time_left", 0.0)),
		"items": int(c.get("items", 0)), "value": int(c.get("value", 0)), "load": Array(c.get("load", [])),
	}
	for z in d.get("zones_owned", {}):
		if zones_owned.has(z):
			zones_owned[z] = bool(d["zones_owned"][z])
	for id in d.get("buildings", {}):
		if buildings.has(id):
			var s: Dictionary = d["buildings"][id]
			var b := _new_building()
			for key in b:
				if s.has(key):
					b[key] = s[key]
			b["level"] = int(b["level"])
			b["recipe"] = int(b["recipe"])
			b["feed"] = int(b["feed"])
			b["queue"] = Array(b["queue"])
			b["casks"] = Array(b["casks"])
			b["animals"] = Dictionary(b["animals"])
			buildings[id] = b
	for id in d.get("helpers", {}):
		helpers[id] = int(d["helpers"][id])
	# Saves from before the helpers had names stored the farmhand as an upgrade level.
	if int(d.get("levels", {}).get("farmhand", 0)) > 0 and not helpers.has("farmhand"):
		helpers["farmhand"] = int(d["levels"]["farmhand"])
	for id in d.get("helper_timers", {}):
		helper_timers[id] = float(d["helper_timers"][id])
	decorations = Dictionary(d.get("decorations", {}))
	for kind in d.get("pets", {}):
		pets[kind] = {"name": String(d["pets"][kind].get("name", "")), "coat": String(d["pets"][kind].get("coat", ""))}
	var bl: Dictionary = d.get("blessing", {})
	blessing = {"god": String(bl["god"]), "time_left": float(bl.get("time_left", 0.0))} if bl.has("god") else {}
	use_manure = bool(d.get("use_manure", true))
	for key in d.get("stats", {}):
		stats[key] = int(d["stats"][key])
	# Saves from before the tutorial counted fewer things, so a farm with harvests behind it skips the first lessons.
	if int(stats.get("harvested", 0)) > 0:
		for key in ["planted", "cart_trips"]:
			stats[key] = maxi(int(stats.get(key, 0)), 1)
		var dug := plots.filter(func(p): return p["unlocked"] and p["zone"] == "home").size()
		if dug > int(Balance.get_value("start.unlocked_plots", 4)):
			stats["plots_unlocked"] = maxi(int(stats.get("plots_unlocked", 0)), 1)
	dog_timer = float(d.get("dog_timer", dog_timer))
	calendar.from_dict(d.get("calendar", {}))
	market.from_dict(d.get("market", {}))
	journal.from_dict(d.get("journal", {}))
	journal.add("animal:dog")
	journal.add("animal:donkey")
	for key in storage:
		journal.add("item:" + item_base(key))
	for id in buildings:
		if buildings[id]["state"] == "working":
			journal.add("building:" + id)
	if market.favourites.is_empty():
		market.new_day()
