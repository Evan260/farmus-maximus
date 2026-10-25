extends Node
## The whole farm's state and the rules that change it. Live play and offline catch-up both run through advance().

signal planted(plot_index: int)
signal unlocked(plot_index: int)
signal harvested(plot_index: int, amount: int)
signal storage_full
signal cart_left(items: int, value: int)
signal cart_returned(coins: int)
signal villa_build_started(stage: int)
signal villa_upgraded(stage: int)
signal message(text: String)

var coins := 0
var storage := {}
var plots: Array = []
var levels := {}
## The crop a click on an empty plot plants.
var selected_seed := "lavender"
var villa_stage := 1
## A villa stage under construction; it finishes on its own, even while the game is closed.
var villa_build := {}
## In-game clock in hours, 0 to 24.
var day_time := 16.0
var cart := {}
var farmhand_timer := 0.0
var stats := {}
## Debug-only multiplier for live time; offline catch-up always uses real elapsed time.
var speed := 1.0
## True during offline catch-up, so hundreds of harvests do not each spawn an effect.
var quiet := false


func _ready() -> void:
	new_game()


func _process(delta: float) -> void:
	advance(delta * speed)


func new_game() -> void:
	coins = int(Balance.get_value("start.coins", 20))
	storage = {}
	plots = []
	var unlocked := int(Balance.get_value("start.unlocked_plots", 4))
	for i in int(Balance.get_value("plots.count", 17)):
		plots.append({"unlocked": i < unlocked, "crop": "", "growth": 0.0, "cycle": 0})
	levels = {"storage": 0, "cart_capacity": 0, "cart_speed": 0, "farmhand": 0}
	selected_seed = "lavender"
	villa_stage = 1
	villa_build = {"active": false, "time_left": 0.0}
	day_time = float(Balance.get_value("time.start_hour", 16))
	cart = _empty_cart()
	farmhand_timer = 0.0
	stats = {"harvested": 0, "earned": 0}


# Rules ------------------------------------------------------------------

func crop_info(crop_id: String) -> Dictionary:
	return Balance.get_value("crops." + crop_id, {})


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


func stored_total() -> int:
	var total := 0
	for item in storage:
		total += int(storage[item])
	return total


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


func item_price(item: String) -> int:
	return int(Balance.get_value("items." + item + ".price", 0))


func unlock_cost() -> int:
	var unlocked := 0
	for p in plots:
		if p["unlocked"]:
			unlocked += 1
	var extra := unlocked - int(Balance.get_value("start.unlocked_plots", 4))
	var base := float(Balance.get_value("plots.unlock_cost_base", 15))
	return int(round(base * pow(float(Balance.get_value("plots.unlock_cost_growth", 1.3)), maxi(extra, 0))))


func villa_stages() -> Array:
	return Balance.get_value("villa.stages", [])


## The price of the next villa stage, or -1 when the villa is fully built or already being built.
func villa_next_cost() -> int:
	var stages := villa_stages()
	if villa_build["active"] or villa_stage >= stages.size():
		return -1
	return int(stages[villa_stage].get("cost", 0))


# Actions ----------------------------------------------------------------

func try_plant(i: int, crop_id := "") -> bool:
	if crop_id == "":
		crop_id = selected_seed
	var p: Dictionary = plots[i]
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
	planted.emit(i)
	return true


func try_harvest(i: int) -> bool:
	if not is_ready(i):
		return false
	if stored_total() >= storage_capacity():
		storage_full.emit()
		return false
	_harvest(i)
	return true


func try_unlock(i: int) -> bool:
	var p: Dictionary = plots[i]
	if p["unlocked"]:
		return false
	var cost := unlock_cost()
	if coins < cost:
		message.emit("Not enough sestertii")
		return false
	coins -= cost
	p["unlocked"] = true
	unlocked.emit(i)
	return true


func send_cart() -> bool:
	if cart["away"]:
		return false
	var capacity := cart_capacity()
	var loaded := 0
	var value := 0
	for item in storage.keys():
		var take := mini(int(storage[item]), capacity - loaded)
		if take <= 0:
			continue
		loaded += take
		value += take * item_price(item)
		storage[item] = int(storage[item]) - take
		if storage[item] <= 0:
			storage.erase(item)
	if loaded == 0:
		message.emit("The storeroom is empty")
		return false
	cart = {"away": true, "time_left": cart_trip_seconds(), "items": loaded, "value": value}
	cart_left.emit(loaded, value)
	return true


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


func upgrade_villa() -> bool:
	var cost := villa_next_cost()
	if cost < 0:
		return false
	if coins < cost:
		message.emit("Not enough sestertii")
		return false
	coins -= cost
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


# Time -------------------------------------------------------------------

## Moves the farm forward by dt seconds and reports what happened.
func advance(dt: float) -> Dictionary:
	var result := {"harvested": 0, "earned": 0}
	day_time = fmod(day_time + dt * 24.0 / float(Balance.get_value("time.day_seconds", 1200)), 24.0)
	if villa_build["active"]:
		villa_build["time_left"] = float(villa_build["time_left"]) - dt
		if villa_build["time_left"] <= 0.0:
			_finish_villa()
	for p in plots:
		if p["unlocked"] and p["crop"] != "":
			p["growth"] = minf(float(p["growth"]) + dt, time_to_ready(p))
	if cart["away"]:
		cart["time_left"] = float(cart["time_left"]) - dt
		if cart["time_left"] <= 0.0:
			var value := int(cart["value"])
			coins += value
			stats["earned"] = int(stats["earned"]) + value
			result["earned"] += value
			cart = _empty_cart()
			if not quiet:
				cart_returned.emit(value)
	var interval := upgrade_value("farmhand")
	if interval > 0.0:
		farmhand_timer -= dt
		while farmhand_timer <= 0.0:
			var i := _first_ready_plot()
			if i < 0 or stored_total() >= storage_capacity():
				# Nothing to do, so the farmhand waits instead of saving up a burst of harvests.
				farmhand_timer = 0.0
				break
			var crop := String(plots[i]["crop"])
			result["harvested"] += _harvest(i)
			# The farmhand replants annual crops straight away, as long as the seed is affordable.
			if plots[i]["crop"] == "" and coins >= int(crop_info(crop).get("plant_cost", 0)):
				coins -= int(crop_info(crop).get("plant_cost", 0))
				plots[i]["crop"] = crop
			farmhand_timer += interval
	return result


## Catches up on time the game was closed, in small steps so every rule applies in order.
func simulate_offline(seconds: float) -> Dictionary:
	var remaining := minf(seconds, float(Balance.get_value("offline.max_hours", 72)) * 3600.0)
	var step := float(Balance.get_value("offline.step_seconds", 5))
	var start_coins := coins
	var summary := {"seconds": remaining, "harvested": 0, "earned": 0}
	quiet = true
	while remaining > 0.0:
		var dt := minf(step, remaining)
		var r := advance(dt)
		summary["harvested"] += r["harvested"]
		remaining -= dt
	quiet = false
	summary["earned"] = coins - start_coins
	summary["ready"] = 0
	for i in plots.size():
		if is_ready(i):
			summary["ready"] += 1
	summary["storage_full"] = stored_total() >= storage_capacity()
	return summary


func _harvest(i: int) -> int:
	var p: Dictionary = plots[i]
	var info := crop_info(p["crop"])
	var item := String(info.get("item", p["crop"]))
	var amount := mini(int(info.get("yield", 1)), storage_capacity() - stored_total())
	storage[item] = int(storage.get(item, 0)) + amount
	p["growth"] = 0.0
	p["cycle"] = int(p["cycle"]) + 1
	# Perennials like lavender regrow from the same plant; annuals like wheat leave the plot empty.
	if not info.get("perennial", false):
		p["crop"] = ""
		p["cycle"] = 0
	stats["harvested"] = int(stats["harvested"]) + amount
	if not quiet:
		harvested.emit(i, amount)
	return amount


func _first_ready_plot() -> int:
	for i in plots.size():
		if is_ready(i):
			return i
	return -1


func _empty_cart() -> Dictionary:
	return {"away": false, "time_left": 0.0, "items": 0, "value": 0}


# Saving -----------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"coins": coins, "selected_seed": selected_seed, "storage": storage, "plots": plots, "levels": levels,
		"villa_stage": villa_stage, "villa_build": villa_build, "day_time": day_time, "cart": cart, "farmhand_timer": farmhand_timer, "stats": stats,
	}


func from_dict(d: Dictionary) -> void:
	new_game()
	coins = int(d.get("coins", coins))
	selected_seed = String(d.get("selected_seed", selected_seed))
	storage = {}
	for item in d.get("storage", {}):
		storage[item] = int(d["storage"][item])
	var saved: Array = d.get("plots", [])
	for i in mini(saved.size(), plots.size()):
		var s: Dictionary = saved[i]
		plots[i] = {
			"unlocked": bool(s.get("unlocked", false)), "crop": String(s.get("crop", "")),
			"growth": float(s.get("growth", 0.0)), "cycle": int(s.get("cycle", 0)),
		}
	for id in d.get("levels", {}):
		levels[id] = int(d["levels"][id])
	villa_stage = int(d.get("villa_stage", 1))
	var vb: Dictionary = d.get("villa_build", {})
	villa_build = {"active": bool(vb.get("active", false)), "time_left": float(vb.get("time_left", 0.0))}
	day_time = float(d.get("day_time", day_time))
	var c: Dictionary = d.get("cart", {})
	cart = {
		"away": bool(c.get("away", false)), "time_left": float(c.get("time_left", 0.0)),
		"items": int(c.get("items", 0)), "value": int(c.get("value", 0)),
	}
	farmhand_timer = float(d.get("farmhand_timer", 0.0))
	var st: Dictionary = d.get("stats", {})
	stats = {"harvested": int(st.get("harvested", 0)), "earned": int(st.get("earned", 0))}
