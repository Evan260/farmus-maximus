extends SceneTree
## Headless checks that the farm scene builds and every plot answers clicks in its own spot.

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	var hooks: Array = [game.unlocked, game.animal_added, game.helper_hired, game.decoration_bought]
	var hooked: Array = hooks.map(func(s: Signal): return s.get_connections().size())
	game.new_game()
	game.pets_chosen = true
	game.day_time = 8.0
	game.coins = 1000
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	_check(main.plot_views.size() == game.plots.size(), "one view per plot")
	await process_frame
	for v in main.plot_views:
		var hit: Node2D = main._plot_at(v.position + Vector2(14, -1))
		_check(hit == v, "plot %d is clicked at its own soil patch" % v.index)
	var empty: Node2D = main._view(0)
	_check(main._plot_at(empty.position + Vector2(14, -20)) != empty, "an empty plot does not respond above its soil")
	main.hud.select_tool("seed:lavender")
	var spot: Node2D = main._view(1)
	main.dog.modulate.a = 1.0
	main.dog.position = spot.position + Vector2(20, -6)
	var pick: Vector2 = spot.position + Vector2(14, -1)
	if main.dog.contains(pick):
		main._click(pick)
		_check(game.plots[1]["crop"] != "", "a plot takes the click when the dog stands behind it")
	main.dog.position = spot.position + Vector2(20, 4)
	_check(main._pet_at(pick, main._plot_at(pick)) == main.dog, "a dog standing in front of a plant takes the click")
	var i := 0
	main._click_plot(i)
	_check(game.plots[i]["crop"] == "lavender", "clicking an empty plot plants lavender")
	main.hud.select_tool("dig")
	main._click_plot(i)
	_check(game.plots[i]["crop"] == "", "the spade digs a plant up")
	main.hud.select_tool("seed:lavender")
	main._click_plot(i)
	game.calendar.wet_left = 9999.0
	# Each planting grows a little faster or slower than the crop's usual time, so allow for the slowest.
	game.advance(60.0 * (1.0 + float(root.get_node("Balance").get_value("plots.growth_spread", 0.12))) + 1.0)
	await process_frame
	_check(main._plot_at(empty.position + Vector2(14, -20)) == empty, "a grown plant responds where its leaves are")
	main._click_plot(i)
	_check(game.stored_total() == 1, "clicking a blooming plot harvests it")
	game.add_item("stone", 3, true)
	game.add_item("tiles", 3, true)
	var top: Vector2 = main.villa.villa_rect().position + Vector2(main.villa.villa_rect().size.x / 2, 10)
	main._click(top)
	_check(main.hud._building.visible and main.hud._building.id == "villa", "clicking the farmhouse opens its panel")
	main.hud._building._action.pressed.emit()
	_check(game.villa_build["active"], "the farmhouse panel starts the restoration")
	for b in main.building_views:
		var r: Rect2 = b.world_rect()
		var point: Vector2 = r.position + Vector2(r.size.x / 2.0, 8)
		_check(main._plot_at(point) == null and main._building_at(point) == b, "a gamepad can pick the %s" % b.id)
	for s in main.signs:
		var r: Rect2 = s.world_rect()
		# The ground strip's top edge wanders between rows 229 and 235.
		_check(r.end.y > 236, "the %s sign stands in the ground" % s.zone_id)
	await _check_steady_size(main.hud._settings, func(w, t): w.tab = t; w.show_page(), ["Sound", "Display", "Play", "Keys"])
	var pages := ["Crops", "Goods", "Buildings", "Helpers", "Animals", "Finds", "Sightings", "Festivals", "Milestones", "Achievements",
		"item:olive_oil", "crop:lavender", "achievement:first_harvest"]
	await _check_steady_size(main.hud._journal, _show_journal_page, pages)
	var journal: Control = main.hud._journal
	journal.open()
	_show_journal_page(journal, "Goods")
	await process_frame
	await process_frame
	_journal_list(journal).scroll_vertical = 40
	_show_journal_page(journal, "item:olive_oil")
	await process_frame
	await process_frame
	_check(_journal_list(journal).scroll_vertical == 40, "choosing a journal entry keeps the list where it was")
	journal.close()
	game.coins += 1000
	game.day_time = 9.0
	game.buy_upgrade("storage")
	for f in 40:
		await process_frame
	_check(main._store_scaffold.visible and main._builders.has("project_storage"), "enlarging the storehouse puts up scaffolding and brings a builder")
	await _check_ride(main)
	_check_catch_up(main)
	var pets: Control = main.hud._companions
	# Without a window the screen is only 64 pixels square, so it is given a full screen's size to fit windows in.
	var screen: Vector2 = main.hud._root.size
	main.hud._root.size = Vector2(480, 270)
	pets.open()
	await process_frame
	await process_frame
	_check(pets._scroll == null or not pets._scroll.get_v_scroll_bar().visible, "the companions window fits without scrolling")
	main.hud._root.size = screen
	pets.close()
	game.day_time = 22.0
	main.hud._start_sleep()
	await create_timer(8.0).timeout
	_check(game.day_time > 6.0 and game.day_time < 7.5 and game.speed == 1.0, "sleeping runs the night by and wakes at dawn (woke at %.2f)" % game.day_time)
	var pair := []
	for who in ["traveller", "shepherd"]:
		var w: Node2D = load("res://scripts/world/walker.gd").new()
		w.dir = "res://assets/sprites/people/%s/" % who
		w.position = Vector2(300, 250)
		w.leave_at = 9999.0
		w.speed = 0.0
		main.world.add_child(w)
		main._passers.append(w)
		pair.append(w)
	# People fade in when they arrive and cannot be clicked until they are there.
	await create_timer(1.5).timeout
	_check(main._pet_at(Vector2(300, 234), null) == pair[1], "of two people standing on each other, the one drawn in front takes the click")
	var donkey: AnimatedSprite2D = main._donkey
	var box: Rect2 = Hit.frame_rect(donkey, donkey)
	var solid := Vector2.INF
	var empty_corner := Vector2.INF
	for y in range(int(box.position.y), int(box.end.y)):
		for x in range(int(box.position.x), int(box.end.x)):
			var at := Vector2(x, y) + Vector2(0.5, 0.5)
			if Hit.frame_has_pixel(donkey, donkey, at):
				solid = at if solid == Vector2.INF else solid
			elif main._pasture.animal_at(at) == null and main._wildlife.rabbit_at(at).is_empty():
				empty_corner = at if empty_corner == Vector2.INF else empty_corner
	_check(solid != Vector2.INF and main._animal_at(solid) == "donkey", "the donkey answers a click on itself")
	_check(empty_corner != Vector2.INF and main._animal_at(empty_corner) != "donkey", "the donkey ignores a click on the empty corner of its picture")
	_check(String(pair[0].saying()) != "", "a person has something to say when clicked")
	await _check_stone_donkey(main)
	game.pets_chosen = false
	main._spawn_pets()
	_check(not main.dog.visible and not main.cat.visible, "on a new farm the pets stay away until they are chosen")
	game.pets_chosen = true
	main._spawn_pets()
	_check(main.dog.visible and main.cat.visible, "and come home once they are")
	var fox: AnimatedSprite2D = main._wildlife._fox
	if fox:
		fox.visible = true
		fox.position = Vector2(300, 262)
		main._wildlife.startle_fox(Vector2(280, 262))
		_check(main._wildlife._fox_fleeing > 0.0 and not fox.flip_h, "a clicked fox runs off, away from the click")
		fox.visible = false
	var holder := Control.new()
	holder.size = Vector2(200, 100)
	main.hud._root.add_child(holder)
	var kit: GDScript = load("res://scripts/ui/kit.gd")
	var list: VBoxContainer = kit.scroll(holder, Vector2(120, 60))
	for k in 20:
		kit.button(list, "Row %d" % k, func(): pass)
	await process_frame
	await process_frame
	var area: ScrollContainer = list.get_parent().get_parent()
	var finger: Node = area.get_child(0) if not area.get_child(0) is Control else area.get_child(1)
	var middle: Vector2 = finger._screen_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = middle
	finger._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.position = middle - Vector2(0, 40)
	finger._input(drag)
	_check(area.scroll_vertical > 0, "a finger dragging up a list scrolls it")
	holder.queue_free()
	game.villa_stage = 3
	main.go_inside()
	await create_timer(1.0).timeout
	_check(main.interior.visible and not main.hud.visible, "the farmhouse door leads inside")
	var inside: CanvasLayer = main.interior
	var stroked: int = game.stats.get("pets", 0)
	_check(inside._pet_at(inside._dog.position + Vector2(0, -8)) == null, "by day the dog is out on the farm, not indoors")
	var hour: float = game.day_time
	game.day_time = 23.0
	inside._dress_room()
	_check(inside._pet_at(inside._dog.position + Vector2(0, -8)) == inside._dog, "the sleeping dog can be clicked inside at night")
	inside._stroke(inside._dog)
	_check(int(game.stats.get("pets", 0)) == stroked + 1, "stroking a pet inside counts like petting it outside")
	inside._weave()
	_check(inside._weaving > 0.0, "clicking the loom sets it weaving")
	game.day_time = hour
	main.interior.leave()
	await create_timer(1.0).timeout
	_check(not main.interior.visible and main.hud.visible, "and back out to the farm")
	var rain: Node2D = load("res://scripts/world/rain_fx.gd").new()
	main.add_child(rain)
	await process_frame
	rain._process(5.0)
	var rows := {}
	for d in rain._drops:
		rows[roundi(d.y)] = true
	_check(rows.size() > 40, "rain stays spread out after one very long frame (%d rows)" % rows.size())
	var settings: Node = root.get_node("Settings")
	var windowing: Node = root.get_node("Windowing")
	var loudness := AudioServer.get_bus_volume_db(0)
	settings.background_sound = "quieter"
	windowing.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(AudioServer.get_bus_volume_db(0) < loudness - 6.0, "the game turns down while another window has the focus")
	settings.background_sound = "muted"
	windowing.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(AudioServer.is_bus_mute(0), "and falls silent when set to muted")
	windowing.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(not AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_db(0), loudness), "and comes back in full when the game has the focus again")
	settings.background_sound = "full"
	await _check_fade_reuse()
	_check_trial_run()
	_check_saves(main)
	await _check_window_fit()
	# The windows rebuilt above finish placing their focus on the next frame, so the scene stays until then.
	await process_frame
	main.queue_free()
	await process_frame
	_check(hooks.map(func(s: Signal): return s.get_connections().size()) == hooked, "the farm's handlers on the game's signals go when the scene does")
	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


## Riding the cart to market: one trip at a time, no strip from inside the town, and the trip called off by going indoors.
func _check_ride(main: Node2D) -> void:
	var settings: Node = root.get_node("Settings")
	var windowing: Node = root.get_node("Windowing")
	var game: Node = root.get_node("Game")
	var motion: bool = settings.reduced_motion
	settings.reduced_motion = false
	var visits := int(game.stats.get("market_visits", 0))
	main._ride_to_market()
	main.go_to_town()
	_check(not main.market.visible, "pressing M during the ride waits for the ride")
	await create_timer(2.4).timeout
	_check(main.market.visible and int(game.stats.get("market_visits", 0)) == visits + 1, "a ride with M pressed on the way enters the market once")
	var strip_key := InputEventAction.new()
	strip_key.action = "toggle_strip"
	strip_key.pressed = true
	root.push_input(strip_key)
	_check(not windowing.strip, "the strip waits until the player has left the market")
	if windowing.strip:
		windowing.toggle_strip()
	main.market.leave()
	await create_timer(0.8).timeout
	_check(not main.market.visible and absf(main._cart.position.x - main._cart_park_x) < 1.0, "back from the market the cart is parked at home")
	main._ride_to_market()
	await process_frame
	main.go_inside()
	await create_timer(2.4).timeout
	_check(main.interior.visible and not main.market.visible and absf(main._cart.position.x - main._cart_park_x) < 1.0, "going indoors during the ride calls the trip off and parks the cart")
	main.interior.leave()
	await create_timer(0.8).timeout
	settings.reduced_motion = motion


## Time caught up all at once sends none of the signals the scene follows, so afterwards the scene is set from the farm.
func _check_catch_up(main: Node2D) -> void:
	var game: Node = root.get_node("Game")
	_check(game.caught_up.is_connected(main._on_caught_up), "the farm is redrawn after time is caught up")
	game.cart = {"away": true, "time_left": 1.0, "items": 1, "value": 5, "load": []}
	main._cart.position.x = main.estate_width + 60
	game.quiet = true
	game.advance(2.0)
	game.quiet = false
	main._on_caught_up({})
	_check(not game.cart["away"] and absf(main._cart.position.x - main._cart_park_x) < 1.0 and main._can_drop(main._cart_side()), "a cart that came home during a catch-up is parked where helpers can load it")
	game.cart = {"away": true, "time_left": 600.0, "items": 1, "value": 5, "load": []}
	game.quiet = true
	game.cart_left.emit(1, 5)
	game.quiet = false
	main._on_caught_up({})
	_check(main._cart.position.x >= main.estate_width and not main._cart_returning, "and one that left during it is away down the road")
	game.cart = game._empty_cart()
	main._on_caught_up({})
	var level := int(game.levels.get("storage", 0))
	game.projects["storage"] = 1.0
	main._store_scaffold.visible = true
	var some: String = game.buildings.keys()[0]
	main._building_states[some] = "upgrading" if game.buildings[some]["state"] != "upgrading" else "working"
	game.quiet = true
	game._finish_project("storage")
	game.quiet = false
	main._on_caught_up({})
	var dressed := "storehouse_%d.png" % (level + 1)
	var shows_level: bool = main._storehouse.texture.resource_path.ends_with(dressed) or not ResourceLoader.exists("res://assets/sprites/farm/" + dressed)
	_check(shows_level and not main._store_scaffold.visible, "a storehouse enlarged during a catch-up is shown enlarged, without its scaffolding")
	_check(main._building_states[some] == String(game.buildings[some]["state"]), "and each building's state is noted afresh")


## Clicking the paving cart's donkey makes that donkey bray, not the trader's.
func _check_stone_donkey(main: Node2D) -> void:
	var game: Node = root.get_node("Game")
	var hour: float = game.day_time
	game.day_time = 10.0
	game.projects["cart_speed"] = game.upgrade_seconds("cart_speed")
	await process_frame
	await process_frame
	var donkey: AnimatedSprite2D = main._stone_donkey
	var host: Node2D = main.road._stone_cart
	var box: Rect2 = Hit.frame_rect(host, donkey)
	var solid := Vector2.INF
	for y in range(int(box.position.y), int(box.end.y)):
		for x in range(int(box.position.x), int(box.end.x)):
			var at := Vector2(x, y) + Vector2(0.5, 0.5)
			if solid == Vector2.INF and Hit.frame_has_pixel(host, donkey, at) and main._pasture.animal_at(at) == null and main._wildlife.rabbit_at(at).is_empty():
				solid = at
	_check(solid != Vector2.INF and main._animal_at(solid) == "donkey", "the paving cart's donkey answers a click on itself")
	if solid != Vector2.INF:
		main._call_out("donkey", solid)
		_check(donkey.animation == "bray" and main._donkey.animation != "bray", "and it is that donkey that brays")
	game.projects.erase("cart_speed")
	game.day_time = hour
	await process_frame


## A test run is a trial run, so a changed setting, volume or window never reaches the player's own files.
func _check_trial_run() -> void:
	var settings: Node = root.get_node("Settings")
	var sfx: Node = root.get_node("Sfx")
	var windowing: Node = root.get_node("Windowing")
	_check(not settings.persist and settings.trial_run(), "a test run counts as a trial run")
	if settings.persist:
		return
	var files := ["user://prefs.json", "user://settings.json", "user://window.json"]
	var read := func() -> Array: return files.map(func(f): return FileAccess.get_file_as_string(f) if FileAccess.file_exists(f) else "-")
	var before: Array = read.call()
	var tips: bool = settings.show_tutorial
	var music: float = sfx.volumes["Music"]
	settings.set_value("show_tutorial", not tips)
	sfx.set_volume("Music", 0.123)
	windowing.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_check(read.call() == before, "a trial run never writes the player's preferences, volumes or window")
	settings.set_value("show_tutorial", tips)
	sfx.set_volume("Music", music)


## A sound player taken while it is still fading out plays the new sound at its own volume.
func _check_fade_reuse() -> void:
	var sfx: Node = root.get_node("Sfx")
	var sound: String = sfx._sounds.keys()[0]
	var first: AudioStreamPlayer = sfx.play(sound)
	sfx.fade_out(first, 1.0)
	if first == null or not sfx._fades.has(first):
		return
	for k in sfx._players.size() - 1:
		sfx.play(sound)
	var again: AudioStreamPlayer = sfx.play(sound, -3.0)
	await create_timer(0.5).timeout
	_check(again == first and is_equal_approx(first.volume_db, -3.0), "a sound player reused during a fade keeps its new sound's volume")


## The farms on disk, kept in a folder of the test's own so the player's farms are never touched.
func _check_saves(main: Node2D) -> void:
	var saves: Node = root.get_node("Saves")
	var game: Node = root.get_node("Game")
	var dir := "user://test_saves/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	_clear_folder(dir)
	saves.folder = dir
	saves.enabled = true
	saves.load_game(1)
	saves.save_game()
	_check(not FileAccess.file_exists(saves.path_for(1)), "the empty estate behind the title screen is not saved")
	game.intro_seen = true
	saves.save_game()
	_check(saves.has_farm and not saves.slot_info(1).is_empty(), "an empty slot played straight away is saved once its welcome begins")
	saves.save_game()
	saves.save_game()
	_check(FileAccess.file_exists(saves.path_for(1) + ".bak1") and not FileAccess.file_exists(saves.path_for(1) + ".bak2"), "saves a moment apart do not push the backups along")
	var good := FileAccess.get_file_as_string(saves.path_for(1))
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(saves.path_for(1) + ".tmp"))
	saves.save_game()
	_check(FileAccess.get_file_as_string(saves.path_for(1)) == good, "a save that cannot be written leaves the last good one alone")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.path_for(1) + ".tmp"))
	var list: Control = load("res://scripts/ui/farms_panel.gd").new()
	main.hud._root.add_child(list)
	var shown: String = list.signature()
	saves.save_game()
	_check(list.signature() == shown, "an autosave does not rebuild the farm list")
	list.open()
	list._deleting = 1
	list._typed = ""
	list.refresh()
	var typing: LineEdit = list.find_children("*", "LineEdit", true, false)[0]
	typing.text = "del"
	typing.text_changed.emit("del")
	list._signature = ""
	list.refresh()
	_check(list.find_children("*", "LineEdit", true, false)[0].text == "del", "the farm list rebuilding keeps what was typed to confirm a delete")
	list.close()
	var tmp: String = saves.path_for(1) + ".tmp"
	var newest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saves.path_for(1)))
	newest["farm_name"] = "Newest"
	newest["saved_at"] = float(newest["saved_at"]) + 1.0
	var whole := JSON.stringify(newest, "\t")
	_write_file(tmp, whole.substr(0, whole.length() / 2))
	saves.load_game(1)
	_check(game.farm_name != "Newest", "a half-written .tmp never wins over the farm file")
	_write_file(tmp, whole)
	saves.load_game(1)
	_check(game.farm_name == "Newest", "a whole .tmp newer than the farm file is loaded first")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.path_for(1)))
	saves.load_game(1)
	_check(game.farm_name == "Newest" and saves.free_slot() != 1, "and is loaded when a save stopped before the farm file was replaced")
	saves.save_game()
	_check(FileAccess.file_exists(saves.path_for(1)) and not FileAccess.file_exists(tmp), "the next save puts the farm file back")
	saves.pending_summary = {"seconds": 3600.0}
	saves.play(saves.slot)
	_check(saves.pending_summary.has("seconds"), "playing the farm already open keeps its summary of time away")
	saves.title_done = false
	for path in saves._candidates(2):
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string("{ not a farm")
		f.close()
	_check(saves.slot_info(2).is_empty() and saves.free_slot() == 3, "a farm that cannot be read keeps its slot")
	saves.load_game(2)
	game.intro_seen = true
	game.farm_name = "Second"
	saves.save_game()
	var kept := Array(DirAccess.get_files_at(dir)).filter(func(f): return String(f).begins_with("farm_2.json") and ".unreadable-" in String(f))
	_check(kept.size() == 4 and not saves.slot_info(2).is_empty(), "a farm that cannot be read is kept aside rather than written over")
	var counts := [saves._files(1).size(), saves._files(2).size()]
	saves.enabled = false
	saves.reset()
	saves.delete(1)
	saves.delete(2)
	_check([saves._files(1).size(), saves._files(2).size()] == counts, "with saving off, resetting or deleting a farm leaves its files alone")
	saves.enabled = true
	saves.load_game(1)
	saves.delete(1)
	_check(saves.slot == 2 and saves.has_farm and game.farm_name == "Second" and int(saves._farms().get("last", 0)) == 2, "deleting the farm being played moves on to another farm")
	saves.delete(2)
	_check(not saves.has_farm and not saves.any_farm(), "deleting the last farm leaves none to carry on with")
	saves.enabled = false
	saves.folder = "user://"
	_clear_folder(dir)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


func _write_file(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _clear_folder(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))


## The page that holds the journal's list of entries.
func _journal_list(journal: Control) -> ScrollContainer:
	var found: ScrollContainer = null
	# The window's own scroll holds the whole book, so the innermost scroll around the grid is the list's.
	for s in journal.find_children("*", "ScrollContainer", true, false):
		if not s.find_children("*", "GridContainer", true, false).is_empty():
			found = s
	return found


func _show_journal_page(journal: Control, page: String) -> void:
	if ":" in page:
		journal.selected = page
		journal.refresh()
	else:
		journal.section = page
		journal.selected = ""
		journal.show_page()


## A window with tabs keeps one size whichever tab it shows.
func _check_steady_size(window: Control, show: Callable, tabs: Array) -> void:
	window.open()
	var sizes := {}
	for t in tabs:
		show.call(window, t)
		await process_frame
		await process_frame
		sizes[str(window.size)] = t
	_check(sizes.size() == 1, "the %s window keeps one size on every tab: %s" % [window.name, sizes])
	window.close()


## A window that fits its page shows no scroll bar, whose width would change where the page's sentences wrap.
func _check_window_fit() -> void:
	for case in [[Vector2(480, 270), ScrollContainer.SCROLL_MODE_DISABLED, "fits the screen has no scroll bar"],
			[Vector2(480, 60), ScrollContainer.SCROLL_MODE_AUTO, "is taller than the screen still scrolls"]]:
		var holder := Control.new()
		holder.size = case[0]
		root.add_child(holder)
		var farms: Control = load("res://scripts/ui/farms_panel.gd").new()
		holder.add_child(farms)
		farms.open()
		for i in 5:
			await process_frame
		_check(farms._scroll.vertical_scroll_mode == case[1], "a window that " + case[2])
		holder.queue_free()


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
