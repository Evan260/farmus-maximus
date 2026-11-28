extends "res://tests/test_case.gd"
## The one purchase that opens the whole game on a phone: what the store says decides whether the farm plays by the
## demo's limits, the answer is kept so it holds without a connection, and a computer sells and locks nothing.

const CACHE := "user://test_store.cfg"
const PRICE := "CA$4.99"
## A reviewer's code of the tests' own, since the game's real one is kept only as a hash.
const REVIEW_CODE := "QX7P-29HD-MM4F"
## A tester's code of the tests' own, for the same reason.
const TESTER_CODE := "TEST-TEST-TEST"

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


## FullGame with a fake store, taking the tests' own reviewer code.
func _reviewer_shop() -> FakeStore:
	var store := _shop()
	_full().review_hash = (_full().package_name + ":" + REVIEW_CODE.replace("-", "")).sha256_text()
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
	full.review_hash = str(ProjectSettings.get_setting("slowsunday/review_code_sha256", ""))
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


func test_the_app_store_sells_it_under_the_games_own_id() -> void:
	var id := "com.slowsunday.example.full_game"
	check(_full().get_script().apple_product("com.slowsunday.example") == id, "the App Store's id is the game's bundle id followed by .full_game")
	var store := _shop()
	_full().use_store(store, id)
	store.billing_connected.emit()
	check(store.calls.has(["query_price", id]), "the App Store is asked for the price under the game's own id")
	store.purchase_finished.emit("full_game", "purchased")
	check(_full().locked(), "Google Play's id opens nothing there")
	store.owned_found.emit(PackedStringArray([id]))
	check(_full().owned() and not _full().locked(), "the game's own id opens the full game")
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
	if thanks.size() == 1:
		var cover: Control = thanks[0]
		var opaque: bool = cover.find_children("*", "ColorRect", false, false).any(func(c: ColorRect) -> bool: return c.color.a == 1.0)
		check(opaque and cover.size == main.hud._root.size, "on a screen of its own, so nothing behind it shows through")
	main.hud._title.queue_free()
	main.hud._title = null
	main.queue_free()
	await process_frame
	_done()


func test_the_game_keeps_only_a_hash_of_its_reviewer_code() -> void:
	var hash := str(ProjectSettings.get_setting("slowsunday/review_code_sha256", ""))
	check(hash.length() == 64 and hash.is_valid_hex_number(), "project.godot holds the SHA-256 of Google Play's reviewer code (%s)" % hash)
	var presets := ConfigFile.new()
	presets.load("res://export_presets.cfg")
	var package := ""
	for section in presets.get_sections():
		if presets.get_value(section, "name", "") == "Android release":
			package = str(presets.get_value(section + ".options", "package/unique_name", ""))
	check(package != "" and _full().package_name == package, "hashed after the package name Google Play knows (%s, %s)" % [_full().package_name, package])


func test_the_reviewer_code_opens_the_full_game_and_is_kept() -> void:
	var store := _reviewer_shop()
	Game.villa_stage = 3
	Game.coins = 1234
	var farm := JSON.stringify(Game.to_dict())
	check(_full().locked() and Game.is_demo(), "a phone that has not bought the full game plays by the demo's limits")
	check(_full().redeem(REVIEW_CODE), "Google Play's reviewer code is taken")
	check(not _full().locked() and not Game.is_demo(), "and opens the full game at once, as buying it does")
	check(not Game.demo_capped_villa(), "so the villa can be restored further")
	check(JSON.stringify(Game.to_dict()) == farm, "with the farm exactly as it was")
	check(not store.calls.any(func(c: Array) -> bool: return c[0] == "buy"), "and nothing bought")
	_full().use_store(FakeStore.new())
	check(not _full().locked(), "a later start keeps the full game open before the store has said anything")
	_done()


func test_the_app_store_build_has_no_reviewer_code() -> void:
	var store := _reviewer_shop()
	_full().use_store(store, "com.slowsunday.example.full_game")
	var opened := false
	for i in 5:
		opened = _full().review_tap(10.0 + i * 0.1) or opened
	check(not opened, "five quick taps open no code box on the App Store, where Apple allows no way in but buying")
	check(not _full().redeem(REVIEW_CODE) and _full().locked(), "and Google Play's reviewer code opens nothing there")
	_done()


func test_the_reviewer_code_may_be_typed_in_lower_case_with_spaces_or_dashes() -> void:
	for typed in ["qx7p-29hd-mm4f", "QX7P 29HD MM4F", "qx7p29hdmm4f", " Qx7P - 29hD - mM4f "]:
		_reviewer_shop()
		check(_full().redeem(typed) and not _full().locked(), "\"%s\" is taken" % typed)
		_done()


func test_a_wrong_reviewer_code_opens_nothing() -> void:
	_reviewer_shop()
	for typed in ["", "QX7P-29HD-MM4G", "QX7P-29HD", "QX7P-29HD-MM4F-2", "QX7P_29HD_MM4F"]:
		check(not _full().redeem(typed), "\"%s\" is not taken" % typed)
	check(_full().locked() and not FileAccess.file_exists(CACHE), "the game stays locked with nothing written down")
	_full().review_hash = ("com.slowsunday.othergame:" + REVIEW_CODE.replace("-", "")).sha256_text()
	check(not _full().redeem(REVIEW_CODE), "and another game's code is not taken here")
	_done()


func test_the_testers_code_adds_sestertii_and_nothing_else() -> void:
	_reviewer_shop()
	var key := "slowsunday/tester_code_sha256"
	var real := str(ProjectSettings.get_setting(key, ""))
	check(real.length() == 64 and real.is_valid_hex_number() and real != _full().review_hash, "project.godot holds the SHA-256 of a tester's code of its own")
	ProjectSettings.set_setting(key, (_full().package_name + ":" + TESTER_CODE.replace("-", "")).sha256_text())
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	game.new_game()
	var title: Control = load("res://scripts/ui/title_screen.gd").new()
	root.add_child(title)
	var coins: int = game.coins
	check(title._tester_code(TESTER_CODE.to_lower()), "the tester's code is taken, typed in any case")
	check(game.coins == coins + title.TESTER_COINS, "and adds its sestertii")
	check(title._tester_code(TESTER_CODE) and game.coins == coins + 2 * title.TESTER_COINS, "again each time it is entered")
	check(_full().locked(), "without opening the full game")
	check(not title._tester_code(REVIEW_CODE) and not _full().redeem(TESTER_CODE), "and neither code does the other's work")
	ProjectSettings.set_setting(key, real)
	title.free()
	_done()


func test_the_store_saying_not_owned_never_locks_a_reviewers_phone_again() -> void:
	var store := _reviewer_shop()
	_full().redeem(REVIEW_CODE)
	store.owned_found.emit(PackedStringArray())
	check(not _full().locked(), "the store listing nothing owned, since the reviewer bought nothing, leaves the full game open")
	var later := FakeStore.new()
	_full().use_store(later)
	later.owned_found.emit(PackedStringArray())
	check(not _full().locked() and not Game.is_demo(), "and so does its answer at the next start")
	_done()


func test_only_five_quick_taps_open_the_reviewer_box() -> void:
	_reviewer_shop()
	var full := _full()
	var opened := []
	for i in 5:
		opened.append(full.review_tap(i * 1.0))
	check(not opened.has(true), "five taps a second apart open nothing (%s)" % str(opened))
	opened.clear()
	for t in [10.0, 10.5, 11.0, 11.5]:
		opened.append(full.review_tap(t))
	check(not opened.has(true), "nor do four quick ones (%s)" % str(opened))
	check(full.review_tap(12.5), "a fifth within three seconds opens it")
	check(not full.review_tap(12.6), "and the count starts again after it")
	_done()


func test_five_quick_taps_on_the_version_open_the_reviewer_box() -> void:
	_reviewer_shop()
	var title: Control = await _title()
	_tap_version(title, 4)
	check(_review_box(title) == null, "four taps on the version number open nothing")
	_tap_version(title, 1)
	await process_frame
	var field := _review_box(title)
	check(field != null and field.is_visible_in_tree(), "a fifth within three seconds opens the box for Google Play's reviewer code")
	check(field != null and field.has_focus(), "with the field ready to type in, which brings up a phone's keyboard")
	check(_button(title, "OK") != null and _button(title, "Cancel") != null, "with OK and Cancel")
	_button(title, "Cancel").pressed.emit()
	check(_review_box(title) == null and _button(title, "Unlock the full game") != null, "Cancel goes back to the title's menu")
	title.free()
	_done()


func test_the_version_opens_no_box_on_a_computer_or_once_the_full_game_is_owned() -> void:
	var title: Control = await _title()
	_tap_version(title, 5)
	check(_review_box(title) == null, "a computer, which sells nothing, opens no box")
	title.free()
	var store := _reviewer_shop()
	store.owned_found.emit(PackedStringArray(["full_game"]))
	title = await _title()
	_tap_version(title, 5)
	check(_review_box(title) == null, "nor does a phone that owns the full game")
	title.free()
	_done()


func test_the_reviewer_box_takes_the_right_code_and_refuses_a_wrong_one() -> void:
	_reviewer_shop()
	var title: Control = await _title()
	_tap_version(title, 5)
	await process_frame
	var field := _review_box(title)
	if field == null:
		check(false, "the box opens")
		title.free()
		_done()
		return
	field.text = "QX7P-29HD-MM4G"
	_button(title, "OK").pressed.emit()
	check(_shown(title, "That code isn't right."), "a wrong code says so")
	check(_full().locked() and _review_box(title) != null, "and leaves the box open and the game locked")
	field.text = "qx7p 29hd mm4f"
	_button(title, "OK").pressed.emit()
	check(not _full().locked() and not Game.is_demo(), "the right code opens the full game at once")
	check(_review_box(title) == null and _button(title, "Unlock the full game") == null, "and the title's menu comes back without the unlock")
	title.free()
	_done()


## The title on its own, as the game opens it.
func _title() -> Control:
	var title: Control = load("res://scripts/ui/title_screen.gd").new()
	root.add_child(title)
	await process_frame
	return title


## Taps the title's version number `n` times, each pressed and lifted where it shows, as a finger does.
func _tap_version(title: Control, n: int) -> void:
	var version: Control = title.get_node("Version")
	for i in n:
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = version.get_global_rect().get_center()
		down.global_position = down.position
		root.push_input(down)
		var up: InputEventMouseButton = down.duplicate()
		up.pressed = false
		root.push_input(up)


func _review_box(title: Control) -> LineEdit:
	return title.find_child("ReviewCode", true, false) as LineEdit


func _shown(node: Node, text: String) -> bool:
	return node.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == text and l.is_visible_in_tree())


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
