extends RefCounted
## The market town: today's prices, the daily favourites, orders on the notice board and the shop.

## How many of each good were sold today; selling a lot of one good lowers its price until tomorrow.
var sold_today := {}
var favourites: Array = []
var orders: Array = []
var order_timer := 0.0
## One-off purchases already made, such as the second cart.
var purchases := {}
## What the cart brought to town this visit, by storage key; the stalls can only sell from it.
var brought := {}
var cart_in_town := false
var _game: Node


func _init(game: Node) -> void:
	_game = game
	order_timer = float(_cfg("orders.every_seconds", 300)) * 0.25


## Full price at the stalls today, for one unit of a stored good (its key may carry a quality).
func price(key: String) -> int:
	var base: String = _game.item_base(key)
	var p := float(_game.base_price(key))
	p *= maxf(float(_cfg("demand_floor", 0.5)), 1.0 - float(_cfg("demand_step", 0.04)) * int(sold_today.get(base, 0)))
	if base in favourites:
		p *= float(_cfg("favourite_bonus", 1.5))
	p *= float(Balance.get_value("items.%s.seasons.%s" % [base, _game.calendar.season_id()], 1.0))
	if base in _game.calendar.festival().get("items", []):
		p *= float(Balance.get_value("calendar.festival_bonus", 1.5))
	if _game.blessed("mercury"):
		p *= float(_cfg("mercury_bonus", 1.15))
	return maxi(1, int(round(p)))


## What the cart gets: the trader in town takes a cut.
func cart_price(key: String) -> int:
	return maxi(1, int(round(price(key) * float(_cfg("cart_cut", 0.7)))))


## Sells goods at the stalls in person, at full price.
## Loads the cart for a visit to town: goods marked for sale, the best paid first, as many as the cart carries.
func pack_cart() -> void:
	brought = {}
	cart_in_town = true
	var room: int = _game.cart_capacity()
	var goods: Dictionary = _game.sellable_goods()
	var keys := goods.keys()
	keys.sort_custom(func(a, b): return price(a) > price(b))
	for key in keys:
		var take := mini(int(goods[key]), room)
		if take <= 0:
			break
		brought[key] = take
		room -= take


## Home again: whatever was not sold goes back to being ordinary stock in the storehouse.
func unpack_cart() -> void:
	brought = {}
	cart_in_town = false


func brought_total() -> int:
	var n := 0
	for k in brought:
		n += int(brought[k])
	return n


func sell(key: String, amount: int) -> int:
	amount = mini(amount, int(_game.storage.get(key, 0)))
	if cart_in_town:
		amount = mini(amount, int(brought.get(key, 0)))
		brought[key] = int(brought.get(key, 0)) - maxi(amount, 0)
	if amount <= 0:
		return 0
	var total := 0
	for i in amount:
		total += price(key)
		note_sold(key, 1)
	_game.remove_key(key, amount)
	_game.coins += total
	_game.add_stat("earned", total)
	_game.add_stat("sold_market", amount)
	return total


func note_sold(key: String, amount: int) -> void:
	var base: String = _game.item_base(key)
	sold_today[base] = int(sold_today.get(base, 0)) + amount


func new_day() -> void:
	sold_today = {}
	var pool: Array = []
	for item in Balance.get_value("items", {}):
		if Balance.get_value("items.%s.kind" % item, "good") == "good" and _game.journal.has("item:" + item):
			pool.append(item)
	if pool.size() < 4:
		pool = ["lavender", "wheat", "olives", "dried_lavender", "honey", "flour"]
	favourites = []
	for i in int(_cfg("favourites", 2)):
		var pick: String = pool[_game.rng.randi() % pool.size()]
		if not pick in favourites:
			favourites.append(pick)


func advance(dt: float) -> void:
	if orders.size() >= int(_cfg("orders.max", 3)):
		return
	order_timer -= dt
	if order_timer <= 0.0:
		order_timer = float(_cfg("orders.every_seconds", 300))
		add_order()


## A new request on the notice board, for a good the player has already made, so it can always be filled.
func add_order() -> bool:
	var festival: Dictionary = _game.calendar.festival()
	var pool: Array = []
	for item in Balance.get_value("items", {}):
		if Balance.get_value("items.%s.kind" % item, "good") == "good" and _game.journal.has("item:" + item):
			pool.append(item)
	var themed := pool.filter(func(i): return i in festival.get("items", []))
	if not themed.is_empty():
		pool = themed
	if pool.is_empty():
		pool = ["lavender"]
	var item: String = pool[_game.rng.randi() % pool.size()]
	var regulars: Array = _cfg("regulars", [])
	var who: Dictionary = regulars[_game.rng.randi() % regulars.size()] if not regulars.is_empty() else {"id": "trader", "name": "A trader", "line": "I need {n} {item}."}
	var range_n: Array = _cfg("orders.amount", [3, 10])
	var base_price := float(_game.base_price(item))
	# Cheap goods are asked for by the dozen, precious ones a few at a time.
	var n := clampi(int(round(120.0 / base_price)), int(range_n[0]), int(range_n[1]))
	var bonus_range: Array = _cfg("orders.bonus", [1.6, 2.2])
	var reward := int(round(base_price * n * _game.rng.randf_range(float(bonus_range[0]), float(bonus_range[1]))))
	var aureus_chance := float(_cfg("orders.aureus_chance", 0.12)) * (2.0 if not festival.is_empty() else 1.0)
	var aureus := 1 if _game.rng.randf() < aureus_chance else 0
	var name := UiKit.mid(tr(String(Balance.get_value("items.%s.name" % item, item))))
	# Now and then a regular offers something money cannot buy: the rare white lavender.
	var seed := "lavender_white" if not _game.crop_unlocked("lavender_white") and _game.rng.randf() < float(_cfg("orders.rare_seed_chance", 0.06)) else ""
	orders.append({
		"who": who.get("name", ""), "role": who.get("role", ""), "item": item, "amount": n, "coins": reward, "aureus": aureus, "seed": seed,
		"text": tr(String(who.get("line", "{n} {item}"))).format({"n": n, "item": name}),
	})
	if not _game.quiet:
		_game.order_added.emit()
	return true


func can_deliver(index: int) -> bool:
	var o: Dictionary = orders[index]
	return _game.count_item(String(o["item"])) >= int(o["amount"])


func deliver(index: int) -> bool:
	if index < 0 or index >= orders.size() or not can_deliver(index):
		return false
	var o: Dictionary = orders[index]
	_game.take_items({String(o["item"]): int(o["amount"])})
	_game.coins += int(o["coins"])
	_game.add_stat("earned", int(o["coins"]))
	if int(o["aureus"]) > 0:
		_game.gain_aureus(int(o["aureus"]))
	if String(o.get("seed", "")) != "" and not _game.crop_unlocked(String(o["seed"])):
		_game.unlock_crop(String(o["seed"]))
		_game.discover("find:rare_seed")
		_game.message.emit(tr("%s gives you a rare seed: white lavender!") % tr(String(o["who"])))
	_game.add_stat("orders", 1)
	orders.remove_at(index)
	return true


## Whether a shop item can be bought right now, and if not, why.
func catalog_block(entry: Dictionary) -> String:
	if entry.get("once", false) and purchases.has(entry["id"]):
		return "Bought"
	if entry.has("unlock_crop") and _game.crop_unlocked(String(entry["unlock_crop"])):
		return "Bought"
	if int(entry.get("requires_villa", 0)) > _game.villa_stage:
		return tr("Needs the %s") % UiKit.mid(tr(String(_game.villa_stages()[int(entry["requires_villa"]) - 1]["name"])))
	if entry.has("requires_zone") and not _game.zone_owned(String(entry["requires_zone"])):
		return tr("Needs the %s") % UiKit.mid(tr(String(_game.zone_info(String(entry["requires_zone"])).get("name", ""))))
	if entry.has("animal"):
		return _game.barn_room_block(String(entry["animal"]))
	return ""


func catalog() -> Array:
	return _cfg("catalog", [])


func buy(id: String, qty := 1) -> bool:
	var entry: Dictionary = {}
	for e in catalog():
		if e["id"] == id:
			entry = e
	if entry.is_empty() or catalog_block(entry) != "":
		return false
	var cost := {"coins": int(entry.get("price", 0)) * qty, "aureus": int(entry.get("aureus", 0)) * qty}
	if not _game.pay(cost):
		return false
	if entry.has("unlock_crop"):
		_game.unlock_crop(String(entry["unlock_crop"]))
	if entry.has("item"):
		_game.add_item(String(entry["item"]), qty, true)
	if entry.has("animal"):
		_game.add_animal(String(entry["animal"]))
	if entry.has("gives_coins"):
		_game.coins += int(entry["gives_coins"]) * qty
	if entry.get("once", false):
		purchases[id] = true
	return true


func _cfg(path: String, fallback: Variant) -> Variant:
	return Balance.get_value("market." + path, fallback)


func to_dict() -> Dictionary:
	return {"sold_today": sold_today, "favourites": favourites, "orders": orders, "order_timer": order_timer, "purchases": purchases}


func from_dict(d: Dictionary) -> void:
	sold_today = {}
	for k in d.get("sold_today", {}):
		sold_today[k] = int(d["sold_today"][k])
	favourites = Array(d.get("favourites", []))
	orders = []
	for o in d.get("orders", []):
		orders.append({"who": String(o.get("who", "")), "role": String(o.get("role", "")), "item": String(o.get("item", "lavender")),
			"amount": int(o.get("amount", 1)), "coins": int(o.get("coins", 0)), "aureus": int(o.get("aureus", 0)), "seed": String(o.get("seed", "")),
			"text": String(o.get("text", ""))})
	order_timer = float(d.get("order_timer", order_timer))
	purchases = Dictionary(d.get("purchases", {}))
