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
var _load: Button
var _casks: Label
var _feed: Label
var _offer_buttons := {}
var _blessing: Label
## The furnace-style workshop view: the counts in its slots, the arrow that fills as a batch is made, the boxes for
## batches waiting, the upgrade's cost chips, and a line shown only when the workshop is paused or blocked.
var _in_counts := {}
var _out_counts := {}
var _arrow: WorkshopParts.Arrow
var _queue_boxes: Array = []
var _cost_chips: Array = []
var _state_note: Label


func signature() -> String:
	if id == VILLA:
		return "villa%d%s" % [Game.villa_stage, Game.villa_build["active"]]
	var b: Dictionary = Game.buildings[id]
	return "%s|%s|%d|%d|%s|%s|%d|%s|%s" % [id, b["state"], int(b["level"]), int(b["recipe"]), b["paused"], Game.helpers.has(String(Game.building_info(id).get("helper", ""))),
		Game.recipes(id).size(), Game.blessing.get("god", ""), JSON.stringify(b["animals"])]


func build() -> void:
	_offer_buttons = {}
	_costs = []
	_in_counts = {}
	_out_counts = {}
	_arrow = null
	_queue_boxes = []
	_cost_chips = []
	_state_note = null
	for field in ["_bar", "_action", "_note", "_load", "_casks", "_feed", "_blessing"]:
		set(field, null)
	if id == VILLA:
		_build_villa()
		return
	var info := Game.building_info(id)
	var b: Dictionary = Game.buildings[id]
	var levels: Array = info.get("levels", [])
	if b["state"] == "working" and Game.building_kind(id) == "workshop":
		set_title(tr(String(info.get("name", id))))
		_build_workshop_view()
		return
	var level := ("   " + tr("Level %d of %d") % [int(b["level"]) + 1, levels.size() + 1]) if b["state"] == "working" and not levels.is_empty() else ""
	set_title(tr(String(info.get("name", id))) + level)
	_status = Ui.para(body, "", WIDTH)
	_status.add_theme_color_override("font_color", UiTheme.MUTED)
	match b["state"]:
		"ruin":
			Ui.section(body, tr("For sale"))
			_next_step(Game.building_action(id)["cost"], tr("Buy this ruin"))
		"owned":
			Ui.section(body, tr("Repairs"))
			Ui.para(body, tr("Builders work on it for %s once the repairs begin.") % Ui.duration(float(info.get("repair_seconds", 30)) / Game.build_speed), WIDTH)
			_next_step(Game.building_action(id)["cost"], tr("Start the repairs"))
		"repairing", "upgrading":
			_bar = Ui.progress(body)
		"working":
			match Game.building_kind(id):
				"cellar":
					_build_cellar()
				"barn":
					_build_barn()
				"shrine":
					_build_shrine()
			var act := Game.building_action(id)
			if not act.is_empty():
				Ui.section(body, tr("Upgrade to level %d") % (int(b["level"]) + 2))
				Ui.para(body, _upgrade_text(levels[int(b["level"])]) + " " + tr("Builders work on it for %s, and it makes nothing meanwhile.") % Ui.duration(Game.building_upgrade_seconds(id) / Game.build_speed), WIDTH)
				_next_step(act["cost"], tr("Upgrade"))


## A checklist of what the next step needs, and the button that takes it, on a row other buttons can join.
func _next_step(cost: Dictionary, verb: String) -> HBoxContainer:
	_costs = Ui.cost_list(body, cost)
	var row := Ui.row(body)
	_action = Ui.button(row, verb, _do_action)
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note = Ui.label(body)
	_note.add_theme_color_override("font_color", UiTheme.RED)
	return row


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
	if _arrow:
		_tick_workshop_view()
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
				_bar.value = float(b["progress"]) / Game.batch_seconds(id) if b["busy"] else 0.0
	_tick_action(Game.building_action(id).get("cost", {}), Game.building_block(id))
	if _casks:
		_casks.text = _cask_text()
	if _feed:
		_feed.text = tr("Feed in the troughs: %d of %d") % [int(b["feed"]), Game.feed_capacity(id)]
	if _blessing:
		_blessing.text = tr("%s blesses the estate: %s left") % [tr(String(Game.gods()[Game.blessing["god"]]["name"])), Ui.duration(float(Game.blessing["time_left"]))] if not Game.blessing.is_empty() else tr("Leave an offering for one blessing at a time.")
		for god in _offer_buttons:
			_offer_buttons[god].disabled = not Game.blessing.is_empty() or Game.missing(Game.gods()[god]["offering"]) != ""


func _tick_action(cost: Dictionary, block: String) -> void:
	Ui.update_costs(_costs)
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
			return tr("Next eggs and milk in %s") % Ui.duration((float(Game.building_info(id).get("cycle_seconds", 60)) - float(b["progress"])) / Game.building_speed(id))
		"shrine":
			return tr("The household gods watch over the estate.")
	if b["paused"]:
		return tr("Paused")
	if b["busy"]:
		if float(b["progress"]) >= Game.batch_seconds(id):
			return tr("Done, waiting for room in the storehouse")
		return tr("Working")
	if Game.current_recipe(id).get("in", {}).is_empty():
		return tr("The bees are out among the flowers")
	return tr("Idle: load it from the storehouse")


func _build_cellar() -> void:
	Ui.section(body, tr("Casks"))
	_casks = Ui.para(body, "", WIDTH)
	var r := Ui.row(body)
	Ui.button(r, tr("Fill casks"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("No young wine, or no empty casks")))
	Ui.button(r, tr("Draw wine"), func(): if Game.draw_wine(id) == 0: Game.message.emit(tr("No wine is ready yet")))
	if Game.helpers.has("presser"):
		Ui.para(body, tr("Titus fills the casks and draws the wine when it is excellent."), WIDTH)


func _cask_text() -> String:
	var b: Dictionary = Game.buildings[id]
	var names: Array = Data.get_value("quality.names", ["Common", "Fine", "Excellent"])
	var counts := {-1: 0, 0: 0, 1: 0, 2: 0}
	for age in b["casks"]:
		counts[Game.cask_quality(float(age), id)] += 1
	var lines := [tr("%d of %d casks in use") % [b["casks"].size(), Game.cellar_capacity(id)]]
	if counts[-1] > 0:
		lines.append(tr("Still resting: %d") % counts[-1])
	for q in 3:
		if counts[q] > 0:
			lines.append(tr("Ready as %s wine: %d") % [Ui.mid(tr(String(names[q]))), counts[q]])
	return "\n".join(lines)


func _build_barn() -> void:
	var b: Dictionary = Game.buildings[id]
	Ui.section(body, tr("Animals"))
	for kind in ["chicken", "goat"]:
		Ui.label(body, tr("%s: %d of %d") % [tr("Hens" if kind == "chicken" else "Goats"), int(b["animals"].get(kind, 0)), Game.animal_capacity(kind, id)])
	Ui.para(body, tr("Hens lay eggs and goats give milk; all of them leave manure for the fields."), WIDTH).add_theme_color_override("font_color", UiTheme.MUTED)
	Ui.section(body, tr("Feed"))
	_feed = Ui.label(body)
	if Game.helpers.has("stablehand"):
		Ui.para(body, tr("Julia keeps the troughs full."), WIDTH)
	else:
		Ui.button(body, tr("Fill the troughs with straw or wheat"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("No straw or wheat in the storehouse")))


func _build_shrine() -> void:
	Ui.section(body, tr("Offerings"))
	_blessing = Ui.para(body, "", WIDTH)
	var list := Ui.scroll(body, Vector2(WIDTH + 10, 110))
	for god in Game.gods():
		var g: Dictionary = Game.gods()[god]
		var r := Ui.row(list)
		var b := Ui.button(r, tr("Offer"), func(): Game.offer(god))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_offer_buttons[god] = b
		Ui.para(r, "%s: %s (%s)" % [tr(String(g["name"])), tr(String(g["does"])), Ui.cost_text(g["offering"])], WIDTH - 40)


func _do_action() -> void:
	Game.do_building_action(id)


func _build_villa() -> void:
	var stages := Game.villa_stages()
	var stage := clampi(Game.villa_stage - 1, 0, stages.size() - 1)
	set_title(tr(String(stages[stage]["name"])) + "   " + tr("Stage %d of %d") % [Game.villa_stage, stages.size()])
	_status = Ui.para(body, "", WIDTH)
	_status.add_theme_color_override("font_color", UiTheme.MUTED)
	if not Windowing.strip:
		Ui.button(body, tr("Go inside"), func(): get_tree().call_group("hud", "request_house"))
	if Game.villa_build["active"]:
		_bar = Ui.progress(body)
		return
	if Game.villa_stage >= stages.size() or Game.demo_capped_villa():
		return
	var next: Dictionary = stages[Game.villa_stage]
	Ui.section(body, tr("Next improvement: %s") % tr(String(next["name"])))
	Ui.para(body, tr("Brings: %s.") % tr(String(next.get("unlocks", ""))), WIDTH)
	Ui.para(body, tr("Builders work on it for %s.") % Ui.duration(float(next.get("build_seconds", 0)) / Game.build_speed), WIDTH).add_theme_color_override("font_color", UiTheme.MUTED)
	_costs = Ui.cost_list(body, Game.villa_next_price())
	_action = Ui.button(body, tr("Build the %s") % Ui.mid(tr(String(next["name"]))), func(): Game.upgrade_villa())
	_note = Ui.label(body)
	_note.add_theme_color_override("font_color", UiTheme.RED)
	if Game.count_item("stone") + Game.count_item("tiles") + Game.count_item("timber") == 0:
		Ui.para(body, tr("Stone, timber and roof tiles are sold at the market town."), WIDTH).add_theme_color_override("font_color", UiTheme.MUTED)


## Building work stops at night, so then the time left stands still and the window says why.
func _work_text(day_text: String, left: float) -> String:
	# Times are shown as they will pass on the clock, which a faster build speed shortens.
	var real := left / Game.build_speed
	if Game.is_night():
		return tr("The builders have gone home for the night and come back in %s. %s of work left.") % [Ui.duration(Game.seconds_until_day()), Ui.duration(real)]
	return day_text % Ui.duration(real)


func _tick_villa() -> void:
	var stages := Game.villa_stages()
	if Game.villa_build["active"]:
		var next: Dictionary = stages[mini(Game.villa_stage, stages.size() - 1)]
		_status.text = _work_text(tr("Builders at work on the %s: %%s left") % Ui.mid(tr(String(next["name"]))), float(Game.villa_build["time_left"]))
		if _bar:
			_bar.value = 1.0 - float(Game.villa_build["time_left"]) / maxf(1.0, float(next.get("build_seconds", 1)))
	elif Game.villa_stage >= stages.size():
		_status.text = tr("Fully restored. The grand estate is complete.")
	elif Game.demo_capped_villa():
		_status.text = tr("The rest of the villa's story is in the full game. Thank you for playing the demo!")
	else:
		_status.text = tr("Your home. Each improvement changes how the villa looks and opens up more of the estate.")
	_tick_action(Game.villa_next_price(), "")


## A workshop at work, drawn like a furnace screen: what goes in on the left, an arrow that fills as a batch is made,
## what comes out on the right, the batches waiting underneath, and the next upgrade along the bottom. Words are kept
## for the hover text, so the window itself is mostly pictures and numbers.
func _build_workshop_view() -> void:
	var b: Dictionary = Game.buildings[id]
	var levels: Array = Game.building_info(id).get("levels", [])
	var list := Game.recipes(id)
	# A choice of products shows as their pictures, the chosen one pressed in.
	if list.size() > 1:
		var choices := Ui.row(body)
		choices.alignment = BoxContainer.ALIGNMENT_CENTER
		for k in list.size():
			var outs: Dictionary = list[k]["out"]
			var item := String(outs.keys()[0])
			var pick := Button.new()
			var path := WorkshopParts.ICONS32 + Game.item_base(item) + ".png"
			pick.icon = load(path) if ResourceLoader.exists(path) else null
			pick.toggle_mode = true
			pick.button_pressed = int(b["recipe"]) == k
			pick.pressed.connect(func(): Audio.play("click", -8.0); Game.set_recipe(id, k))
			choices.add_child(pick)
	var recipe := Game.current_recipe(id)
	var ins: Dictionary = recipe.get("in", {})
	var outs: Dictionary = recipe.get("out", {})
	var batch := Game.building_batch(id)
	var line := Ui.row(body)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 6)
	if ins.is_empty():
		# Bees need no loading: their slot shows the flowers they visit.
		WorkshopParts.slot_with_caption(line, "lavender", "")
	for item in ins:
		_in_counts[item] = [WorkshopParts.slot_with_caption(line, item, "x%d" % (int(ins[item]) * batch)), int(ins[item]) * batch]
	_arrow = WorkshopParts.Arrow.new()
	_arrow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_arrow.custom_minimum_size.y = 40
	line.add_child(_arrow)
	for item in outs:
		_out_counts[item] = WorkshopParts.slot_with_caption(line, item, "x%d" % (int(outs[item]) * batch))
	if not ins.is_empty():
		var feed := Ui.row(body)
		feed.alignment = BoxContainer.ALIGNMENT_CENTER
		var helper := String(Game.building_info(id).get("helper", ""))
		if Game.helpers.has(helper):
			# The helper who keeps it loaded stands in for the load button.
			WorkshopParts.face(feed, helper)
		else:
			_load = Ui.button(feed, tr("Load"), func(): if Game.load_building(id) == 0: Game.message.emit(tr("Not enough in the storehouse")))
		var boxes := Ui.row(feed)
		boxes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var first := String(ins.keys()[0])
		for k in Game.building_queue_max(id):
			var box := PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = WorkshopParts.SLOT_FILL
			style.border_color = WorkshopParts.SLOT_EDGE
			style.set_border_width_all(1)
			box.add_theme_stylebox_override("panel", style)
			box.custom_minimum_size = Vector2(16, 16)
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var pic := TextureRect.new()
			pic.texture = load(Ui.ICONS + Game.item_base(first) + ".png") if ResourceLoader.exists(Ui.ICONS + Game.item_base(first) + ".png") else null
			pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(pic)
			boxes.add_child(box)
			_queue_boxes.append(pic)
	elif recipe.get("lavender_honey", false):
		Ui.para(body, tr("When lavender blooms on the farm, the bees make lavender honey."), WIDTH).add_theme_color_override("font_color", UiTheme.MUTED)
	_state_note = Ui.label(body)
	_state_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_note.add_theme_color_override("font_color", UiTheme.RED)
	Ui.divider(body)
	# The level, what the next one brings as small pictures, its cost, and the buttons, in two short rows.
	Ui.label(body, tr("Level %d of %d") % [int(b["level"]) + 1, levels.size() + 1]).add_theme_color_override("font_color", UiTheme.HEADING)
	var act := Game.building_action(id)
	if not act.is_empty():
		# What the next level brings, as short tags that wrap onto a second line if the window is narrow.
		var next: Dictionary = levels[int(b["level"])]
		var gains := HFlowContainer.new()
		gains.add_theme_constant_override("h_separation", 4)
		gains.add_theme_constant_override("v_separation", 3)
		body.add_child(gains)
		Ui.label(gains, tr("Next level:")).add_theme_color_override("font_color", UiTheme.MUTED)
		WorkshopParts.tag(gains, tr("%s× speed") % str(next.get("speed", 1)))
		if next.has("queue"):
			WorkshopParts.tag(gains, tr("%d batch slots") % int(next["queue"]))
		if int(next.get("batch", 1)) > 1:
			WorkshopParts.tag(gains, tr("%d per batch") % int(next["batch"]))
		if int(next.get("quality", 0)) > 0:
			WorkshopParts.tag(gains, tr("Better goods"))
	var bottom := Ui.row(body)
	bottom.add_theme_constant_override("separation", 6)
	if not act.is_empty():
		for key in act["cost"]:
			if int(act["cost"][key]) <= 0:
				continue
			var c := Ui.row(bottom)
			c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			Ui.icon(c, {"coins": "sestertius", "aureus": "aureus", "provisions": "bread"}.get(key, key))
			var n := Ui.label(c, str(int(act["cost"][key])))
			n.set_meta("key", key)
			n.set_meta("need", int(act["cost"][key]))
			_cost_chips.append(n)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom.add_child(spacer)
		_action = Ui.button(bottom, tr("Upgrade"), _do_action)
	else:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom.add_child(spacer)
	Ui.button(bottom, ">" if b["paused"] else "||", func(): Game.set_building_paused(id, not b["paused"]))
	_tick_workshop_view()


func _tick_workshop_view() -> void:
	var b: Dictionary = Game.buildings[id]
	_arrow.value = float(b["progress"]) / Game.batch_seconds(id) if b["busy"] else 0.0
	for item in _in_counts:
		var have := Game.count_item(item)
		var l: Label = _in_counts[item][0]
		l.text = str(have)
		# Too little for a batch shows in red, the same warning colour as a short cost.
		l.add_theme_color_override("font_color", UiTheme.CREAM if have >= int(_in_counts[item][1]) else Color(1.0, 0.55, 0.45))
	for item in _out_counts:
		_out_counts[item].text = str(Game.count_item(item))
	for k in _queue_boxes.size():
		_queue_boxes[k].visible = k < b["queue"].size()
	if _load:
		_load.disabled = b["queue"].size() >= Game.building_queue_max(id)
	var note := ""
	if b["paused"]:
		note = tr("Paused")
	elif b["busy"] and float(b["progress"]) >= Game.batch_seconds(id):
		note = tr("Done, waiting for room in the storehouse")
	_state_note.text = note
	_state_note.visible = note != ""
	for n in _cost_chips:
		var key := String(n.get_meta("key"))
		var need := int(n.get_meta("need"))
		var have: int = Game.coins if key == "coins" else (Game.aureus if key == "aureus" else Game.count_item(key))
		n.add_theme_color_override("font_color", UiTheme.INK if have >= need else UiTheme.RED)
	if _action:
		var block := Game.building_block(id)
		_action.disabled = block != "" or Game.missing(Game.building_action(id).get("cost", {})) != ""
