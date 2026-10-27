extends RefCounted
## The farmer's journal: everything discovered, the milestones, the achievements and the tutorial's progress.

var entries := {}
var achievements := {}
var _game: Node
var _catalogue: Array = []


func _init(game: Node) -> void:
	_game = game


func has(id: String) -> bool:
	return entries.has(id)


## Records a first-time discovery and returns true when it was new.
func add(id: String) -> bool:
	if entries.has(id):
		return false
	entries[id] = true
	return true


## Every page the journal can hold, grouped by section, with the text each page shows.
func catalogue() -> Array:
	if not _catalogue.is_empty():
		return _catalogue
	var add_section := func(section: String, ids: Array, names: Array) -> void:
		for i in ids.size():
			_catalogue.append({"section": section, "id": ids[i], "name": names[i]})
	var crops := []
	var crop_names := []
	for c in Balance.get_value("crops", {}):
		crops.append("crop:" + c)
		crop_names.append(Balance.get_value("crops.%s.name" % c, c))
	add_section.call("Crops", crops, crop_names)
	var goods := []
	var good_names := []
	var quality_names: Array = Balance.get_value("quality.names", ["Common", "Fine", "Excellent"])
	for item in Balance.get_value("items", {}):
		var name := String(Balance.get_value("items.%s.name" % item, item))
		goods.append("item:" + item)
		good_names.append(name)
		if not Balance.get_value("items.%s.no_quality" % item, false):
			for q in [1, 2]:
				goods.append("quality:%s:%d" % [item, q])
				good_names.append("%s %s" % [quality_names[q], name.to_lower()])
	add_section.call("Goods", goods, good_names)
	var buildings := []
	var building_names := []
	for b in Balance.get_value("buildings", {}):
		buildings.append("building:" + b)
		building_names.append(Balance.get_value("buildings.%s.name" % b, b))
	add_section.call("Buildings", buildings, building_names)
	var helpers := []
	var helper_names := []
	for h in Balance.get_value("helpers", {}):
		helpers.append("helper:" + h)
		helper_names.append("%s the %s" % [Balance.get_value("helpers.%s.name" % h, h), String(Balance.get_value("helpers.%s.role" % h, "")).to_lower()])
	add_section.call("Helpers", helpers, helper_names)
	for section in [["Animals", "animals", "animal"], ["Finds", "finds", "find"], ["Sightings", "sightings", "sighting"], ["Milestones", "milestones", "milestone"]]:
		var d: Dictionary = Balance.get_value("journal." + section[1], {})
		add_section.call(section[0], d.keys().map(func(k): return "%s:%s" % [section[2], k]), d.values())
	var festivals: Array = Balance.get_value("calendar.festivals", [])
	add_section.call("Festivals", festivals.map(func(f): return "festival:" + String(f["id"])), festivals.map(func(f): return f["name"]))
	return _catalogue


func share() -> float:
	var all := catalogue()
	var found := 0
	for e in all:
		if entries.has(e["id"]):
			found += 1
	return float(found) / maxf(1.0, float(all.size()))


## True when a condition from the data files holds, such as {"stat": "harvested", "at": 100} or {"villa": 3}.
func met(cond: Dictionary) -> bool:
	if cond.has("stat"):
		return int(_game.stats.get(cond["stat"], 0)) >= int(cond.get("at", 1))
	if cond.has("villa"):
		return _game.villa_stage >= int(cond["villa"])
	if cond.has("zones"):
		return _game.zones_owned.values().count(true) >= int(cond["zones"])
	if cond.has("buildings"):
		return _game.working_buildings() >= int(cond["buildings"])
	if cond.has("helpers"):
		return _game.helpers.size() >= int(cond["helpers"])
	if cond.has("journal"):
		return entries.has(cond["journal"])
	if cond.has("decorations"):
		return _game.decorations.size() >= int(cond["decorations"])
	if cond.has("furnishings"):
		return _game.furnishings.size() >= int(cond["furnishings"])
	if cond.has("journal_share"):
		return share() >= float(cond["journal_share"]) - 0.0001
	if cond.has("achievements"):
		var others := _other_achievements()
		return others.all(func(id): return achievements.has(id))
	return false


## Every achievement except the ones that are earned by earning the rest.
func _other_achievements() -> Array:
	return Balance.get_value("achievements", []).filter(func(a): return not a["when"].has("achievements")).map(func(a): return a["id"])


## How far along a countable condition is, as how many of how many, or an empty array for one that is simply met or not.
func progress(cond: Dictionary) -> Array:
	if cond.has("stat"):
		return [int(_game.stats.get(cond["stat"], 0)), int(cond.get("at", 1))]
	if cond.has("villa"):
		return [_game.villa_stage, int(cond["villa"])]
	if cond.has("zones"):
		return [_game.zones_owned.values().count(true), int(cond["zones"])]
	if cond.has("buildings"):
		return [_game.working_buildings(), int(cond["buildings"])]
	if cond.has("helpers"):
		return [_game.helpers.size(), int(cond["helpers"])]
	if cond.has("decorations"):
		return [_game.decorations.size(), int(cond["decorations"])]
	if cond.has("furnishings"):
		return [_game.furnishings.size(), int(cond["furnishings"])]
	if cond.has("journal_share"):
		return [int(round(share() * 100.0)), int(round(float(cond["journal_share"]) * 100.0))]
	if cond.has("achievements"):
		var others := _other_achievements()
		return [others.filter(func(id): return achievements.has(id)).size(), others.size()]
	return []


## Unlocks every achievement whose condition now holds and returns the new ones.
func check_achievements() -> Array:
	var fresh := []
	for a in Balance.get_value("achievements", []):
		if not achievements.has(a["id"]) and met(a["when"]):
			achievements[a["id"]] = true
			fresh.append(a)
	_check_milestones()
	return fresh


func _check_milestones() -> void:
	if _game.zones_owned.values().count(false) == 0:
		_game.discover("milestone:all_zones")
	if _game.working_buildings() >= Balance.get_value("buildings", {}).size():
		_game.discover("milestone:all_buildings")
	if _game.villa_stage >= _game.villa_stages().size():
		_game.discover("milestone:grand_estate")
	if _game.helpers.size() >= Balance.get_value("helpers", {}).size():
		_game.discover("milestone:all_helpers")
	var all_festivals := true
	for f in Balance.get_value("calendar.festivals", []):
		all_festivals = all_festivals and entries.has("festival:" + String(f["id"]))
	if all_festivals:
		_game.discover("milestone:all_festivals")


## The first tutorial step not yet done, or an empty dictionary when the tutorial is finished.
func tutorial_step() -> Dictionary:
	for step in Balance.get_value("tutorial", []):
		if not met(step["done"]):
			return step
	return {}


func to_dict() -> Dictionary:
	return {"entries": entries, "achievements": achievements}


func from_dict(d: Dictionary) -> void:
	entries = Dictionary(d.get("entries", {}))
	achievements = Dictionary(d.get("achievements", {}))
