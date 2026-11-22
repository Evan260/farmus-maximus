extends RefCounted
## When the farm will next want the player, worked out as a phone puts the game away so the phone can say so at the
## time: the cart home from market, the storehouse and parked cart full, and the builders done. Nothing is planned
## past the limit on time away, after which the farm stops counting.


## Each notice as {id, seconds, title, text}, soonest first; the phone replaces a waiting notice that has the same id.
static func plan(game: Node) -> Array:
	var notices := []
	# With progress while closed turned off the farm waits exactly as it was left, so nothing will happen to tell of.
	if not Settings.offline_progress:
		return notices
	var most := float(Data.get_value("offline.max_hours", 12)) * 3600.0
	if Settings.notify_cart and game.cart["away"] and float(game.cart["time_left"]) <= most:
		notices.append(_notice("cart", float(game.cart["time_left"]), "The cart is home",
			TranslationServer.translate("The cart is back from market with %d sestertii.") % int(game.cart["value"])))
	if Settings.notify_full:
		var at := fills_in(game, most)
		if at >= 0.0:
			notices.append(_notice("full", at, "The storehouse is full",
				TranslationServer.translate("The storehouse and the cart are full: send the cart to market")))
	if Settings.notify_builders:
		notices.append_array(_builders(game, most))
	notices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["seconds"]) < float(b["seconds"]))
	return notices


## The builders' work under way, each with the seconds of work left: the farmhouse's next stage, farm improvements and
## buildings being repaired or raised.
static func builder_jobs(game: Node) -> Array:
	var jobs := []
	if game.villa_build["active"] and game.villa_stage < game.villa_stages().size():
		jobs.append({"id": "build_villa", "work": float(game.villa_build["time_left"]), "name": String(game.villa_stages()[game.villa_stage].get("name", ""))})
	for id in game.projects:
		jobs.append({"id": "build_" + id, "work": float(game.projects[id]), "name": String(game.upgrade_info(id).get("name", ""))})
	for id in game.buildings:
		var b: Dictionary = game.buildings[id]
		if b["state"] in ["repairing", "upgrading"]:
			jobs.append({"id": "build_" + id, "work": float(b["time_left"]), "name": String(game.building_info(id).get("name", ""))})
	return jobs


## When each job is done: builders work only by day, so the clock is walked forward counting the daylight.
static func _builders(game: Node, most: float) -> Array:
	var found := []
	var waiting := builder_jobs(game)
	var step := float(Data.get_value("notifications.step_seconds", 60))
	var hour: float = game.day_time
	var worked := 0.0
	var t := 0.0
	while t < most and not waiting.is_empty():
		var dt := minf(step, most - t)
		hour = fmod(hour + dt * 24.0 / game.day_seconds(), 24.0)
		t += dt
		if Lighting.night_amount(hour) <= 0.5:
			worked += dt * game.build_speed
		for job in waiting.duplicate():
			if worked >= float(job["work"]):
				found.append(_notice(String(job["id"]), t, String(job["name"]), TranslationServer.translate("The work is finished")))
				waiting.erase(job)
	return found


## How many goods until the farm counts as full, with the cart parked in the yard. A plant or batch that does not fit
## whole waits rather than filling the last places, so the last few places are not waited for.
static func room(game: Node) -> int:
	var holds: int = game.storage_capacity() + game.cart_capacity()
	var spare := maxi(int(Data.get_value("notifications.full_room", 3)), ceili(holds * float(Data.get_value("notifications.full_share", 0.05))))
	return holds - game.stored_total() - spare + 1


static func full(game: Node) -> bool:
	return not game.cart["away"] and room(game) <= 0


## Seconds until the storehouse and the parked cart fill up, or -1 if they do not within `most`. A copy of the farm is
## played as the catch-up will play it for up to a day, and the rest is reckoned from how fast it filled meanwhile.
static func fills_in(game: Node, most: float) -> float:
	var copy: Node = game.get_script().new()
	copy.acts_as_demo = game.acts_as_demo
	copy.build_speed = game.build_speed
	copy.from_dict(game.to_dict().duplicate(true))
	copy.quiet = true
	copy._stored = copy.stored_total()
	var start: int = copy.stored_total()
	var step := float(Data.get_value("offline.step_seconds", 5))
	var sample := minf(most, minf(copy.day_seconds(), float(Data.get_value("notifications.sample_seconds", 1200))))
	# A farm already full when put away was left that way, so only filling up again afterwards is news.
	var was_full := full(copy)
	var t := 0.0
	var at := -1.0
	while t < sample and at < 0.0:
		var dt := minf(step, sample - t)
		copy.advance(dt)
		t += dt
		var now_full := full(copy)
		if now_full and not was_full:
			at = t
		was_full = now_full
	var gained: int = copy.stored_total() - start
	if at < 0.0 and gained > 0 and not was_full:
		at = t + room(copy) * t / gained
	copy.free()
	return at if at <= most else -1.0


static func _notice(id: String, seconds: float, title: String, text: String) -> Dictionary:
	return {"id": id, "seconds": seconds, "title": TranslationServer.translate(title), "text": text}
