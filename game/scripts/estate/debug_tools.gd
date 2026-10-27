extends Node
## The development-only side of the estate: demo farms, screenshots, bursts of frames and opening a panel from the
## command line, so screenshots and checks never touch a real save.

## The estate scene this works for.
var m: Estate


## Saves exactly what the window shows after the scene settles, then quits; used for store screenshots and layout checks.
func take_screenshot(path: String) -> void:
	for i in 45:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


## Saves eight frames a quarter of a second apart (or --burst-gap seconds), for checking anything that flickers or moves.
func take_burst(prefix: String) -> void:
	for i in 45:
		await get_tree().process_frame
	for k in 8:
		get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, k])
		var gap := 0.25
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--burst-gap="):
				gap = float(arg.trim_prefix("--burst-gap="))
		await get_tree().create_timer(gap).timeout
	get_tree().quit()


func open_panel(which: String) -> void:
	if which.begins_with("journal:"):
		m.hud.open_window("journal")
		m.hud.show_journal_entry(which.trim_prefix("journal:"))
	elif which.begins_with("settings:"):
		m.hud.open_window("settings")
		m.hud._settings.tab = which.trim_prefix("settings:")
		m.hud._settings.show_page()
	elif which in ["journal", "helpers", "store", "settings", "upgrades", "companions", "credits"]:
		m.hud.open_window(which)
	else:
		m.hud.show_building(which)


## Fills the farm with plants at every stage, for screenshots and clips; saving is switched off so a real save is never touched.
func load_demo_state() -> void:
	Saves.enabled = false
	Saves.pending_summary = {}
	Settings.show_tutorial = false
	Game.new_game()
	Game.intro_seen = true
	Game.pets_chosen = true
	Game.farm_name = "Villa Aurelia"
	# Enough of everything to buy and build anything straight away.
	Game.coins = 10000000
	Game.aureus = 1000
	Game.build_speed = 5.0
	Game.levels["storage"] = Balance.get_value("upgrades.storage.values", [12]).size() - 1
	Game.storage = {"stone": 999, "timber": 999, "tiles": 999}
	for item in Balance.get_value("items", {}):
		if String(Balance.get_value("items.%s.kind" % item, "good")) == "good":
			Game.storage[item] = 4
	Game.storage["bread"] = 15
	var stages := [1.0, 1.0, 0.7, 1.0, 0.4, 1.0, 1.0, 0.1, 1.0, 1.0, 0.8, 1.0, 1.0, 0.3, 1.0, 1.0, 0.0]
	for i in Game.plots.size():
		var p: Dictionary = Game.plots[i]
		if p["zone"] == "home":
			p["unlocked"] = i < 15 or i >= Game.plots.size() - 5
			if p["unlocked"]:
				p["crop"] = ["lavender", "lavender", "lavender_violet", "lavender", "lavender_bluegrey", "lavender", "lavender_white", "wheat"][i % 8]
				p["growth"] = stages[i % stages.size()] * Game.time_to_ready(p)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			Game.day_time = float(arg.trim_prefix("--hour="))
		elif arg.begins_with("--villa="):
			Game.villa_stage = int(arg.trim_prefix("--villa="))
		elif arg.begins_with("--aurora"):
			var shape := arg.trim_prefix("--aurora=") if "=" in arg else ""
			(func() -> void: m._sky_view.force_aurora = true; m._sky_view.aurora_shape = shape).call_deferred()
		elif arg.begins_with("--furnish="):
			var which := arg.trim_prefix("--furnish=")
			for id in Balance.get_value("interior.furnishings", {}):
				if which == "all" or id in which.split(","):
					Game.furnishings[id] = true
		elif arg.begins_with("--inside"):
			# "--inside=list" or "--inside=rug" opens the furnishing window too.
			var open := arg.trim_prefix("--inside=") if "=" in arg else "-"
			(func() -> void:
				m.hud.visible = false
				m.interior.enter()
				if open == "pet":
					m.interior.get_tree().create_timer(1.0).timeout.connect(func(): m.interior._stroke(m.interior._dog))
				elif open != "-":
					m.interior._open("" if open == "list" else open)).call_deferred()
		elif arg.begins_with("--guide"):
			# Uncle Marcus's advice, from the start or from a later step such as "--guide=cart".
			Settings.show_tutorial = true
			var from := arg.trim_prefix("--guide=") if "=" in arg else ""
			for step in Balance.get_value("tutorial", []):
				if String(step["id"]) == from:
					break
				if step["done"].has("stat"):
					Game.stats[step["done"]["stat"]] = int(step["done"].get("at", 1))
		elif arg == "--galaxy":
			(func() -> void: m._sky_view.force_galaxy = true).call_deferred()
		elif arg == "--rainbow":
			(func() -> void: m._sky_view.fx.show_rainbow(40.0)).call_deferred()
		elif arg.begins_with("--weather="):
			Game.calendar.weather = arg.trim_prefix("--weather=")
			Game.calendar.weather_left = 9999.0
			Game.calendar.wet_left = 9999.0 if Game.calendar.weather == "rain" else 0.0
		elif arg.begins_with("--day="):
			Game.calendar.day = int(arg.trim_prefix("--day="))
		elif arg.begins_with("--cart="):
			Game.levels["cart_capacity"] = int(arg.trim_prefix("--cart="))
		elif arg.begins_with("--road="):
			Game.levels["cart_speed"] = int(arg.trim_prefix("--road="))
		elif arg.begins_with("--start="):
			Game.buy_upgrade.call_deferred(arg.trim_prefix("--start="))
		elif arg == "--build-villa":
			Game.upgrade_villa.call_deferred()
		elif arg == "--send-cart":
			Game.send_cart.call_deferred()
		elif arg == "--estate":
			demo_estate()
		elif arg == "--maxed":
			demo_estate()
			demo_maxed()
		elif arg.begins_with("--pets="):
			var breeds := arg.trim_prefix("--pets=").split(",")
			Game.pets["dog"]["breed"] = breeds[0]
			Game.pets["dog"]["coat"] = Coats.options("dog", breeds[0]).keys()[0]
			if breeds.size() > 1:
				Game.pets["cat"]["breed"] = breeds[1]
				Game.pets["cat"]["coat"] = Coats.options("cat", breeds[1]).keys()[0]
			m._spawn_pets.call_deferred()
		elif arg == "--greet":
			get_tree().create_timer(1.6).timeout.connect(func():
				for w in m._people() + m.market._folk:
					w.greet()
				# The first person in view also says something, to see the speech bubble.
				var view := Rect2(m._camera.position, m._view_size())
				for w in m._people():
					if view.has_point(w.position):
						m.hud.say(w.position + Vector2(0, -46) - m._camera.position, w.saying())
						break)
		elif arg.begins_with("--achievement"):
			# The named achievements, or the next two not yet earned, to see their cards slide in one after the other.
			var named := arg.trim_prefix("--achievement=").split(",") if "=" in arg else PackedStringArray()
			var fresh: Array = Balance.get_value("achievements", []).filter(func(a): return not a.get("special", false) and (a["id"] in named if not named.is_empty() else not Game.journal.achievements.has(a["id"])))
			for a in fresh.slice(0, 2 if named.is_empty() else named.size()):
				Game.achievement_unlocked.emit.call_deferred(a)
		elif arg == "--triumph":
			for a in Balance.get_value("achievements", []):
				if not a.get("special", false):
					Game.journal.achievements[a["id"]] = true
			Game.check_achievements.call_deferred()


## Shows the whole estate in use: every zone owned, a mix of building states, helpers at work, animals and decorations.
func demo_estate() -> void:
	Game.villa_stage = maxi(Game.villa_stage, 5)
	for z in Game.zones_owned:
		Game.zones_owned[z] = true
	for c in Balance.get_value("crops", {}):
		Game.unlock_crop(c)
	var looks := {"drying_shed": "working", "mill": "working", "bakery": "repairing", "beehives": "working", "olive_press": "owned",
		"unguent": "ruin", "wine_press": "working", "cellar": "working", "barn": "working", "dairy": "repairing", "lararium": "working"}
	for id in looks:
		Game.buildings[id]["state"] = looks[id]
		Game.buildings[id]["time_left"] = float(Game.building_info(id).get("repair_seconds", 60)) * 0.8
	Game.buildings["mill"]["busy"] = true
	Game.buildings["mill"]["progress"] = 12.0
	Game.buildings["cellar"]["casks"] = [100.0, 2000.0, 4000.0]
	Game.buildings["barn"]["animals"] = {"chicken": 5, "goat": 3}
	Game.buildings["barn"]["feed"] = 12
	for h in ["farmhand", "miller", "beekeeper", "presser", "stablehand", "perfumer", "trader"]:
		Game.helpers[h] = 1
	for d in ["statue", "lanterns", "planters", "fountain", "bench", "dovecote", "column", "sundial", "birdbath", "pergola"]:
		Game.decorations[d] = true
	Game.levels["channels"] = 1
	Game.storage.merge({"lavender@1": 2, "bread@2": 1}, true)
	var fills := {"grove": [1.0, 0.5, 1.0, 0.2, 1.0, 0.8], "vineyard": [1.0, 0.7, 1.0, 0.3, 1.0, 0.6]}
	var counts := {"grove": 0, "vineyard": 0}
	for i in Game.plots.size():
		var zone := String(Game.plots[i]["zone"])
		if fills.has(zone):
			Game.plots[i]["unlocked"] = true
			var olive: bool = counts[zone] % 3 != 1 and counts[zone] < 6
			Game.plots[i]["crop"] = ("olives" if olive else "herbs") if zone == "grove" else "grapes"
			Game.plots[i]["growth"] = fills[zone][counts[zone] % fills[zone].size()] * Game.time_to_ready(Game.plots[i])
			counts[zone] += 1
	Game.market.add_order()
	Game.market.add_order()


## Everything at its best: the grand estate, every building working at its top level, every helper fully trained, every
## upgrade bought, every bed planted and every page of the journal found.
func demo_maxed() -> void:
	Game.quiet = true
	Game.villa_stage = Game.villa_stages().size()
	for id in Game.buildings:
		var b: Dictionary = Game.buildings[id]
		b["state"] = "working"
		b["level"] = Game.building_info(id).get("levels", []).size()
	var barn: Dictionary = Game.buildings["barn"]
	for kind in ["chicken", "goat"]:
		barn["animals"][kind] = Game.animal_capacity(kind)
	barn["feed"] = 40
	for h in Balance.get_value("helpers", {}):
		Game.helpers[h] = Game.helper_info(h).get("costs", [0]).size()
	for u in Game.levels:
		Game.levels[u] = Balance.get_value("upgrades.%s.values" % u, [0]).size() - 1
	for d in Balance.get_value("decorations", {}):
		Game.decorations[d] = true
	var home_crops := ["lavender", "lavender_violet", "lavender_bluegrey", "lavender_white", "wheat", "lavender"]
	for i in Game.plots.size():
		var p: Dictionary = Game.plots[i]
		p["unlocked"] = true
		if p["zone"] == "home":
			p["crop"] = home_crops[i % home_crops.size()]
			p["growth"] = (1.0 if i % 3 != 1 else 0.6) * Game.time_to_ready(p)
	for entry in Game.journal.catalogue():
		Game.discover(String(entry["id"]))
	# The trader would carry the full storehouse off at once, so every good starts marked to keep.
	for item in Balance.get_value("items", {}):
		Game.keep_goods[item] = true
	# A finished farm has earned every achievement already, the Triumph too, so none chimes in once play starts.
	for ach in Balance.get_value("achievements", []):
		Game.journal.achievements[ach["id"]] = true
	Game.quiet = false
