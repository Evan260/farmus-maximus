extends CanvasLayer
## The placeholder interface: farm stats, buttons, upgrade list, messages, the "while you were away" summary and the debug panel.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const PANEL_TEX := preload("res://assets/ui/panel.png")
const BUTTON_TEX := preload("res://assets/ui/button.png")
## Dark ink for text on parchment, and cream for text on terracotta buttons or straight over the scene.
const INK := Color(0.29, 0.18, 0.14)
const CREAM := Color(0.99, 0.95, 0.86)

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
var _settings: PanelContainer
var _seed_buttons := {}
var _stats_panel: PanelContainer
var _buttons: VBoxContainer
var _compact: PanelContainer
var _compact_label: Label
var _style_button: Button
var _size_button: Button
var _strip_button: Button


func _ready() -> void:
	# Above the scene and the firefly glow layer.
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Clicks on empty parts of the interface pass through to the farm.
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)

	var stats := _panel(Vector2(4, 4))
	_stats_panel = stats
	var col := VBoxContainer.new()
	stats.add_child(col)
	_coins = _label(col)
	_storage = _label(col)
	_cart = _label(col)
	var seeds := HBoxContainer.new()
	col.add_child(seeds)
	for crop in Balance.get_value("seeds", ["lavender"]):
		_seed_buttons[crop] = _button(seeds, String(Game.crop_info(crop).get("name", crop)), func(): Game.selected_seed = crop)
		_seed_buttons[crop].toggle_mode = true

	var buttons := VBoxContainer.new()
	_buttons = buttons
	_root.add_child(buttons)
	# Anchored to the top-right corner and growing leftwards, so longer button text never gets cut off.
	buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	buttons.offset_top = 4
	buttons.offset_right = -4
	_cart_button = _button(buttons, "Send cart", func(): Game.send_cart())
	_button(buttons, "Upgrades", func(): _upgrades_panel.visible = not _upgrades_panel.visible)
	_villa_button = _button(buttons, "", func(): Game.upgrade_villa())
	_button(buttons, "Settings", func(): _settings.visible = not _settings.visible)

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

	_info = _label(_root, true)
	_info.position = Vector2(4, 4)
	_info.visible = false

	_toast = _label(_root, true)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 54)
	_toast.size = Vector2(480, 10)
	_toast.modulate.a = 0.0

	_build_settings()
	_build_compact()
	_build_debug()
	Game.message.connect(func(text): toast(text); Sfx.play("nope", -6.0))
	Game.storage_full.connect(func(): toast("The storeroom is full: send the cart to market"))
	if not Saves.pending_summary.is_empty():
		_show_away(Saves.pending_summary)
		Saves.pending_summary = {}


func _process(_delta: float) -> void:
	var in_strip := Windowing.strip
	_stats_panel.visible = not in_strip
	_buttons.visible = not in_strip
	_compact.visible = in_strip
	if in_strip:
		_upgrades_panel.visible = false
		_settings.visible = false
		_compact_label.text = "%d   %d/%d" % [Game.coins, Game.stored_total(), Game.storage_capacity()]
	_strip_button.text = "Full window  (F10)" if in_strip else "Desktop strip  (F10)"
	_style_button.text = "Strip: transparent" if Windowing.transparent else "Strip: solid"
	_size_button.text = "Strip size: %s" % Windowing.SIZES[Windowing.size_index]
	_coins.text = "Sestertii  %d" % Game.coins
	_storage.text = "Storeroom  %d / %d" % [Game.stored_total(), Game.storage_capacity()]
	if Game.cart["away"]:
		_cart.text = "Cart back in  %ds" % ceili(float(Game.cart["time_left"]))
	else:
		_cart.text = "Cart ready  (carries %d)" % Game.cart_capacity()
	_cart_button.disabled = Game.cart["away"] or Game.stored_total() == 0
	var villa_cost := Game.villa_next_cost()
	_villa_button.visible = villa_cost >= 0 or Game.villa_build["active"]
	if Game.villa_build["active"]:
		_villa_button.text = "Building...  %ds" % ceili(float(Game.villa_build["time_left"]))
		_villa_button.disabled = true
	elif villa_cost >= 0:
		var next: Dictionary = Game.villa_stages()[Game.villa_stage]
		_villa_button.text = "%s  %d" % [next.get("name", "Upgrade villa"), villa_cost]
		_villa_button.disabled = Game.coins < villa_cost
	for crop in _seed_buttons:
		var b: Button = _seed_buttons[crop]
		var info := Game.crop_info(crop)
		b.text = "%s %d" % [info.get("name", crop), int(info.get("plant_cost", 0))]
		# The chosen seed is shown pressed, so it is clear what a click on an empty plot will plant.
		b.button_pressed = Game.selected_seed == crop
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


## The compact bar's area in the strip, which must stay clickable when the rest of the sky lets clicks through.
func compact_rect() -> Rect2:
	return _compact.get_global_rect() if _compact.visible else Rect2()


func set_info(text: String) -> void:
	_info.visible = text != ""
	_info.text = text
	_info.position = Vector2(4, get_viewport().get_visible_rect().size.y - 14)


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast.position = Vector2(0, roundf(get_viewport().get_visible_rect().size.y * 0.2))
	_toast.size.x = get_viewport().get_visible_rect().size.x
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func float_text(pos: Vector2, text: String) -> void:
	var l := _label(_root, true)
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
	# Centred on whatever the view is, so it fits the desktop strip as well as the full window.
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH


func _build_settings() -> void:
	_settings = _panel(Vector2(150, 80))
	_settings.visible = false
	var col := VBoxContainer.new()
	_settings.add_child(col)
	_label(col).text = "Settings"
	for bus in ["Music", "Ambience", "Effects"]:
		var row := HBoxContainer.new()
		col.add_child(row)
		var name := _label(row)
		name.text = bus
		name.custom_minimum_size = Vector2(56, 0)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Sfx.volumes[bus]
		slider.custom_minimum_size = Vector2(90, 8)
		slider.focus_mode = Control.FOCUS_NONE
		slider.value_changed.connect(func(v): Sfx.set_volume(bus, v))
		row.add_child(slider)
	_strip_button = _button(col, "", func(): Windowing.toggle_strip())
	_style_button = _button(col, "", func(): Windowing.set_transparent(not Windowing.transparent))
	_size_button = _button(col, "", func(): Windowing.cycle_size())
	_button(col, "Close", func(): _settings.visible = false)


## The small bar shown in the desktop strip instead of the full panels.
func _build_compact() -> void:
	_compact = PanelContainer.new()
	_root.add_child(_compact)
	var row := HBoxContainer.new()
	_compact.add_child(row)
	_compact_label = _label(row)
	_button(row, "Sell", func(): Game.send_cart())
	_button(row, "Expand", func(): Windowing.toggle_strip())
	# Top-left, where the strip shows only sky or desktop, so it never covers the cart or the plots.
	_compact.position = Vector2(4, 4)
	_compact.visible = false


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


func _label(parent: Node, over_scene := false) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if over_scene:
		# Text drawn straight over the farm needs light ink and an outline to stay readable on any background.
		l.add_theme_color_override("font_color", CREAM)
		l.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.12))
		l.add_theme_constant_override("outline_size", 2)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Sfx.play("click", -8.0))
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
	t.set_constant("separation", "VBoxContainer", 2)
	t.set_constant("separation", "HBoxContainer", 2)
	t.set_stylebox("panel", "PanelContainer", _textured(PANEL_TEX, 6, Color.WHITE, 5))
	t.set_stylebox("normal", "Button", _textured(BUTTON_TEX, 4, Color.WHITE, 3))
	t.set_stylebox("hover", "Button", _textured(BUTTON_TEX, 4, Color(1.12, 1.08, 1.05), 3))
	t.set_stylebox("pressed", "Button", _textured(BUTTON_TEX, 4, Color(0.72, 0.6, 0.55), 3))
	t.set_stylebox("hover_pressed", "Button", _textured(BUTTON_TEX, 4, Color(0.78, 0.66, 0.6), 3))
	t.set_stylebox("disabled", "Button", _textured(BUTTON_TEX, 4, Color(0.62, 0.58, 0.56, 0.8), 3))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.94))
	t.set_color("font_pressed_color", "Button", Color(1, 0.93, 0.78))
	t.set_color("font_hover_pressed_color", "Button", Color(1, 0.93, 0.78))
	t.set_color("font_disabled_color", "Button", Color(0.92, 0.86, 0.8, 0.75))
	return t


## A stretchable panel or button skin cut from one small image: the corners stay sharp, the middle stretches.
func _textured(tex: Texture2D, border: int, tint: Color, pad: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	# The generated images have transparent margins, so the skin is cut from the visible part only.
	s.region_rect = tex.get_image().get_used_rect()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_texture_margin(side, border)
		s.set_content_margin(side, pad + 1)
	s.modulate_color = tint
	return s
