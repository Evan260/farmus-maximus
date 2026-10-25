extends "res://scripts/ui/window_panel.gd"
## The window for one building: buying and repairing it, then whatever it does once it works, and its upgrades.

## The id the panel uses for the farmhouse, which is not one of the estate's workshops.
const VILLA := "villa"

var id := ""
var _status: Label
var _queue: Label
var _action: Button
var _action_note: Label
var _load: Button
var _casks: Label
var _feed: Label
var _offer_buttons := {}
var _blessing: Label


func signature() -> String:
	if id == VILLA:
		return "villa%d%s" % [Game.villa_stage, Game.villa_build["active"]]
	var b: Dictionary = Game.buildings[id]
	return "%s|%s|%d|%d|%s|%s|%d|%s|%s" % [id, b["state"], int(b["level"]), int(b["recipe"]), b["paused"], Game.helpers.has(String(Game.building_info(id).get("helper", ""))),
		Game.recipes(id).size(), Game.blessing.get("god", ""), JSON.stringify(b["animals"])]


func build() -> void:
	_offer_buttons = {}
	_queue = null
	_load = null
	_action = null
	_casks = null
	_feed = null
	_blessing = null
	if id == VILLA:
		_build_villa()
		return
	var info := Game.building_info(id)
	var b: Dictionary = Game.buildings[id]
	var levels: Array = info.get("levels", [])
	var level_text := ("   " + tr("Level %d of %d") % [int(b["level"]) + 1, levels.size() + 1]) if b["state"] == "working" and not levels.is_empty() else ""
	set_title(tr(String(info.get("name", id))) + level_text)
	_status = UiKit.para(body, "", 230)
	if b["state"] == "working":
		match Game.building_kind(id):
			"cellar":
				_build_cellar()
			"barn":
				_build_barn()
			"shrine":
				_build_shrine()
			_:
				_build_workshop()
	var act := Game.building_action(id)
	if not act.is_empty():
		var r := UiKit.row(body)
		_action = UiKit.button(r, "", _do_action)
		_action_note = UiKit.label(r)
	if b["state"] == "working" and Game.building_kind(id) == "workshop":
		UiKit.button(body, tr("Resume") if b["paused"] else tr("Pause"), func(): Game.set_building_paused(id, not b["paused"]))


func tick() -> void:
	if id == VILLA:
		_tick_villa()
		return
	var b: Dictionary = Game.buildings[id]
	var info := Game.building_info(id)
	match b["state"]:
		"ruin":
			var block := Game.building_block(id)
			_status.text = tr("A ruin. %s.") % block if block != "" else tr("A ruin, for sale.")
		"owned":
			_status.text = tr("Yours, but in ruins. Repair it to put it to work.")
		"repairing":
			_status.text = tr("Being repaired: %s left") % UiKit.duration(float(b["time_left"]))
		"working":
			_status.text = _working_status()
	if _action and is_instance_valid(_action):
		var act := Game.building_action(id)
		if not act.is_empty():
			var label: String = {"buy": "Buy", "repair": "Repair", "upgrade": "Upgrade"}[act["action"]]
			_action.text = "%s: %s" % [tr(label), UiKit.cost_text(act["cost"])]
			var problem := Game.building_block(id)
			if problem == "":
				problem = Game.missing(act["cost"])
			_action.disabled = problem != ""
			_action_note.text = tr(problem)
			if act["action"] == "upgrade":
				var next: Dictionary = info["levels"][int(b["level"])]
				_action_note.text = tr(problem) if problem != "" else tr("x%s speed") % str(next.get("speed", 1))
	if _queue and is_instance_valid(_queue):
		_queue.text = tr("Loaded: %d of %d batches") % [b["queue"].size() + (1 if b["busy"] else 0), Game.building_queue_max(id) + 1]
		if _load and is_instance_valid(_load):
			_load.disabled = b["queue"].size() >= Game.building_queue_max(id)
	if _casks and is_instance_valid(_casks):
		_casks.text = _cask_text()
	if _feed and is_instance_valid(_feed):
		_feed.text = tr("Feed in the troughs: %d of %d") % [int(b["feed"]), Game.feed_capacity(id)]
	if _blessing and is_instance_valid(_blessing):
		_blessing.text = tr("%s blesses the estate: %s left") % [tr(String(Game.gods()[Game.blessing["god"]]["name"])), UiKit.duration(float(Game.blessing["time_left"]))] if not Game.blessing.is_empty() else tr("Leave an offering for one blessing at a time.")
		for god in _offer_buttons:
			_offer_buttons[god].disabled = not Game.blessing.is_empty() or Game.missing(Game.gods()[god]["offering"]) != ""


func _working_status() -> String:
	var b: Dictionary = Game.buildings[id]
	match Game.building_kind(id):
		"cellar":
			return tr("Wine rests here and improves with time.")
		"barn":
			var herd := 0
			for kind in b["animals"]:
				herd += int(b["animals"][kind])
			if herd == 0:
				return tr("Empty. Buy hens and goats at the market.")
			if int(b["feed"]) == 0:
				return tr("The animals are resting: there is no feed.")
			return tr("Next eggs and milk in %s") % UiKit.duration((float(Game.building_info(id).get("cycle_seconds", 60)) - float(b["progress"])) / Game.building_speed(id))
		"shrine":
			return tr("The household gods watch over the estate.")
	if b["paused"]:
		return tr("Paused")
	if b["busy"]:
		var seconds := float(Game.current_recipe(id).get("seconds", 30))
		if float(b["progress"]) >= seconds:
			return tr("Done, waiting for room in the storehouse")
		return tr("Working: %d%%") % int(100.0 * float(b["progress"]) / seconds)
	if Game.current_recipe(id).get("in", {}).is_empty():
		return tr("The bees are at work")
	return tr("Waiting to be loaded")


func _build_workshop() -> void:
	var list := Game.recipes(id)
	if list.size() > 1:
		var r := UiKit.row(body)
		for k in list.size():
			var outs: Dictionary = list[k]["out"]
			var b := UiKit.button(r, tr(String(Balance.get_value("items.%s.name" % outs.keys()[0], ""))), func(): Game.set_recipe(id, k))
			b.toggle_mode = true
			b.button_pressed = int(Game.buildings[id]["recipe"]) == k
	var recipe := Game.current_recipe(id)
	var line := UiKit.row(body)
	var ins: Dictionary = recipe.get("in", {})
	for item in ins:
		UiKit.icon(line, item)
	UiKit.label(line, (UiKit.goods_text(_scaled(ins)) if not ins.is_empty() else tr("Flowers nearby")) + "  >")
	for item in recipe.get("out", {}):
		UiKit.icon(line, item)
	UiKit.label(line, "%s  (%s)" % [UiKit.goods_text(_scaled(recipe.get("out", {}))), UiKit.duration(float(recipe.get("seconds", 30)) / Game.building_speed(id))])
	if recipe.get("lavender_honey", false):
		UiKit.para(body, tr("When lavender blooms on the farm, the bees make lavender honey."), 230)
	if ins.is_empty():
		return
	_queue = UiKit.label(body)
	var helper := String(Game.building_info(id).get("helper", ""))
	if Game.helpers.has(helper):
		UiKit.para(body, tr("%s keeps it loaded from the storehouse.") % Game.helper_info(helper).get("name", ""), 230)
	else:
		_load = UiKit.button(body, tr("Load from the storehouse"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("Not enough in the storehouse")))
		if helper != "":
			UiKit.para(body, tr("Hire %s the %s to keep it loaded.") % [Game.helper_info(helper).get("name", ""), tr(String(Game.helper_info(helper).get("role", ""))).to_lower()], 230)


func _scaled(goods: Dictionary) -> Dictionary:
	var out := {}
	for item in goods:
		out[item] = int(goods[item]) * Game.building_batch(id)
	return out


func _build_cellar() -> void:
	_casks = UiKit.para(body, "", 230)
	var r := UiKit.row(body)
	UiKit.button(r, tr("Fill casks"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("No young wine, or no empty casks")))
	UiKit.button(r, tr("Draw wine"), func(): if Game.draw_wine(id) == 0: Game.message.emit(tr("No wine is ready yet")))
	if Game.helpers.has("presser"):
		UiKit.para(body, tr("Titus fills the casks and draws the wine when it is excellent."), 230)


func _cask_text() -> String:
	var b: Dictionary = Game.buildings[id]
	var names: Array = Balance.get_value("quality.names", ["Common", "Fine", "Excellent"])
	var counts := {-1: 0, 0: 0, 1: 0, 2: 0}
	for age in b["casks"]:
		counts[Game.cask_quality(float(age), id)] += 1
	var text := tr("Casks: %d of %d") % [b["casks"].size(), Game.cellar_capacity(id)]
	if counts[-1] > 0:
		text += "\n" + tr("Still resting: %d") % counts[-1]
	for q in 3:
		if counts[q] > 0:
			text += "\n" + tr("Ready as %s wine: %d") % [tr(String(names[q])).to_lower(), counts[q]]
	return text


func _build_barn() -> void:
	var b: Dictionary = Game.buildings[id]
	for kind in ["chicken", "goat"]:
		UiKit.label(body, "%s: %d of %d" % [tr("Hens" if kind == "chicken" else "Goats"), int(b["animals"].get(kind, 0)), Game.animal_capacity(kind, id)])
	_feed = UiKit.label(body)
	if Game.helpers.has("stablehand"):
		UiKit.para(body, tr("Julia keeps the troughs full."), 230)
	else:
		UiKit.button(body, tr("Fill the troughs with straw or wheat"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("No straw or wheat in the storehouse")))
	UiKit.para(body, tr("Hens lay eggs and goats give milk; all of them leave manure for the fields."), 230)


func _build_shrine() -> void:
	_blessing = UiKit.para(body, "", 230)
	var list := UiKit.scroll(body, Vector2(240, 120))
	for god in Game.gods():
		var g: Dictionary = Game.gods()[god]
		var r := UiKit.row(list)
		var b := UiKit.button(r, tr("Offer"), func(): Game.offer(god))
		_offer_buttons[god] = b
		UiKit.para(r, "%s: %s (%s)" % [tr(String(g["name"])), tr(String(g["does"])), UiKit.cost_text(g["offering"])], 190)


func _do_action() -> void:
	Game.do_building_action(id)


func _build_villa() -> void:
	var stages := Game.villa_stages()
	set_title(tr(String(stages[clampi(Game.villa_stage - 1, 0, stages.size() - 1)]["name"])))
	_status = UiKit.para(body, "", 230)
	if Game.villa_stage < stages.size() and not Game.villa_build["active"]:
		var next: Dictionary = stages[Game.villa_stage]
		UiKit.para(body, tr("Next: %s") % tr(String(next["name"])), 230)
		UiKit.para(body, tr("Brings: %s") % tr(String(next.get("unlocks", ""))), 230)
		_action = UiKit.button(body, "", func(): Game.upgrade_villa())
		_action_note = UiKit.para(body, "", 230)


func _tick_villa() -> void:
	var stages := Game.villa_stages()
	if Game.villa_build["active"]:
		_status.text = tr("Being restored: %s left") % UiKit.duration(float(Game.villa_build["time_left"]))
	elif Game.villa_stage >= stages.size():
		_status.text = tr("Fully restored. The grand estate is complete.")
	elif Game.demo_capped_villa():
		_status.text = tr("The rest of the villa's story is in the full game. Thank you for playing the demo!")
	else:
		_status.text = tr("Home of the estate.")
	if _action and is_instance_valid(_action):
		var price := Game.villa_next_price()
		_action.visible = not price.is_empty()
		_action.text = tr("Restore: %s") % UiKit.cost_text(price)
		var problem := Game.missing(price)
		_action.disabled = problem != ""
		_action_note.text = tr(problem)
