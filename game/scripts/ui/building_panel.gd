extends "res://scripts/ui/window_panel.gd"
## The window for one building or the villa: its state, what it does, and the next step with exactly what that step needs.

## The id the panel uses for the farmhouse, which is not one of the estate's workshops.
const VILLA := "villa"
const WIDTH := 230

var id := ""
var _status: Label
var _bar: ProgressBar
var _costs: Array = []
var _action: Button
var _note: Label
var _queue: Label
var _load: Button
var _casks: Label
var _feed: Label
var _offer_buttons := {}
var _blessing: Label
## How much of each ingredient and product the storehouse holds, by item, kept up to date while the window is open.
var _stock := {}


func signature() -> String:
	if id == VILLA:
		return "villa%d%s" % [Game.villa_stage, Game.villa_build["active"]]
	var b: Dictionary = Game.buildings[id]
	return "%s|%s|%d|%d|%s|%s|%d|%s|%s" % [id, b["state"], int(b["level"]), int(b["recipe"]), b["paused"], Game.helpers.has(String(Game.building_info(id).get("helper", ""))),
		Game.recipes(id).size(), Game.blessing.get("god", ""), JSON.stringify(b["animals"])]


func build() -> void:
	_offer_buttons = {}
	_costs = []
	_stock = {}
	for field in ["_bar", "_action", "_note", "_queue", "_load", "_casks", "_feed", "_blessing"]:
		set(field, null)
	if id == VILLA:
		_build_villa()
		return
	var info := Game.building_info(id)
	var b: Dictionary = Game.buildings[id]
	var levels: Array = info.get("levels", [])
	var level := ("   " + tr("Level %d of %d") % [int(b["level"]) + 1, levels.size() + 1]) if b["state"] == "working" and not levels.is_empty() else ""
	set_title(tr(String(info.get("name", id))) + level)
	_status = UiKit.para(body, "", WIDTH)
	_status.add_theme_color_override("font_color", UiKit.FADED)
	match b["state"]:
		"ruin":
			UiKit.section(body, tr("For sale"))
			_next_step(Game.building_action(id)["cost"], tr("Buy this ruin"))
		"owned":
			UiKit.section(body, tr("Repairs"))
			UiKit.para(body, tr("Builders work on it for %s once the repairs begin.") % UiKit.duration(float(info.get("repair_seconds", 30)) / Game.build_speed), WIDTH)
			_next_step(Game.building_action(id)["cost"], tr("Start the repairs"))
		"repairing", "upgrading":
			_bar = UiKit.progress(body)
		"working":
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
				UiKit.section(body, tr("Upgrade to level %d") % (int(b["level"]) + 2))
				UiKit.para(body, _upgrade_text(levels[int(b["level"])]), WIDTH)
				UiKit.para(body, tr("Builders work on it for %s, and it makes nothing meanwhile.") % UiKit.duration(Game.building_upgrade_seconds(id) / Game.build_speed), WIDTH).add_theme_color_override("font_color", UiKit.FADED)
				_next_step(act["cost"], tr("Upgrade"))
			if Game.building_kind(id) == "workshop":
				UiKit.button(body, tr("Resume work") if b["paused"] else tr("Pause work"), func(): Game.set_building_paused(id, not b["paused"]))


## A checklist of what the next step needs, and the button that takes it.
func _next_step(cost: Dictionary, verb: String) -> void:
	_costs = UiKit.cost_list(body, cost)
	_action = UiKit.button(body, verb, _do_action)
	_note = UiKit.label(body)
	_note.add_theme_color_override("font_color", UiKit.SHORT)


func _upgrade_text(next: Dictionary) -> String:
	var parts := [tr("Works %s times as fast") % str(next.get("speed", 1))]
	if int(next.get("batch", 1)) > 1:
		parts.append(tr("makes %d at a time") % int(next["batch"]))
	if next.has("queue"):
		parts.append(tr("holds %d batches") % int(next["queue"]))
	if int(next.get("quality", 0)) > 0:
		parts.append(tr("makes better goods"))
	return ", ".join(parts) + "."


func tick() -> void:
	if id == VILLA:
		_tick_villa()
		return
	var b: Dictionary = Game.buildings[id]
	var info := Game.building_info(id)
	match b["state"]:
		"ruin":
			var block := Game.building_block(id)
			_status.text = tr("An old ruin. %s.") % tr(block) if block != "" else tr("An old ruin, waiting for someone to bring it back.")
		"owned":
			_status.text = tr("Yours, but still in ruins.")
		"repairing":
			_status.text = _work_text(tr("Builders at work: %s left"), float(b["time_left"]))
			if _bar:
				_bar.value = 1.0 - float(b["time_left"]) / float(info.get("repair_seconds", 30))
		"upgrading":
			_status.text = _work_text(tr("Builders are taking it to level %d: %%s left") % (int(b["level"]) + 2), float(b["time_left"]))
			if _bar:
				_bar.value = 1.0 - float(b["time_left"]) / Game.building_upgrade_seconds(id)
		"working":
			_status.text = _working_status()
			if _bar:
				# An idle workshop says so in words, so an empty bar would only take up room.
				_bar.visible = b["busy"]
				_bar.value = float(b["progress"]) / float(Game.current_recipe(id).get("seconds", 30)) if b["busy"] else 0.0
	_tick_action(Game.building_action(id).get("cost", {}), Game.building_block(id))
	if _queue:
		_queue.text = tr("Batches waiting: %d of %d") % [b["queue"].size(), Game.building_queue_max(id)]
	if not _stock.is_empty():
		_tick_stock()
	if _load:
		_load.disabled = b["queue"].size() >= Game.building_queue_max(id)
	if _casks:
		_casks.text = _cask_text()
	if _feed:
		_feed.text = tr("Feed in the troughs: %d of %d") % [int(b["feed"]), Game.feed_capacity(id)]
	if _blessing:
		_blessing.text = tr("%s blesses the estate: %s left") % [tr(String(Game.gods()[Game.blessing["god"]]["name"])), UiKit.duration(float(Game.blessing["time_left"]))] if not Game.blessing.is_empty() else tr("Leave an offering for one blessing at a time.")
		for god in _offer_buttons:
			_offer_buttons[god].disabled = not Game.blessing.is_empty() or Game.missing(Game.gods()[god]["offering"]) != ""


func _tick_action(cost: Dictionary, block: String) -> void:
	UiKit.update_costs(_costs)
	if not _action:
		return
	_action.disabled = block != "" or Game.missing(cost) != ""
	# What is short is already shown in red on the cost lines above, so only a reason those lines cannot show is spelled out.
	_note.text = tr(block)
	_note.visible = block != ""


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
				return tr("The animals are resting: the troughs are empty.")
			return tr("Next eggs and milk in %s") % UiKit.duration((float(Game.building_info(id).get("cycle_seconds", 60)) - float(b["progress"])) / Game.building_speed(id))
		"shrine":
			return tr("The household gods watch over the estate.")
	if b["paused"]:
		return tr("Paused")
	if b["busy"]:
		if float(b["progress"]) >= float(Game.current_recipe(id).get("seconds", 30)):
			return tr("Done, waiting for room in the storehouse")
		return tr("Working")
	if Game.current_recipe(id).get("in", {}).is_empty():
		return tr("The bees are out among the flowers")
	return tr("Idle: load it from the storehouse")


func _build_workshop() -> void:
	UiKit.section(body, tr("Makes"))
	var list := Game.recipes(id)
	if list.size() > 1:
		var r := UiKit.row(body)
		for k in list.size():
			var outs: Dictionary = list[k]["out"]
			var choice := UiKit.button(r, tr(String(Balance.get_value("items.%s.name" % outs.keys()[0], ""))), func(): Game.set_recipe(id, k))
			choice.toggle_mode = true
			choice.button_pressed = int(Game.buildings[id]["recipe"]) == k
	var recipe := Game.current_recipe(id)
	var line := UiKit.row(body)
	var ins: Dictionary = recipe.get("in", {})
	for item in ins:
		UiKit.icon(line, item)
	UiKit.label(line, (UiKit.goods_text(_scaled(ins)) if not ins.is_empty() else tr("Flowers nearby")) + "  >")
	for item in recipe.get("out", {}):
		UiKit.icon(line, item)
	UiKit.label(line, UiKit.goods_text(_scaled(recipe.get("out", {}))))
	UiKit.label(body, tr("Each batch takes %s") % UiKit.duration(float(recipe.get("seconds", 30)) / Game.building_speed(id))).add_theme_color_override("font_color", UiKit.FADED)
	_bar = UiKit.progress(body)
	if recipe.get("lavender_honey", false):
		UiKit.para(body, tr("When lavender blooms on the farm, the bees make lavender honey."), WIDTH)
	_build_stock(ins, recipe.get("out", {}))
	if ins.is_empty():
		return
	UiKit.section(body, tr("Loading"))
	_queue = UiKit.label(body)
	var helper := String(Game.building_info(id).get("helper", ""))
	if Game.helpers.has(helper):
		UiKit.para(body, tr("%s keeps it loaded from the storehouse.") % Game.helper_info(helper).get("name", ""), WIDTH)
	else:
		_load = UiKit.button(body, tr("Load from the storehouse"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("Not enough in the storehouse")))
		if helper != "":
			UiKit.para(body, tr("Hire %s the %s to keep it loaded.") % [Game.helper_info(helper).get("name", ""), UiKit.mid(tr(String(Game.helper_info(helper).get("role", ""))))], WIDTH).add_theme_color_override("font_color", UiKit.FADED)


## What the storehouse holds of everything this workshop uses and makes, so the player can see at a glance how many
## batches are left before it runs dry.
func _build_stock(ins: Dictionary, outs: Dictionary) -> void:
	UiKit.section(body, tr("In the storehouse"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	body.add_child(grid)
	for item in ins.keys() + outs.keys():
		if _stock.has(item):
			continue
		var r := UiKit.row(grid)
		UiKit.icon(r, item)
		var l := UiKit.label(r)
		l.set_meta("per_batch", int(ins.get(item, 0)) * Game.building_batch(id))
		_stock[item] = l
	_tick_stock()


func _tick_stock() -> void:
	for item in _stock:
		var l: Label = _stock[item]
		var have := Game.count_item(item)
		var per := int(l.get_meta("per_batch"))
		var name := tr(Game.item_name(item))
		if per > 0:
			var batches := floori(float(have) / per)
			l.text = "%s  %d  (%s)" % [name, have, UiKit.plural(batches, "batch", "batches")]
			l.add_theme_color_override("font_color", UiKit.INK if have >= per else UiKit.SHORT)
		else:
			l.text = "%s  %d" % [name, have]


func _scaled(goods: Dictionary) -> Dictionary:
	var out := {}
	for item in goods:
		out[item] = int(goods[item]) * Game.building_batch(id)
	return out


func _build_cellar() -> void:
	UiKit.section(body, tr("Casks"))
	_casks = UiKit.para(body, "", WIDTH)
	var r := UiKit.row(body)
	UiKit.button(r, tr("Fill casks"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("No young wine, or no empty casks")))
	UiKit.button(r, tr("Draw wine"), func(): if Game.draw_wine(id) == 0: Game.message.emit(tr("No wine is ready yet")))
	if Game.helpers.has("presser"):
		UiKit.para(body, tr("Titus fills the casks and draws the wine when it is excellent."), WIDTH)


func _cask_text() -> String:
	var b: Dictionary = Game.buildings[id]
	var names: Array = Balance.get_value("quality.names", ["Common", "Fine", "Excellent"])
	var counts := {-1: 0, 0: 0, 1: 0, 2: 0}
	for age in b["casks"]:
		counts[Game.cask_quality(float(age), id)] += 1
	var lines := [tr("%d of %d casks in use") % [b["casks"].size(), Game.cellar_capacity(id)]]
	if counts[-1] > 0:
		lines.append(tr("Still resting: %d") % counts[-1])
	for q in 3:
		if counts[q] > 0:
			lines.append(tr("Ready as %s wine: %d") % [UiKit.mid(tr(String(names[q]))), counts[q]])
	return "\n".join(lines)


func _build_barn() -> void:
	var b: Dictionary = Game.buildings[id]
	UiKit.section(body, tr("Animals"))
	for kind in ["chicken", "goat"]:
		UiKit.label(body, "%s: %d of %d" % [tr("Hens" if kind == "chicken" else "Goats"), int(b["animals"].get(kind, 0)), Game.animal_capacity(kind, id)])
	UiKit.para(body, tr("Hens lay eggs and goats give milk; all of them leave manure for the fields."), WIDTH).add_theme_color_override("font_color", UiKit.FADED)
	UiKit.section(body, tr("Feed"))
	_feed = UiKit.label(body)
	if Game.helpers.has("stablehand"):
		UiKit.para(body, tr("Julia keeps the troughs full."), WIDTH)
	else:
		UiKit.button(body, tr("Fill the troughs with straw or wheat"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("No straw or wheat in the storehouse")))


func _build_shrine() -> void:
	UiKit.section(body, tr("Offerings"))
	_blessing = UiKit.para(body, "", WIDTH)
	var list := UiKit.scroll(body, Vector2(WIDTH + 10, 110))
	for god in Game.gods():
		var g: Dictionary = Game.gods()[god]
		var r := UiKit.row(list)
		var b := UiKit.button(r, tr("Offer"), func(): Game.offer(god))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_offer_buttons[god] = b
		UiKit.para(r, "%s: %s (%s)" % [tr(String(g["name"])), tr(String(g["does"])), UiKit.cost_text(g["offering"])], WIDTH - 40)


func _do_action() -> void:
	Game.do_building_action(id)


func _build_villa() -> void:
	var stages := Game.villa_stages()
	var stage := clampi(Game.villa_stage - 1, 0, stages.size() - 1)
	set_title(tr(String(stages[stage]["name"])) + "   " + tr("Stage %d of %d") % [Game.villa_stage, stages.size()])
	_status = UiKit.para(body, "", WIDTH)
	_status.add_theme_color_override("font_color", UiKit.FADED)
	if not Windowing.strip:
		UiKit.button(body, tr("Go inside"), func(): get_tree().call_group("hud", "request_house"))
	if Game.villa_build["active"]:
		_bar = UiKit.progress(body)
		return
	if Game.villa_stage >= stages.size() or Game.demo_capped_villa():
		return
	var next: Dictionary = stages[Game.villa_stage]
	UiKit.section(body, tr("Next improvement: %s") % tr(String(next["name"])))
	UiKit.para(body, tr("Brings: %s.") % tr(String(next.get("unlocks", ""))), WIDTH)
	UiKit.para(body, tr("Builders work on it for %s.") % UiKit.duration(float(next.get("build_seconds", 0)) / Game.build_speed), WIDTH).add_theme_color_override("font_color", UiKit.FADED)
	_costs = UiKit.cost_list(body, Game.villa_next_price())
	_action = UiKit.button(body, tr("Build the %s") % UiKit.mid(tr(String(next["name"]))), func(): Game.upgrade_villa())
	_note = UiKit.label(body)
	_note.add_theme_color_override("font_color", UiKit.SHORT)
	if Game.count_item("stone") + Game.count_item("tiles") + Game.count_item("timber") == 0:
		UiKit.para(body, tr("Stone, timber and roof tiles are sold at the market town."), WIDTH).add_theme_color_override("font_color", UiKit.FADED)


## Building work stops at night, so then the time left stands still and the window says why.
func _work_text(day_text: String, left: float) -> String:
	# Times are shown as they will pass on the clock, which a faster build speed shortens.
	var real := left / Game.build_speed
	if Game.is_night():
		return tr("The builders have gone home for the night and come back in %s. %s of work left.") % [UiKit.duration(Game.seconds_until_day()), UiKit.duration(real)]
	return day_text % UiKit.duration(real)


func _tick_villa() -> void:
	var stages := Game.villa_stages()
	if Game.villa_build["active"]:
		var next: Dictionary = stages[mini(Game.villa_stage, stages.size() - 1)]
		_status.text = _work_text(tr("Builders at work on the %s: %%s left") % UiKit.mid(tr(String(next["name"]))), float(Game.villa_build["time_left"]))
		if _bar:
			_bar.value = 1.0 - float(Game.villa_build["time_left"]) / maxf(1.0, float(next.get("build_seconds", 1)))
	elif Game.villa_stage >= stages.size():
		_status.text = tr("Fully restored. The grand estate is complete.")
	elif Game.demo_capped_villa():
		_status.text = tr("The rest of the villa's story is in the full game. Thank you for playing the demo!")
	else:
		_status.text = tr("Your home. Each improvement changes how the villa looks and opens up more of the estate.")
	_tick_action(Game.villa_next_price(), "")
