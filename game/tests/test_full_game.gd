extends "res://tests/test_case.gd"
## The one purchase that opens the whole game on a phone: what the store says decides whether the farm plays by the
## demo's limits, the answer is kept so it holds without a connection, and a computer sells and locks nothing.

const CACHE := "user://test_store.cfg"
const PRICE := "CA$6.99"

## What each test listens to on FullGame, let go of when the test is done.
var _listening: Array[Callable] = []


func _full() -> Node:
	return root.get_node_or_null("FullGame")


## FullGame with a fake store that has answered nothing yet, and a cache of its own.
func _shop() -> FakeStore:
	var full := _full()
	_forget()
	full.cache_path = CACHE
	var store := FakeStore.new()
	full.use_store(store)
	return store


func _forget() -> void:
	if FileAccess.file_exists(CACHE):
		DirAccess.remove_absolute(CACHE)


func _done() -> void:
	var full := _full()
	for c in _listening:
		full.finished.disconnect(c)
	_listening.clear()
	full.use_store(null)
	full.cache_path = "user://store.cfg"
	_forget()
	Game.new_game()


func _results() -> Array:
	var heard := []
	var listen := func(result: String) -> void: heard.append(result)
	_full().finished.connect(listen)
	_listening.append(listen)
	return heard


func test_a_computer_sells_nothing_and_locks_nothing() -> void:
	var full := _full()
	check(full != null, "FullGame is an autoload")
	if full == null:
		return
	check(not Engine.has_singleton("SlowSundayPhone") and not full.sold_here(), "a computer has no store to buy the full game from")
	check(not full.locked() and not Game.is_demo(), "so the full game plays in full")
	var holder := Control.new()
	check(Ui.unlock_button(holder) == null, "and offers no unlock")
	full.buy()
	full.restore()
	check(not full.locked(), "and buying or restoring does nothing at all")
	holder.free()


func test_the_store_is_asked_for_the_price_once_it_connects() -> void:
	var store := _shop()
	check(store.calls.has(["billing_start"]), "the store's connection is opened at start")
	check(_full().price() == "", "the price is blank until the store says it")
	store.billing_connected.emit()
	check(store.calls.has(["query_price", "full_game"]), "once connected, the full game's price is asked for")
	store.price_found.emit("full_game", PRICE)
	check(_full().price() == PRICE, "and the store's own price text is kept (%s)" % _full().price())
	store.price_found.emit("other", "CA$1.00")
	check(_full().price() == PRICE, "a price for another product is not taken")
	_done()


func test_not_owned_plays_by_the_demos_limits() -> void:
	var store := _shop()
	check(_full().sold_here() and _full().locked(), "a phone that has not bought the full game is locked")
	check(Game.is_demo(), "so the farm plays by the demo's limits")
	check(Game.zone_block("pasture") == "In the full game", "and land beyond the demo waits for the full game")
	store.owned_found.emit(PackedStringArray())
	check(_full().locked(), "a store that lists nothing owned keeps it locked")
	_done()


func test_owned_opens_everything() -> void:
	var store := _shop()
	store.owned_found.emit(PackedStringArray(["full_game"]))
	check(_full().owned() and not _full().locked(), "a store that lists the full game unlocks it")
	check(not Game.is_demo(), "and the farm is no longer limited")
	check(Game.zone_block("pasture") != "In the full game", "so land beyond the demo can be bought")
	_done()


func test_buying_unlocks_at_once_and_keeps_the_farm() -> void:
	var store := _shop()
	var heard := _results()
	Game.villa_stage = 3
	Game.coins = 1234
	Game.zones_owned["grove"] = true
	var farm := JSON.stringify(Game.to_dict())
	check(Game.demo_capped_villa(), "the villa has reached the demo's last stage")
	_full().buy()
	check(store.calls.has(["buy", "full_game"]), "buying opens the store's purchase for the full game")
	store.purchase_finished.emit("full_game", "purchased")
	check(_full().owned() and not Game.is_demo(), "a finished purchase opens the full game straight away")
	check(not Game.demo_capped_villa(), "so the villa can be restored further")
	check(JSON.stringify(Game.to_dict()) == farm, "with the farm exactly as it was")
	check(heard == ["purchased"], "and the game hears it was bought, to say thank you (%s)" % str(heard))
	_done()


func test_a_pending_purchase_waits_for_the_payment() -> void:
	var store := _shop()
	var heard := _results()
	_full().buy()
	store.purchase_finished.emit("full_game", "pending")
	check(_full().locked(), "a purchase waiting for payment does not unlock anything yet")
	check(heard == ["pending"], "and the game hears that it waits (%s)" % str(heard))
	store.owned_found.emit(PackedStringArray(["full_game"]))
	check(not _full().locked(), "once the payment goes through the store lists it and the game opens")
	check(heard == ["pending", "purchased"], "with the thank-you then (%s)" % str(heard))
	_done()


func test_a_cancelled_or_failed_purchase_leaves_it_locked() -> void:
	var store := _shop()
	var heard := _results()
	for status in ["cancelled", "error", "unavailable"]:
		_full().buy()
		store.purchase_finished.emit("full_game", status)
		check(_full().locked(), "a purchase that ended %s leaves the game locked" % status)
	check(heard == ["cancelled", "error", "unavailable"], "and each ending is passed on (%s)" % str(heard))
	store.purchase_finished.emit("other", "purchased")
	check(_full().locked(), "buying some other product unlocks nothing")
	_done()


func test_restoring_asks_the_store_what_was_bought() -> void:
	var store := _shop()
	var heard := _results()
	_full().restore()
	check(store.calls.has(["query_owned"]), "restoring asks the store again what the player owns")
	store.owned_found.emit(PackedStringArray(["full_game"]))
	check(not _full().locked() and heard == ["restored"], "a purchase found unlocks the game and says so (%s)" % str(heard))
	store = _shop()
	heard = _results()
	_full().restore()
	store.owned_found.emit(PackedStringArray())
	check(_full().locked() and heard == ["not_found"], "with nothing bought it says none was found (%s)" % str(heard))
	heard.clear()
	_full().restore()
	store.billing_unavailable.emit("Billing service unavailable on device.")
	check(heard == ["unavailable"], "and a store that cannot be reached says that (%s)" % str(heard))
	heard.clear()
	store.owned_found.emit(PackedStringArray(["full_game"]))
	check(heard.is_empty() and not _full().locked(), "a later answer at start unlocks quietly, as on a new phone")
	_done()


func test_the_answer_is_kept_for_when_the_store_cannot_be_reached() -> void:
	var store := _shop()
	store.purchase_finished.emit("full_game", "purchased")
	check(FileAccess.file_exists(CACHE), "owning the full game is written down")
	var full := _full()
	var offline := FakeStore.new()
	full.use_store(offline)
	offline.billing_unavailable.emit("Network is down")
	check(full.owned() and not full.locked(), "so a later start without a connection still has the full game")
	offline.owned_found.emit(PackedStringArray())
	check(full.locked(), "a store that no longer lists it, as after a refund, locks it again")
	full.use_store(FakeStore.new())
	check(full.locked(), "and that is written down too")
	_done()


func test_the_unlock_button_shows_the_price_and_buys() -> void:
	var store := _shop()
	var holder := Control.new()
	var b: Button = Ui.unlock_button(holder)
	check(b != null and b.text == tr("Unlock the full game"), "before the store answers the button has no price (%s)" % (b.text if b else "none"))
	store.billing_connected.emit()
	store.price_found.emit("full_game", PRICE)
	b = Ui.unlock_button(holder)
	check(b != null and b.text == tr("Unlock the full game: %s") % PRICE, "then it shows the store's price (%s)" % (b.text if b else "none"))
	check(Ui.full_game_button(holder) != null, "a phone that sells the full game offers it where the demo stops")
	if b:
		b.pressed.emit()
	check(store.calls.has(["buy", "full_game"]), "pressing it buys the full game")
	store.purchase_finished.emit("full_game", "purchased")
	check(Ui.unlock_button(holder) == null and Ui.full_game_button(holder) == null, "and once it is owned there is nothing left to offer")
	holder.free()
	_done()


func test_phones_offer_to_restore_a_purchase_in_the_settings() -> void:
	var store := _shop()
	var was := [Windowing.phone, Windowing.phone_preview]
	Windowing.phone = true
	Windowing.phone_preview = true
	var panel: Control = load("res://scripts/ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.tab = "Gameplay"
	panel.open()
	await process_frame
	var restore := _button(panel, "Restore purchase")
	check(restore != null, "a phone that has not bought the full game offers to restore a purchase")
	if restore:
		restore.pressed.emit()
	check(store.calls.has(["query_owned"]), "which asks the store what was bought")
	store.owned_found.emit(PackedStringArray(["full_game"]))
	panel.show_page()
	await process_frame
	check(_button(panel, "Restore purchase") == null, "once it is owned the settings stop offering it")
	panel.free()
	Windowing.phone = was[0]
	Windowing.phone_preview = was[1]
	_done()


func test_the_title_offers_the_unlock_and_says_thank_you() -> void:
	var store := _shop()
	store.billing_connected.emit()
	store.price_found.emit("full_game", PRICE)
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	game.pets_chosen = true
	game.intro_seen = true
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	main.hud.back_to_title()
	await process_frame
	var title: Control = main.hud._title
	check(_button(title, "Unlock the full game: %s" % PRICE) != null, "the title offers the full game with its price")
	_full().buy()
	store.purchase_finished.emit("full_game", "purchased")
	await process_frame
	check(_button(title, "Unlock the full game: %s" % PRICE) == null, "and stops offering it once bought")
	var demo := title.find_child("DemoLabel", true, false)
	check(demo == null or not demo.visible, "the title no longer says Demo")
	var thanks: Array = main.hud._open_cards().filter(func(c: Control) -> bool:
		return c.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == tr("Thank you for buying the full game!")))
	check(thanks.size() == 1, "and a card thanks the player")
	main.hud._title.queue_free()
	main.hud._title = null
	main.queue_free()
	await process_frame
	_done()


func _button(node: Node, text: String) -> Button:
	for b in node.find_children("*", "Button", true, false):
		if b.text == tr(text) or b.text == text:
			return b
	return null


## The SlowSundayPhone plugin's purchase methods and signals, answered by hand.
class FakeStore:
	signal billing_connected
	signal billing_unavailable(message: String)
	signal price_found(product_id: String, price: String)
	signal purchase_finished(product_id: String, status: String)
	signal owned_found(product_ids: PackedStringArray)

	var calls: Array = []

	func billing_start() -> void:
		calls.append(["billing_start"])

	func billing_ready() -> bool:
		return true

	func query_price(product_id: String) -> void:
		calls.append(["query_price", product_id])

	func buy(product_id: String) -> void:
		calls.append(["buy", product_id])

	func query_owned() -> void:
		calls.append(["query_owned"])
