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
signal helper_trained(helper_id: String, level: int)
signal decoration_bought(decoration_id: String)
signal furnishing_bought(furnishing_id: String)
signal animal_added(kind: String)
signal pets_changed
signal rescued(coins: int)
signal upgrade_bought(upgrade_id: String)
signal upgrade_started(upgrade_id: String)
## A frame long enough to count as time away was caught up, with the same summary a closed game gets on opening.
signal caught_up(summary: Dictionary)

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
## Each building's state: "ruin" (not yet bought), "owned" (bought, still a ruin), "repairing", "working", or
## "upgrading" (builders at work on the next level, with the workshop closed meanwhile).
var buildings := {}
## Hired helpers and their level.
var helpers := {}
var helper_timers := {}
## Helpers walking about on screen, who harvest the plant they actually reach instead of on a timer.
var live_helpers := {}
var decorations := {}
## The furnishings bought for the inside of the farmhouse.
var furnishings := {}
## The farm's dog and cat: the names and coats the player chose for them.
var pets := {}
## What the player named their farm.
var farm_name := ""
## Whether this farm has had its first-day welcome: the choice of pets and Uncle Marcus's greeting.
var intro_seen := false
## False on a new farm until the player has chosen their dog and cat; until then neither is about on the farm.
var pets_chosen := false
## The lararium's blessing in effect, if any.
var blessing := {}
## When on, every planting and regrowth uses one manure from the storehouse.
var use_manure := true
## Goods the player keeps for themselves: the trader leaves them in the storehouse. Keyed by the good's plain name.
var keep_goods := {}
var stats := {}
var calendar: RefCounted
var market: RefCounted
var journal: RefCounted
var rng := RandomNumberGenerator.new()
var dog_timer := 0.0
var _achievement_timer := 0.0
## Debug-only multiplier for live time; offline catch-up always uses real elapsed time.
var speed := 1.0
## How fast repairs and restoration go; the demo farm builds faster for testing. Not saved.
var build_speed := 1.0
## Farm improvements the builders are working on, by upgrade id, with the seconds of work left.
var projects := {}
## Upgrades that are built rather than bought, so they take builders and time.
const BUILT_UPGRADES := ["storage", "channels", "cart_speed"]
## True during offline catch-up, so hundreds of harvests do not each spawn an effect.
var quiet := false
## The goods stored, kept up to date by add_item and remove_key while the estate advances, and -1 otherwise.
var _stored := -1
## Each storage key's good, quality and kind, worked out once.
var _key_info := {}
## Each good's storage keys, from common to excellent.
var _quality_keys := {}
## The wall clock, which keeps running while the computer sleeps; tests swap in their own.
var wall_clock: Callable = Time.get_unix_time_from_system
## The wall clock at the last frame, or 0 when the next frame is the first since the farm was loaded or caught up.
var _last_wall := 0.0
var _dark := 0.0
var _dark_at := -1.0
## The data's tables, kept at hand because the rules read them on every step.
var _crop_data: Dictionary = Data.get_value("crops", {})
var _building_data: Dictionary = Data.get_value("buildings", {})
var _helper_data: Dictionary = Data.get_value("helpers", {})
var _upgrade_data: Dictionary = Data.get_value("upgrades", {})


func _ready() -> void:
	new_game()
	# The seconds spent building a new scene are not time away.
	get_tree().scene_changed.connect(func() -> void: _last_wall = 0.0)


func _process(delta: float) -> void:
	var now: float = wall_clock.call()
	var gap := now - _last_wall
	var first := _last_wall <= 0.0
	_last_wall = now
	# Godot shortens a long frame's delta, so time spent asleep with the game open shows only on the wall clock.
	if not first and gap > float(Data.get_value("offline.long_frame_seconds", 10)) and Settings.offline_progress and Saves.has_farm:
		caught_up.emit(simulate_offline(gap))
	else:
		advance(delta * speed)
	dog_timer -= delta * speed
	_achievement_timer -= delta
	if _achievement_timer <= 0.0:
		_achievement_timer = 1.0
		check_achievements()


func new_game() -> void:
	rng.randomize()
	_last_wall = 0.0
	_stored = -1
	farm_name = ""
	intro_seen = false
	pets_chosen = false
	coins = int(Data.get_value("start.coins", 20))
	aureus = 0
	storage = {}
	plots = []
	var unlocked_count := int(Data.get_value("start.unlocked_plots", 4))
	# Home plots come first, so saves from before the estate grew still line up with the same plots.
	var homes := 0
	for group in Data.get_value("plots.zones", [{"zone": "home", "count": 17}]):
		for k in int(group["count"]):
			var home: bool = group["zone"] == "home"
			plots.append(_new_plot(String(group["zone"]), home and homes < unlocked_count))
			if home:
				homes += 1
	zones_owned = {}
	for z in zones():
		zones_owned[z["id"]] = int(z.get("deed", 0)) == 0
	buildings = {}
	for id in Data.get_value("buildings", {}):
		buildings[id] = _new_building()
	levels = {"storage": 0, "cart_capacity": 0, "cart_speed": 0, "channels": 0}
	projects = {}
	keep_goods = {}
	selected_seed = "lavender"
	crops_unlocked = {}
	for c in Data.get_value("crops", {}):
		if not Data.get_value("crops.%s.locked" % c, false):
			crops_unlocked[c] = true
	villa_stage = 1
	villa_build = {"active": false, "time_left": 0.0}
	day_time = float(Data.get_value("time.start_hour", 16))
	cart = _empty_cart()
	helpers = {}
	helper_timers = {}
	decorations = {}
	furnishings = {}
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
	var name := tr(String(Data.get_value("items.%s.name" % item_base(key), item_base(key))))
	var q := item_quality(key)
	if q == 0:
		return name
	return (tr("Excellent %s") if q == 2 else tr("Fine %s")) % Ui.mid(name)


## The unchanging price of one unit, before the market's daily mood.
func base_price(key: String) -> float:
	var mult: Array = Data.get_value("quality.price", [1, 1.5, 2.5])
	return float(Data.get_value("items.%s.price" % item_base(key), 0)) * float(mult[mini(item_quality(key), mult.size() - 1)])


## Kept for older callers: the market's full price for a good today.
func item_price(key: String) -> int:
	return market.price(key)


func count_item(base: String) -> int:
	if base == "provisions":
		var n := 0
		for p in Data.get_value("provisions", []):
			n += count_item(String(p))
		return n
	var keys: Array = _quality_keys.get(base, [])
	if keys.is_empty():
		keys = [base, item_key(base, 1), item_key(base, 2)]
		_quality_keys[base] = keys
	return int(storage.get(keys[0], 0)) + int(storage.get(keys[1], 0)) + int(storage.get(keys[2], 0))


## Goods in the storehouse; building materials are stacked in the yard and take no room there.
func stored_total() -> int:
	if _stored >= 0:
		return _stored
	var total := 0
	for key in storage:
		if not is_material(key):
			total += int(storage[key])
	return total


func is_material(key: String) -> bool:
	return item_kind(key) == "material"


## What sort of thing a stored good is: "good", "material" or "farm".
func item_kind(key: String) -> String:
	return _info_of(key)[2]


func _info_of(key: String) -> Array:
	var info: Variant = _key_info.get(key)
	if info == null:
		info = [item_base(key), item_quality(key), String(Data.get_value("items.%s.kind" % item_base(key), "good"))]
		_key_info[key] = info
	return info


## Puts goods in the storehouse, as many as fit unless forced, and returns how many went in.
func add_item(key: String, amount: int, force := false) -> int:
	if Data.get_value("items.%s.no_quality" % item_base(key), false):
		key = item_base(key)
	if not force and not is_material(key):
		amount = mini(amount, holding_capacity() - stored_total())
	if amount <= 0:
		return 0
	storage[key] = int(storage.get(key, 0)) + amount
	if _stored >= 0 and not is_material(key):
		_stored += amount
	discover("item:" + item_base(key))
	var q := item_quality(key)
	if q > 0:
		discover("quality:%s:%d" % [item_base(key), q])
		discover("quality:%d" % q)
	return amount


func remove_key(key: String, amount: int) -> void:
	var had := int(storage.get(key, 0))
	storage[key] = had - amount
	if int(storage[key]) <= 0:
		storage.erase(key)
	if _stored >= 0 and not is_material(key):
		_stored += int(storage.get(key, 0)) - had


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
		var bases: Array = Data.get_value("provisions", []) if base == "provisions" else [base]
		var left := int(needs[base])
		for q in 3:
			for b in bases:
				var key := item_key(String(b), q)
				var take := mini(left, int(storage.get(key, 0)))
				if take > 0:
					remove_key(key, take)
					left -= take
					if not Data.get_value("items.%s.no_quality" % b, false):
						quality_sum += q * take
						counted += take
	return quality_sum / counted if counted > 0 else 0.0


## Whether a price can be paid; returns what is missing, or "" when it can.
func missing(cost: Dictionary) -> String:
	if coins < int(cost.get("coins", 0)):
		return tr("Not enough sestertii")
	if aureus < int(cost.get("aureus", 0)):
		return tr("Not enough aurei")
	for key in cost:
		if key in ["coins", "aureus"] or int(cost[key]) <= 0:
			continue
		var short := int(cost[key]) - count_item(String(key))
		if short > 0:
			return tr("Needs %d more %s") % [short, Ui.item_words(String(key), short)]
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
	return _crop_data.get(crop_id, {})


func crop_unlocked(crop_id: String) -> bool:
	return crops_unlocked.has(crop_id)


func unlock_crop(crop_id: String) -> void:
	crops_unlocked[crop_id] = true


func time_to_ready(plot: Dictionary) -> float:
	var info := crop_info(plot["crop"])
	return float(info.get("regrow_seconds" if int(plot["cycle"]) > 0 else "grow_seconds", 60)) * float(plot.get("pace", 1.0))


## Plants are not all alike: each sowing and each regrowth takes a little more or less time than the crop's usual.
func _new_pace() -> float:
	var spread := float(Data.get_value("plots.growth_spread", 0.12))
	return rng.randf_range(1.0 - spread, 1.0 + spread)


func is_ready(i: int) -> bool:
	var p: Dictionary = plots[i]
	return p["unlocked"] and p["crop"] != "" and float(p["growth"]) >= time_to_ready(p)


func growth_fraction(i: int) -> float:
	var p: Dictionary = plots[i]
	if p["crop"] == "":
		return 0.0
	return clampf(float(p["growth"]) / time_to_ready(p), 0.0, 1.0)


func watered(i: int) -> bool:
	return calendar.wet() or (plots[i]["zone"] == "home" and upgrade_value("channels") > 0.0)


## How fast a plot grows right now: the season, water, manure and the gods all play a part.
## The young woman of the market town expecting a child: how far along she is, from the calendar. "expecting" grows
## from 0 to 1 over the days before the birth, and then she carries the baby for a while.
func baby_story() -> Dictionary:
	var story: Dictionary = Data.get_value("story.baby", {})
	if story.is_empty():
		return {"stage": "none"}
	var days := float(calendar.day) + day_time / 24.0 - float(story.get("starts_day", 3))
	var expecting := float(story.get("expecting_days", 8))
	if days < 0.0:
		return {"stage": "none"}
	if days < expecting:
		return {"stage": "expecting", "share": days / expecting}
	if days < expecting + float(story.get("baby_days", 6)):
		if not stats.has("baby_born"):
			stats["baby_born"] = 1
			if not quiet:
				message.emit(TranslationServer.translate("%s in the market town has had %s!") % [story.get("who", "Julia"), TranslationServer.translate(String(story.get("child", "a baby girl")))])
		return {"stage": "baby"}
	return {"stage": "none"}


## Night falls once the light is mostly gone; people go home, building work stops and plants grow slowly.
func is_night() -> bool:
	return night_amount() > 0.5


## How dark it is now, from 0 by day to 1 at night; worked out again only when the clock has moved.
func night_amount() -> float:
	if day_time != _dark_at:
		_dark_at = day_time
		_dark = Lighting.night_amount(day_time)
	return _dark


## How long until night ends, in seconds as they pass on the clock.
func seconds_until_day() -> float:
	var hours := 0.0
	while hours < 24.0 and Lighting.night_amount(fposmod(day_time + hours, 24.0)) > 0.5:
		hours += 0.05
	return hours / 24.0 * day_seconds() / maxf(speed, 1.0)


func growth_rate(i: int) -> float:
	var p: Dictionary = plots[i]
	if p.get("first", false):
		return 1.0
	var info := crop_info(p["crop"])
	var rate := float(info.get("seasons", {}).get(calendar.season_id(), 1.0))
	# Plants keep growing in the dark, but at about a third of their daytime pace.
	rate *= 1.0 - 0.65 * night_amount()
	if not watered(i):
		rate *= float(Data.get_value("calendar.dry_growth", 0.8))
	if p.get("manured", false):
		rate *= float(Data.get_value("calendar.manure_growth", 1.25))
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
	var extra := unlocked_count - int(Data.get_value("start.unlocked_plots", 4))
	var base := float(Data.get_value("plots.unlock_cost_base", 15))
	return int(round(base * pow(float(Data.get_value("plots.unlock_cost_growth", 1.3)), maxi(extra, 0))))


## The parts of the estate a crop can be planted in: lavender grows on the farm and in the grove, olives only in the grove.
func crop_zones(crop_id: String) -> Array:
	var info := crop_info(crop_id)
	return info.get("zones", [info.get("zone", "home")])


## The crop an empty plot gets: the chosen seed when it grows in that zone, otherwise the zone's own crop.
## The chosen seed, if it can grow in this plot's part of the estate; otherwise nothing is planted.
func seed_for_plot(i: int) -> String:
	var zone := String(plots[i]["zone"])
	if zone in crop_zones(selected_seed) and crop_unlocked(selected_seed):
		return selected_seed
	return ""


## Why the chosen seed cannot go in this plot, in words for the player.
func seed_block(i: int) -> String:
	if not crop_unlocked(selected_seed):
		return "Buy cuttings for this land at the market"
	var where := tr(" or ").join(crop_zones(selected_seed).map(func(z): return Ui.mid(tr(String(zone_info(z).get("name", ""))))))
	return tr("%s grows on the %s: choose another seed for this land") % [tr(String(crop_info(selected_seed).get("name", selected_seed))), where]


func try_plant(i: int, crop_id := "") -> bool:
	var p: Dictionary = plots[i]
	if crop_id == "":
		crop_id = seed_for_plot(i)
	if crop_id == "":
		message.emit(seed_block(i))
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
	p["pace"] = _new_pace()
	# The very first plant on a farm blooms within seconds, so a new player sees a harvest before their attention drifts.
	if int(stats.get("planted", 0)) == 0:
		p["pace"] = float(Data.get_value("plots.first_crop_seconds", 12)) / float(crop_info(crop_id).get("grow_seconds", 60))
		p["first"] = true
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
	p.erase("first")
	dug_up.emit(i)
	return true


func try_harvest(i: int) -> bool:
	if not is_ready(i):
		return false
	if not harvest_fits(i):
		storage_full.emit()
		return false
	_harvest(i, true)
	return true


## How many goods a ripe plant gives when it is picked.
func harvest_amount(i: int) -> int:
	var p: Dictionary = plots[i]
	var amount := int(crop_info(p["crop"]).get("yield", 1))
	if p["crop"] == "olives" and blessed("minerva"):
		amount += 1
	return amount


## Whether the farm has room for a ripe plant's whole yield; a plant that does not fit stays ripe until there is.
func harvest_fits(i: int) -> bool:
	return stored_total() + harvest_amount(i) <= holding_capacity()


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
	var key := item_key(base, _harvest_quality(i, by_hand))
	var amount := add_item(key, harvest_amount(i))
	p["growth"] = 0.0
	p["ready_age"] = 0.0
	p["cycle"] = int(p["cycle"]) + 1
	p["manured"] = false
	p["pace"] = _new_pace()
	p.erase("first")
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
	if Data.get_value("items.%s.no_quality" % String(crop_info(p["crop"]).get("item", "")), false):
		return 0
	var points := 0.0
	if p.get("manured", false):
		points += 1.0
	if watered(i):
		points += 0.5
	if by_hand and float(p.get("ready_age", 0.0)) <= float(Data.get_value("quality.timely_seconds", 20)):
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
	return _upgrade_data.get(id, {})


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


## Everything the farm can hold right now. A parked cart is loaded with goods waiting for market, so its space adds
## to the storehouse's; while it is away on the road, only the storehouse holds anything.
func holding_capacity() -> int:
	return storage_capacity() + (0 if cart["away"] else cart_capacity())


## How the goods held split between the storehouse and the parked cart: the storehouse fills first, the rest is on
## the cart.
func in_storehouse() -> int:
	return mini(stored_total(), storage_capacity())


func on_cart() -> int:
	return 0 if cart["away"] else maxi(0, stored_total() - storage_capacity())


func cart_trip_seconds() -> float:
	return upgrade_value("cart_speed")


func buy_upgrade(id: String) -> bool:
	var cost := upgrade_cost(id)
	if cost < 0:
		return false
	if coins < cost:
		message.emit("Not enough sestertii")
		return false
	if projects.has(id):
		message.emit("The builders are already at work on it")
		return false
	coins -= cost
	if id in BUILT_UPGRADES:
		projects[id] = upgrade_seconds(id)
		if not quiet:
			upgrade_started.emit(id)
		if float(projects[id]) <= 0.0:
			_finish_project(id)
		return true
	levels[id] = int(levels.get(id, 0)) + 1
	if not quiet:
		upgrade_bought.emit(id)
	return true


## How long builders take over the next level of a built upgrade.
func upgrade_seconds(id: String) -> float:
	var times: Array = upgrade_info(id).get("seconds", [])
	var level := int(levels.get(id, 0))
	return float(times[mini(level, times.size() - 1)]) if not times.is_empty() else 60.0 * (level + 1)


func _finish_project(id: String) -> void:
	projects.erase(id)
	levels[id] = int(levels.get(id, 0)) + 1
	if not quiet:
		upgrade_bought.emit(id)


func villa_stages() -> Array:
	return Data.get_value("villa.stages", [])


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
		if not quiet:
			message.emit("Nothing marked for sale in the storehouse")
		return false
	cart = {"away": true, "time_left": cart_trip_seconds(), "items": loaded, "value": value, "load": taken.slice(0, 4)}
	add_stat("cart_trips", 1)
	if not quiet:
		cart_left.emit(loaded, value)
	return true


# Time -------------------------------------------------------------------

## Moves the estate forward by dt seconds and reports what happened.
func advance(dt: float) -> Dictionary:
	var result := {"harvested": 0, "earned": 0, "made": 0}
	var counting := _stored < 0
	if counting:
		_stored = stored_total()
	calendar.advance(dt)
	market.advance(dt)
	result["made"] = _advance_buildings(dt)
	var before := day_time
	day_time = fmod(day_time + dt * 24.0 / day_seconds(), 24.0)
	if day_time < before:
		calendar.next_day()
		market.new_day()
	if not is_night():
		for id in projects.keys():
			projects[id] = float(projects[id]) - dt * build_speed
			if float(projects[id]) <= 0.0:
				_finish_project(id)
	if villa_build["active"] and not is_night():
		villa_build["time_left"] = float(villa_build["time_left"]) - dt * build_speed
		if villa_build["time_left"] <= 0.0:
			_finish_villa()
	if not blessing.is_empty():
		blessing["time_left"] = float(blessing["time_left"]) - dt
		if blessing["time_left"] <= 0.0:
			blessing = {}
	var ripe := []
	for i in plots.size():
		var p: Dictionary = plots[i]
		if p["unlocked"] and p["crop"] != "":
			var need := time_to_ready(p)
			if float(p["growth"]) >= need:
				p["ready_age"] = float(p.get("ready_age", 0.0)) + dt
			else:
				p["growth"] = minf(float(p["growth"]) + dt * growth_rate(i), need)
			if float(p["growth"]) >= need:
				ripe.append(i)
	var spare := 0.0
	if cart["away"]:
		cart["time_left"] = float(cart["time_left"]) - dt
		if cart["time_left"] <= 0.0:
			spare = -float(cart["time_left"])
			var value := int(cart["value"])
			coins += value
			add_stat("earned", value)
			result["earned"] += value
			cart = _empty_cart()
			if not quiet:
				cart_returned.emit(value)
	result["harvested"] += _advance_helpers(dt, ripe)
	# A trader who set out again in this step has already been on the road for the part of it after the cart came home.
	if spare > 0.0 and cart["away"]:
		cart["time_left"] = float(cart["time_left"]) - spare
	_rescue_if_stranded()
	if counting:
		_stored = -1
	return result


## True when the purse cannot pay for the farm's first crop, lavender, and nothing is planted anywhere. A cheaper seed
## such as wheat may still be affordable, but a new player thinks of lavender, so this is when they feel stuck.
func short_of_seed() -> bool:
	if coins >= int(crop_info(String(Data.get_value("start.seed", "lavender"))).get("plant_cost", 0)):
		return false
	for p in plots:
		if p["crop"] != "":
			return false
	return true


## A farm short of a seed with nothing to sell and nothing on its way could never earn again, so Uncle Marcus gives a
## few sestertii to start over. In ordinary play this never happens.
func _rescue_if_stranded() -> void:
	# Uncle Marcus comes by once the player is back, so his gift is kept in full rather than counted as time-away earnings.
	if quiet or not short_of_seed() or stored_total() > 0 or cart["away"]:
		return
	for id in buildings:
		if buildings[id].get("busy", false):
			return
	var gift := int(Data.get_value("start.rescue_coins", 10))
	coins += gift
	rescued.emit(gift)


## Catches up on time the game was closed, in small steps so every rule applies in order. The farm runs as usual, but
## only a share of what it earns is kept, so coming back is a welcome bonus rather than a way to skip the game.
func simulate_offline(seconds: float) -> Dictionary:
	var remaining := minf(seconds, float(Data.get_value("offline.max_hours", 12)) * 3600.0)
	var step := float(Data.get_value("offline.step_seconds", 5))
	var start_coins := coins
	# A cart already on the road was loaded and sold in play, so it pays in full when it comes home.
	var on_road: bool = cart["away"]
	var paid_in_full := 0
	var summary := {"seconds": remaining, "harvested": 0, "earned": 0, "made": 0}
	quiet = true
	_stored = -1
	_stored = stored_total()
	while remaining > 0.0:
		var dt := minf(step, remaining)
		var r := advance(dt)
		summary["harvested"] += r["harvested"]
		summary["made"] += r["made"]
		if on_road and int(r["earned"]) > 0:
			paid_in_full = int(r["earned"])
			on_road = false
		remaining -= dt
	_stored = -1
	quiet = false
	var earned := coins - start_coins - paid_in_full
	if earned > 0:
		var forgone := earned - int(earned * float(Data.get_value("offline.earnings_share", 0.25)))
		coins -= forgone
		stats["earned"] = int(stats.get("earned", 0)) - forgone
	summary["earned"] = coins - start_coins
	summary["ready"] = 0
	for i in plots.size():
		if is_ready(i):
			summary["ready"] += 1
	summary["storage_full"] = stored_total() >= holding_capacity()
	_last_wall = 0.0
	return summary


## Real seconds in one in-game day, as the player has set it.
func day_seconds() -> float:
	return float(Settings.day_minutes) * 60.0 if Settings.day_minutes > 0 else float(Data.get_value("time.day_seconds", 1200))


func blessed(god: String) -> bool:
	return blessing.get("god", "") == god


# Estate -----------------------------------------------------------------

func zones() -> Array:
	return Data.get_value("estate.zones", [])


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
	if is_demo() and not zone_id in Data.get_value("demo.zones", []):
		return "Available in the full game"
	var needs := int(z.get("requires_villa", 0))
	if villa_stage < needs:
		return tr("Restore the villa first: %s") % Ui.mid(tr(String(villa_stages()[needs - 1]["name"])))
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
	return is_demo() and villa_stage >= int(Data.get_value("demo.max_villa", 3))


# Buildings --------------------------------------------------------------

func building_info(id: String) -> Dictionary:
	return _building_data.get(id, {})


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
	var level := building_level_info(id)
	return int(level["queue"]) if level.has("queue") else int(building_info(id).get("queue", 2))


func working_buildings() -> int:
	return buildings.values().filter(func(b): return b["state"] == "working").size()


## The recipes a building can use now; later villa stages unlock some.
func recipes(id: String) -> Array:
	var all: Array = building_info(id).get("recipes", [])
	for r in all:
		if int(r.get("requires_villa", 0)) > villa_stage:
			return all.filter(func(x): return int(x.get("requires_villa", 0)) <= villa_stage)
	return all.duplicate()


func current_recipe(id: String) -> Dictionary:
	var list := recipes(id)
	return list[clampi(int(buildings[id]["recipe"]), 0, list.size() - 1)] if not list.is_empty() else {}


## Where the chosen recipe sits in the building's full list; a queued batch keeps this, since that list never shifts.
func _recipe_slot(id: String) -> int:
	return maxi(0, building_info(id).get("recipes", []).find(current_recipe(id)))


## The recipe of the batch a workshop is making: the one it was loaded with, even if the player has chosen another since.
func batch_recipe(id: String) -> Dictionary:
	var all: Array = building_info(id).get("recipes", [])
	var slot := int(buildings[id].get("batch_recipe", -1))
	return all[slot] if buildings[id]["busy"] and slot >= 0 and slot < all.size() else current_recipe(id)


## A queued batch as its quality and recipe. An older save's batch is only its quality, so it uses the recipe chosen now.
func _batch_entry(id: String, e: Variant) -> Dictionary:
	var entry: Dictionary = e if e is Dictionary else {"quality": float(e)}
	return {"quality": float(entry.get("quality", 0.0)), "recipe": int(entry.get("recipe", _recipe_slot(id)))}


## How much work the batch a workshop is making takes, in seconds at the building's first level.
func batch_seconds(id: String) -> float:
	return float(batch_recipe(id).get("seconds", 30))


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
		return tr("Restore the villa first: %s") % Ui.mid(tr(String(villa_stages()[needs - 1]["name"])))
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
			b["state"] = "upgrading"
			b["time_left"] = building_upgrade_seconds(id)
	building_changed.emit(id)
	return true


## How long builders take over a building's next level: a set time from the data, or half its repair time for each
## level it already has.
func building_upgrade_seconds(id: String) -> float:
	var info := building_info(id)
	var levels_info: Array = info.get("levels", [])
	var level := int(buildings[id]["level"])
	if level < levels_info.size() and levels_info[level].has("seconds"):
		return float(levels_info[level]["seconds"])
	return float(info.get("repair_seconds", 30)) * 0.5 * (level + 1)


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


## Whether the trader may take a good to market; the player marks goods they want to keep.
func for_sale(key: String) -> bool:
	return not keep_goods.has(item_base(key))


func set_for_sale(key: String, sell: bool) -> void:
	if sell:
		keep_goods.erase(item_base(key))
	else:
		keep_goods[item_base(key)] = true


## Goods the player has a use for, which the hired trader leaves at home: the provisions for the villa's next stage, one
## of each offering once the shrine stands, and what the open market orders ask for. "provisions" is any bread or wine.
## Before the trader is hired the player loads the cart themselves, so nothing is held back from what they send.
func needed_goods() -> Dictionary:
	var need := {}
	if not helpers.has("trader"):
		return need
	var provisions := int(villa_next_price().get("provisions", 0))
	if provisions > 0:
		need["provisions"] = provisions
	if buildings.get("lararium", {}).get("state", "") == "working":
		for god in gods().values():
			for item in god.get("offering", {}):
				need[item] = maxi(int(need.get(item, 0)), int(god["offering"][item]))
	for o in market.orders:
		need[o["item"]] = int(need.get(o["item"], 0)) + int(o["amount"])
	return need


## Goods the trader may take, by storage key: goods marked for sale, less what the workshops and the player need.
## The plainest units are the ones kept, since workshops use those first, so the better ones go to market.
func sellable_goods() -> Dictionary:
	# A nearly full storehouse sells the workshops' share too, so goods kept for them can never jam the farm.
	var keep := reserved_amounts() if stored_total() < storage_capacity() * 0.9 else {}
	var need := needed_goods()
	# What the player needs is held back up to half the storehouse, so it cannot fill the storehouse either.
	var room := storage_capacity() / 2
	var provision_bases: Array = Data.get_value("provisions", [])
	var out := {}
	var by_quality := [[], [], []]
	for key in storage:
		var info := _info_of(key)
		if info[2] == "good" and not keep_goods.has(info[0]) and info[1] < 3:
			by_quality[info[1]].append(key)
	for q in 3:
		for key in by_quality[q]:
			var base := item_base(key)
			var left := int(storage[key])
			var kept := mini(int(keep.get(base, 0)), left)
			keep[base] = int(keep.get(base, 0)) - kept
			left -= kept
			for pool in [base, "provisions"] if base in provision_bases else [base]:
				var held := mini(mini(int(need.get(pool, 0)), left), room)
				need[pool] = int(need.get(pool, 0)) - held
				room -= held
				left -= held
			if left > 0:
				out[key] = left
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
	return _load_workshop(id, current_recipe(id))


func _load_workshop(id: String, r: Dictionary) -> int:
	var b: Dictionary = buildings[id]
	var needs := {}
	for item in r.get("in", {}):
		needs[item] = int(r["in"][item]) * building_batch(id)
	var loaded := 0
	var queue_max := building_queue_max(id)
	while b["queue"].size() < queue_max and has_items(needs) and not needs.is_empty():
		b["queue"].append({"quality": take_items(needs), "recipe": _recipe_slot(id)})
		loaded += 1
	return loaded


func _helper_runs(id: String) -> bool:
	var helper := String(building_info(id).get("helper", ""))
	return helper != "" and helpers.has(helper)


## Whether a building's helper loads it on their own now: only by day, and not while they are on screen carrying the
## goods there by hand.
func _helper_loads(id: String) -> bool:
	return _helper_runs(id) and not is_night() and not (live_helpers.has(String(building_info(id).get("helper", ""))) and not quiet)


## What a helper would carry to this building now, or "" when it needs nothing the storehouse has.
func load_need(id: String) -> String:
	var b: Dictionary = buildings[id]
	if b["state"] != "working" or b["paused"]:
		return ""
	match building_kind(id):
		"cellar":
			return "young_wine" if b["casks"].size() < cellar_capacity(id) and count_item("young_wine") > 0 else ""
		"barn":
			if int(b["feed"]) >= feed_capacity(id) / 2:
				return ""
			for feed in building_info(id).get("feed", ["straw", "wheat"]):
				if count_item(String(feed)) > 0:
					return String(feed)
			return ""
		"shrine":
			return ""
	var r := current_recipe(id)
	var needs := {}
	for item in r.get("in", {}):
		needs[item] = int(r["in"][item]) * building_batch(id)
	if needs.is_empty() or b["queue"].size() >= building_queue_max(id) or not has_items(needs):
		return ""
	# The ingredient most of the batch is made of is the one seen being carried.
	var main := ""
	for item in needs:
		if main == "" or int(needs[item]) > int(needs[main]):
			main = String(item)
	return main


func _advance_buildings(dt: float) -> int:
	var made := 0
	for id in buildings:
		var b: Dictionary = buildings[id]
		if b["state"] == "repairing" or b["state"] == "upgrading":
			if is_night():
				continue
			b["time_left"] = float(b["time_left"]) - dt * build_speed
			if b["time_left"] <= 0.0:
				if b["state"] == "upgrading":
					b["level"] = int(b["level"]) + 1
				b["state"] = "working"
				discover("building:" + id)
				if not quiet:
					building_changed.emit(id)
			continue
		if b["state"] != "working" or b["paused"]:
			continue
		# Bees only fly by day, so the hives make nothing at night.
		if building_info(id).get("day_only", false) and is_night():
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
		made += _advance_workshop(id, dt)
	return made


## Works a workshop's batches; work past a batch's end goes on to the next, so long catch-up steps make as much as play.
func _advance_workshop(id: String, dt: float) -> int:
	var b: Dictionary = buildings[id]
	var made := 0
	var work := dt * building_speed(id)
	var queue_max := building_queue_max(id)
	var batch := building_batch(id)
	while true:
		var r := current_recipe(id)
		if r.is_empty():
			return made
		if r.get("in", {}).is_empty():
			# Bees need nobody: hives fill their own queue.
			while b["queue"].size() < queue_max:
				b["queue"].append({"quality": 0.0, "recipe": _recipe_slot(id)})
		elif b["queue"].size() < queue_max and _helper_loads(id):
			_load_workshop(id, r)
		if not b["busy"]:
			if b["queue"].is_empty():
				return made
			var next := _batch_entry(id, b["queue"].pop_front())
			b["batch_q"] = float(next["quality"])
			b["batch_recipe"] = int(next["recipe"])
			b["busy"] = true
			b["progress"] = 0.0
		var run := batch_recipe(id)
		var seconds := float(run.get("seconds", 30))
		var left := seconds - float(b["progress"])
		if work < left:
			b["progress"] = float(b["progress"]) + work
			return made
		work -= maxf(left, 0.0)
		b["progress"] = seconds
		var amount := 0
		for item in run.get("out", {}):
			amount += int(run["out"][item]) * batch
		# A finished batch waits in the building until the storehouse has room for it.
		if stored_total() + amount > holding_capacity():
			return made
		var out := {}
		for item in run.get("out", {}):
			var name := String(item)
			if name == "honey" and run.get("lavender_honey", false) and _lavender_in_bloom():
				name = "lavender_honey"
			out[name] = int(run["out"][item]) * batch
		var q := clampi(int(round(float(b["batch_q"]))) + int(building_level_info(id).get("quality", 0)), 0, 2)
		for item in out:
			add_item(item_key(item, q), int(out[item]))
			if not quiet:
				building_made.emit(id, item, int(out[item]))
		made += amount
		b["busy"] = false
		b["progress"] = 0.0
		if work <= 0.0:
			return made
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
	var room := holding_capacity() - stored_total()
	for age in b["casks"]:
		var q := cask_quality(float(age), id)
		if q < 0 or (only_best and q < 2) or room <= 0:
			kept.append(age)
			continue
		add_item(item_key("aged_wine", q), 1)
		room -= 1
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
		if _helper_loads(id):
			_fill_casks(id)
		return draw_wine(id, true) if not is_night() else 0
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
	if _helper_loads(id) and int(b["feed"]) < feed_capacity(id) / 2:
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
	var makes: Dictionary = building_info(id).get("makes", {})
	var goods := {}
	var amount := 0
	for kind in b["animals"]:
		var item := String(makes.get(kind, ""))
		if item != "" and int(b["animals"][kind]) > 0:
			goods[item] = int(goods.get(item, 0)) + int(b["animals"][kind])
			amount += int(b["animals"][kind])
	var need := ceili(herd / 3.0)
	# Animals are never hungry in a way that hurts: without feed, or without room for their eggs and milk, they rest.
	if int(b["feed"]) < need or stored_total() + amount > holding_capacity():
		b["progress"] = cycle
		return 0
	b["progress"] = float(b["progress"]) - cycle
	b["feed"] = int(b["feed"]) - need
	var q := clampi(int(building_level_info(id).get("quality", 0)), 0, 2)
	for item in goods:
		add_item(item_key(item, q), int(goods[item]))
		if not quiet:
			building_made.emit(id, item, int(goods[item]))
	return amount + add_item("manure", mini(ceili(herd / 2.0), manure_room(id)))


func manure_cap(id := "barn") -> int:
	return int(building_info(id).get("manure_max", 10))


## How much more manure the storehouse takes. It keeps only a few loads for planting, and none while manure is not used.
func manure_room(id := "barn") -> int:
	return maxi(0, manure_cap(id) - count_item("manure")) if use_manure else 0


# The lararium -----------------------------------------------------------

func gods() -> Dictionary:
	return Data.get_value("blessings.gods", {})


func offer(god: String) -> bool:
	if buildings.get("lararium", {}).get("state", "") != "working":
		message.emit("Restore the lararium first")
		return false
	if not blessing.is_empty():
		message.emit("A blessing is already with you")
		return false
	if not pay(gods().get(god, {}).get("offering", {})):
		return false
	blessing = {"god": god, "time_left": float(Data.get_value("blessings.seconds", 1800))}
	add_stat("blessings", 1)
	blessing_started.emit(god)
	return true


# Helpers ----------------------------------------------------------------

func helper_info(id: String) -> Dictionary:
	return _helper_data.get(id, {})


## Why a helper cannot be hired yet, or "" when they can.
func helper_block(id: String) -> String:
	var unlock: Dictionary = helper_info(id).get("unlock", {})
	if unlock.has("villa") and villa_stage < int(unlock["villa"]):
		return "Restore the villa first"
	if unlock.has("building") and buildings[unlock["building"]]["state"] != "working":
		return tr("Repair the %s first") % Ui.mid(tr(String(building_info(String(unlock["building"])).get("name", ""))))
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
	if helpers[id] == 1:
		helper_hired.emit(id)
	else:
		helper_trained.emit(id, helpers[id])
	return true


func _advance_helpers(dt: float, ripe: Array) -> int:
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
		# Helpers go home at night, so nothing is picked until morning.
		if is_night():
			helper_timers[id] = 0.0
			continue
		var intervals: Array = info.get("intervals", [5])
		var interval := float(intervals[mini(int(helpers[id]) - 1, intervals.size() - 1)]) / comfort_factor()
		helper_timers[id] = float(helper_timers.get(id, 0.0)) - dt
		while float(helper_timers[id]) <= 0.0:
			var i := _ready_plot_for(info, ripe)
			if i < 0:
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
	if i < 0 or not is_ready(i) or not harvest_fits(i):
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
	return float(intervals[mini(int(helpers.get(id, 1)) - 1, intervals.size() - 1)]) / comfort_factor()


## The first of the plants ripe this step that a helper looks after, still unpicked and whose whole yield fits, or -1.
func _ready_plot_for(info: Dictionary, ripe: Array) -> int:
	var room := holding_capacity() - stored_total()
	if room <= 0:
		return -1
	for i in ripe:
		var p: Dictionary = plots[i]
		var theirs: bool = (info.has("zones") and p["zone"] in info["zones"]) or (info.has("crops") and p["crop"] in info["crops"])
		if theirs and is_ready(i) and harvest_amount(i) <= room:
			return i
	return -1


## The trader takes the cart out whenever the storehouse holds enough to make the trip worthwhile.
func _trader_check() -> void:
	# The donkey spends the night in the barn, and the cart stays put while the player sells from it in town.
	if cart["away"] or is_night() or market.cart_in_town:
		return
	var worth := mini(cart_capacity(), int(storage_capacity() * float(Data.get_value("market.trader_fill", 0.6))))
	# Only part of what is stored can be sold, so a storehouse holding less than a cartload cannot fill one.
	if stored_total() < worth:
		return
	var sellable := 0
	for n in sellable_goods().values():
		sellable += int(n)
	if sellable >= worth:
		send_cart()


# Decorations and the dog ------------------------------------------------

func decoration_info(id: String) -> Dictionary:
	return Data.get_value("decorations." + id, {})


## Why a decoration cannot be bought, or "" when it can.
func decoration_block(id: String) -> String:
	var d := decoration_info(id)
	if decorations.has(id):
		return "Owned"
	if villa_stage < int(d.get("requires_villa", 0)):
		return tr("Restore the villa first: %s") % Ui.mid(tr(String(villa_stages()[int(d["requires_villa"]) - 1]["name"])))
	if not zone_owned(String(d.get("zone", "home"))):
		return "Buy this land first"
	if d.has("festival") and calendar.festival().get("id", "") != d["festival"] and not journal.has("festival:" + String(d["festival"])):
		return tr("Sold during %s") % tr(String(d["festival"]).capitalize())
	return ""


## The farmhouse's furnishings ------------------------------------------

func furnishing_info(id: String) -> Dictionary:
	return Data.get_value("interior.furnishings." + id, {})


## Why a furnishing cannot be bought, or "" when it can.
func furnishing_block(id: String) -> String:
	var f := furnishing_info(id)
	if furnishings.has(id):
		return "Already in the house"
	if villa_stage < int(f.get("requires_villa", 2)):
		return tr("Restore the villa first: %s") % Ui.mid(tr(String(villa_stages()[int(f.get("requires_villa", 2)) - 1]["name"])))
	return ""


func buy_furnishing(id: String) -> bool:
	var block := furnishing_block(id)
	if block != "":
		message.emit(block)
		return false
	if not pay({"coins": int(furnishing_info(id).get("price", 0))}):
		return false
	furnishings[id] = true
	furnishing_bought.emit(id)
	check_achievements()
	return true


## How much quicker the helpers work for a comfortable home: each furnishing adds a little.
func comfort_factor() -> float:
	return 1.0 + float(Data.get_value("interior.comfort_speed", 0.02)) * furnishings.size()


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
	var finds: Array = Data.get_value("dog.finds", []).filter(func(f): return not (f.get("once", false) and journal.has("find:" + String(f["id"]))))
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
			text = tr("%s dug up an old coin: +%d sestertii") % [pet_name("dog"), n]
		elif f.has("item"):
			add_item(String(f["item"]), 1, true)
			text = tr("%s found a %s!") % [pet_name("dog"), Ui.mid(tr(String(Data.get_value("items.%s.name" % f["item"], f["item"]))))]
		elif f.has("unlock_crop"):
			unlock_crop(String(f["unlock_crop"]))
			text = tr("%s dug up a rare seed: white lavender!") % pet_name("dog")
		add_stat("finds", 1)
		discover("find:" + String(f["id"]))
		dog_found.emit(String(f["id"]), text)
		return String(f["id"])
	return ""


static func default_pets() -> Dictionary:
	return {"dog": {"name": "Fidus", "coat": "golden", "breed": "hound"}, "cat": {"name": "Mica", "coat": "ginger", "breed": "tabby"}}


func pet_name(kind: String) -> String:
	return String(pets.get(kind, {}).get("name", kind.capitalize()))


func _next_dog_find() -> float:
	var r: Array = Data.get_value("dog.find_seconds", [240, 600])
	return rng.randf_range(float(r[0]), float(r[1]))


# State ------------------------------------------------------------------

func _new_plot(zone: String, is_unlocked: bool) -> Dictionary:
	return {"zone": zone, "unlocked": is_unlocked, "crop": "", "growth": 0.0, "cycle": 0, "manured": false, "ready_age": 0.0}


func _new_building() -> Dictionary:
	return {
		"state": "ruin", "time_left": 0.0, "level": 0, "busy": false, "progress": 0.0, "paused": false,
		"recipe": 0, "queue": [], "batch_q": 0.0, "batch_recipe": -1, "casks": [], "feed": 0, "animals": {},
	}


func _empty_cart() -> Dictionary:
	return {"away": false, "time_left": 0.0, "items": 0, "value": 0, "load": []}


func to_dict() -> Dictionary:
	return {
		"keep_goods": keep_goods, "projects": projects, "farm_name": farm_name, "intro_seen": intro_seen, "pets_chosen": pets_chosen,
		"coins": coins, "aureus": aureus, "selected_seed": selected_seed, "storage": storage, "plots": plots, "levels": levels,
		"crops_unlocked": crops_unlocked, "villa_stage": villa_stage, "villa_build": villa_build, "day_time": day_time,
		"cart": cart, "zones_owned": zones_owned, "buildings": buildings, "helpers": helpers, "helper_timers": helper_timers,
		"decorations": decorations, "furnishings": furnishings, "pets": pets, "blessing": blessing, "use_manure": use_manure, "stats": stats, "dog_timer": dog_timer,
		"calendar": calendar.to_dict(), "market": market.to_dict(), "journal": journal.to_dict(),
	}


func from_dict(d: Dictionary) -> void:
	new_game()
	farm_name = String(d.get("farm_name", ""))
	# Farms saved before the welcome was kept per farm had already been opened and played.
	intro_seen = bool(d.get("intro_seen", true))
	pets_chosen = bool(d.get("pets_chosen", true))
	coins = int(d.get("coins", coins))
	aureus = int(d.get("aureus", 0))
	keep_goods = {}
	for base in d.get("keep_goods", {}):
		keep_goods[base] = true
	projects = {}
	for id in d.get("projects", {}):
		projects[id] = float(d["projects"][id])
	selected_seed = String(d.get("selected_seed", selected_seed))
	storage = {}
	for key in d.get("storage", {}):
		storage[key] = int(d["storage"][key])
	if count_item("manure") > manure_cap():
		remove_key("manure", count_item("manure") - manure_cap())
	var saved: Array = d.get("plots", [])
	for i in mini(saved.size(), plots.size()):
		var s: Dictionary = saved[i]
		var p := _new_plot(String(plots[i]["zone"]), bool(s.get("unlocked", false)))
		p["crop"] = String(s.get("crop", ""))
		p["growth"] = float(s.get("growth", 0.0))
		p["cycle"] = int(s.get("cycle", 0))
		p["manured"] = bool(s.get("manured", false))
		p["ready_age"] = float(s.get("ready_age", 0.0))
		p["pace"] = float(s.get("pace", 1.0))
		if s.get("first", false):
			p["first"] = true
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
	# Beds added to the estate since the save are ready to plant in land the family already owns.
	for p in plots:
		if p["zone"] != "home" and zones_owned.get(p["zone"], false):
			p["unlocked"] = true
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
			b["casks"] = Array(b["casks"])
			b["animals"] = Dictionary(b["animals"])
			buildings[id] = b
			b["batch_recipe"] = int(s.get("batch_recipe", _recipe_slot(id)))
			b["queue"] = Array(b["queue"]).map(func(e): return _batch_entry(id, e))
	for id in d.get("helpers", {}):
		helpers[id] = int(d["helpers"][id])
	# Saves from before the helpers had names stored the farmhand as an upgrade level.
	if int(d.get("levels", {}).get("farmhand", 0)) > 0 and not helpers.has("farmhand"):
		helpers["farmhand"] = int(d["levels"]["farmhand"])
	for id in d.get("helper_timers", {}):
		helper_timers[id] = float(d["helper_timers"][id])
	decorations = Dictionary(d.get("decorations", {}))
	# Only furnishings that still exist are kept; the rug, for one, became part of the room.
	furnishings = {}
	for id in d.get("furnishings", {}):
		if Data.get_value("interior.furnishings", {}).has(id):
			furnishings[id] = true
		elif id == "water":
			# The rain pool is no longer sold, so a farm that bought one is paid back what it cost.
			coins += 15000
	for kind in d.get("pets", {}):
		pets[kind] = {"name": String(d["pets"][kind].get("name", "")), "coat": String(d["pets"][kind].get("coat", "")),
			"breed": String(d["pets"][kind].get("breed", "hound" if kind == "dog" else "tabby"))}
	var bl: Dictionary = d.get("blessing", {})
	blessing = {"god": String(bl["god"]), "time_left": float(bl.get("time_left", 0.0))} if bl.has("god") else {}
	use_manure = bool(d.get("use_manure", true))
	for key in d.get("stats", {}):
		stats[key] = int(d["stats"][key])
	# Saves from before the tutorial counted fewer things, so a farm with harvests behind it skips the first lessons.
	if int(stats.get("harvested", 0)) > 0:
		stats["planted"] = maxi(int(stats.get("planted", 0)), 1)
		var dug := plots.filter(func(p): return p["unlocked"] and p["zone"] == "home").size()
		if dug > int(Data.get_value("start.unlocked_plots", 4)):
			stats["plots_unlocked"] = maxi(int(stats.get("plots_unlocked", 0)), 1)
	# A farmhouse already restored was looked at before the tutorial counted it.
	if villa_stage >= 2:
		stats["villa_viewed"] = maxi(int(stats.get("villa_viewed", 0)), 1)
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
