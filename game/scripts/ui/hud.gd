extends CanvasLayer
## The placeholder interface: farm stats, buttons, upgrade list, messages, the "while you were away" summary and the debug panel.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const INK := Color(0.98, 0.94, 0.86)
const PANEL := Color(0.17, 0.12, 0.14, 0.82)

var _root: Control
var _coins: Label
var _storage: Label
var _cart: Label
var _info: Label
var _toast: Label
var _toast_tween: Tween
var _upgrades_panel: PanelContainer
var _upgrade_buttons := {}
var _villa_button: Button
var _cart_button: Button
var _debug: PanelContainer


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Clicks on empty parts of the interface pass through to the farm.
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)

	var stats := _panel(Vector2(4, 4))
	var col := VBoxContainer.new()
	stats.add_child(col)
	_coins = _label(col)
	_storage = _label(col)
	_cart = _label(col)

	var buttons := VBoxContainer.new()
	_root.add_child(buttons)
	# Anchored to the top-right corner and growing leftwards, so longer button text never gets cut off.
	buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	buttons.offset_top = 4
	buttons.offset_right = -4
	_cart_button = _button(buttons, "Send cart", func(): Game.send_cart())
	_button(buttons, "Upgrades", func(): _upgrades_panel.visible = not _upgrades_panel.visible)
	_villa_button = _button(buttons, "", func(): Game.upgrade_villa())

	_upgrades_panel = _panel(Vector2(0, 0))
	_upgrades_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_upgrades_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_upgrades_panel.offset_top = 52
	_upgrades_panel.offset_right = -4
	_upgrades_panel.visible = false
	var list := VBoxContainer.new()
	_upgrades_panel.add_child(list)
	for id in ["storage", "cart_capacity", "cart_speed", "farmhand"]:
		_upgrade_buttons[id] = _button(list, "", func(): Game.buy_upgrade(id))

	_info = _label(_root)
	_info.position = Vector2(4, 4)
	_info.visible = false

	_toast = _label(_root)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 54)
	_toast.size = Vector2(480, 10)
	_toast.modulate.a = 0.0

	_build_debug()
	Game.message.connect(toast)
	Game.storage_full.connect(func(): toast("The storeroom is full: send the cart to market"))
	if not Saves.pending_summary.is_empty():
		_show_away(Saves.pending_summary)
		Saves.pending_summary = {}


func _process(_delta: float) -> void:
	_coins.text = "Sestertii  %d" % Game.coins
	_storage.text = "Storeroom  %d / %d" % [Game.stored_total(), Game.storage_capacity()]
	if Game.cart["away"]:
		_cart.text = "Cart back in  %ds" % ceili(float(Game.cart["time_left"]))
	else:
		_cart.text = "Cart ready  (carries %d)" % Game.cart_capacity()
	_cart_button.disabled = Game.cart["away"] or Game.stored_total() == 0
	var villa_cost := Game.villa_next_cost()
	_villa_button.visible = villa_cost >= 0
	if villa_cost >= 0:
		var next: Dictionary = Game.villa_stages()[Game.villa_stage]
		_villa_button.text = "%s  %d" % [next.get("name", "Upgrade villa"), villa_cost]
		_villa_button.disabled = Game.coins < villa_cost
	for id in _upgrade_buttons:
		var info := Game.upgrade_info(id)
		var cost := Game.upgrade_cost(id)
		var b: Button = _upgrade_buttons[id]
		if cost < 0:
			b.text = "%s  maxed" % info.get("name", id)
			b.disabled = true
		else:
			var values: Array = info.get("values", [])
			var next_value: Variant = values[mini(int(Game.levels.get(id, 0)) + 1, values.size() - 1)]
			b.text = "%s  %s %s  %d" % [info.get("name", id), info.get("label", ""), _num(next_value), cost]
			b.disabled = Game.coins < cost


func set_info(text: String) -> void:
	_info.visible = text != ""
	_info.text = text
	_info.position = Vector2(4, 256)


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func float_text(pos: Vector2, text: String) -> void:
	var l := _label(_root)
	l.text = text
	l.position = pos
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", pos.y - 12, 0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)


func _show_away(summary: Dictionary) -> void:
	var p := _panel(Vector2(140, 90))
	var col := VBoxContainer.new()
	p.add_child(col)
	var hours := float(summary.get("seconds", 0)) / 3600.0
	var lines := ["While you were away" , "(%s)" % (("%.1f hours" % hours) if hours >= 1.0 else ("%d minutes" % int(hours * 60)))]
	if int(summary.get("harvested", 0)) > 0:
		lines.append("Harvested  %d lavender" % int(summary["harvested"]))
	if int(summary.get("earned", 0)) > 0:
		lines.append("Earned  %d sestertii" % int(summary["earned"]))
	if int(summary.get("ready", 0)) > 0:
		lines.append("%d plants are ready to harvest" % int(summary["ready"]))
	if summary.get("storage_full", false):
		lines.append("The storeroom is full")
	for line in lines:
		_label(col).text = line
	_button(col, "Lovely", p.queue_free)


func _build_debug() -> void:
	_debug = _panel(Vector2(4, 50))
	_debug.visible = false
	var col := VBoxContainer.new()
	_debug.add_child(col)
	_label(col).text = "Debug (F1)"
	for s in [1, 10, 60]:
		_button(col, "Speed x%d" % s, func(): Game.speed = s; toast("Time speed x%d" % s))
	_button(col, "Skip 1 hour", func(): _show_away(Game.simulate_offline(3600)))
	_button(col, "+100 sestertii", func(): Game.coins += 100)
	_button(col, "Save now", func(): Saves.save_game(); toast("Saved"))
	_button(col, "Reset farm", func(): Saves.reset(); get_tree().reload_current_scene())


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_debug.visible = not _debug.visible


func _panel(pos: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	_root.add_child(p)
	return p


func _label(parent: Node) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _num(v: Variant) -> String:
	return str(int(v)) if float(v) == floor(float(v)) else str(v)


func _make_theme() -> Theme:
	var t := Theme.new()
	var font: FontFile = FONT.duplicate()
	# The pixel font is drawn without smoothing so it stays crisp at the game's low resolution.
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	t.default_font = font
	t.default_font_size = 8
	t.set_color("font_color", "Label", INK)
	t.set_color("font_outline_color", "Label", Color(0.12, 0.08, 0.1))
	t.set_constant("outline_size", "Label", 0)
	t.set_constant("separation", "VBoxContainer", 2)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 3))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var c := Color(0.36, 0.25, 0.3)
		match state:
			"hover": c = Color(0.48, 0.34, 0.42)
			"pressed": c = Color(0.28, 0.19, 0.24)
			"disabled": c = Color(0.25, 0.2, 0.22, 0.85)
			"focus": c = Color(0, 0, 0, 0)
		t.set_stylebox(state, "Button", _box(c, 2))
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.92))
	t.set_color("font_disabled_color", "Button", Color(0.65, 0.58, 0.58))
	return t


func _box(color: Color, margin: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.content_margin_left = margin + 1
	s.content_margin_right = margin + 1
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	return s
