extends SceneTree
## Headless checks that the farm scene builds and every plot answers clicks in its own spot.

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
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
	var lists: Array = journal.find_children("*", "ScrollContainer", true, false)
	var grid: ScrollContainer = lists[lists.size() - 1]
	grid.scroll_vertical = 40
	_show_journal_page(journal, "item:olive_oil")
	await process_frame
	await process_frame
	lists = journal.find_children("*", "ScrollContainer", true, false)
	_check(lists[lists.size() - 1].scroll_vertical == 40, "choosing a journal entry keeps the list where it was")
	journal.close()
	game.coins += 1000
	game.day_time = 9.0
	game.buy_upgrade("storage")
	for f in 40:
		await process_frame
	_check(main._store_scaffold.visible and main._builders.has("project_storage"), "enlarging the storehouse puts up scaffolding and brings a builder")
	var pets: Control = main.hud._companions
	pets.open()
	await process_frame
	await process_frame
	_check(pets._scroll == null or not pets._scroll.get_v_scroll_bar().visible, "the companions window fits without scrolling")
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
	_check(inside._pet_at(inside._dog.position + Vector2(0, -8)) == inside._dog, "the sleeping dog can be clicked inside")
	inside._stroke(inside._dog)
	_check(int(game.stats.get("pets", 0)) == stroked + 1, "stroking a pet inside counts like petting it outside")
	inside._weave()
	_check(inside._weaving > 0.0, "clicking the loom sets it weaving")
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
	print("FAILURES: %d" % failures if failures else "ALL TESTS PASSED")
	quit(1 if failures else 0)


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


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
