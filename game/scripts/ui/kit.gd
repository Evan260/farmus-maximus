class_name UiKit
## Shared building blocks for the interface: the parchment theme, labels, buttons, item icons and price text.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const PANEL_TEX := preload("res://assets/ui/panel.png")
const BUTTON_TEX := preload("res://assets/ui/button.png")
const ICONS := "res://assets/sprites/icons/"
## Dark ink for text on parchment, and cream for text on terracotta buttons or straight over the scene.
const INK := Color(0.29, 0.18, 0.14)
const CREAM := Color(0.99, 0.95, 0.86)
## Secondary text: lighter than the main ink but still dark and solid, so it reads on dim or poor screens.
const FADED := Color(0.4, 0.27, 0.2)
const SHORT := Color(0.66, 0.2, 0.14)
const HEADING := Color(0.55, 0.27, 0.18)


static func label(parent: Node, text := "", over_scene := false) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if over_scene:
		# Text drawn straight over the farm needs light ink and an outline to stay readable on any background.
		l.add_theme_color_override("font_color", CREAM)
		l.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.12))
		l.add_theme_constant_override("outline_size", 2)
	parent.add_child(l)
	return l


## A label that wraps within a fixed width, for sentences in panels.
static func para(parent: Node, text: String, width := 200) -> Label:
	var l := label(parent, text)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


static func button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Sfx.play("click", -8.0))
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## A framed panel of slightly darker parchment, for one item in a list, so each item reads as its own block.
static func card(parent: Node) -> VBoxContainer:
	var frame := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.9, 0.82, 0.64)
	box.border_color = Color(0.66, 0.5, 0.34)
	box.set_border_width_all(1)
	box.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", box)
	parent.add_child(frame)
	return column(frame)


## A line of a window naming something on the left, wrapped if long, with a short button for it on the right.
static func setting(parent: Node, text: String, value: String, action: Callable, width := 250) -> Button:
	var r := row(parent)
	var l := para(r, text, width - 74)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var b := button(r, value, action)
	b.custom_minimum_size = Vector2(70, 0)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


## A tab along the top of a window: it sounds like turning a page rather than pressing a button.
static func tab_button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Sfx.play("tab", -4.0))
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## A small square close button with a drawn cross, for the top-right corner of a window.
static func close_button(parent: Node, action: Callable) -> Button:
	var b := button(parent, "", action)
	b.custom_minimum_size = Vector2(13, 13)
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var cross := Control.new()
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	cross.draw.connect(func():
		var c := Rect2(Vector2.ZERO, cross.size).get_center().floor()
		for i in range(-2, 3):
			cross.draw_rect(Rect2(c + Vector2(i, i), Vector2.ONE), CREAM)
			cross.draw_rect(Rect2(c + Vector2(i, -i), Vector2.ONE), CREAM))
	b.add_child(cross)
	return b


## A heading that opens a section of a window, with a thin rule under it.
## Shows a window by fading it in, so it does not pop up all at once.
static func fade_in(item: CanvasItem, seconds := 0.18) -> void:
	item.visible = true
	item.modulate.a = 0.0
	item.create_tween().tween_property(item, "modulate:a", 1.0, seconds).set_ease(Tween.EASE_OUT)


static func section(parent: Node, text: String) -> Label:
	var l := label(parent, text)
	l.add_theme_color_override("font_color", HEADING)
	var rule := ColorRect.new()
	rule.color = Color(0.55, 0.27, 0.18, 0.35)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)
	return l


## A checklist of what something costs, one line per thing with its icon and how many you have of how many it needs.
## Returns the lines so update_costs can refresh the counts without rebuilding.
static func cost_list(parent: Node, cost: Dictionary) -> Array:
	var lines := []
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	parent.add_child(grid)
	for key in cost:
		if int(cost[key]) <= 0:
			continue
		var r := row(grid)
		var icon_item: String = {"coins": "sestertius", "aureus": "aureus", "provisions": "bread"}.get(key, key)
		icon(r, icon_item)
		var l := label(r)
		l.set_meta("key", key)
		l.set_meta("need", int(cost[key]))
		lines.append(l)
	update_costs(lines)
	return lines


static func update_costs(lines: Array) -> void:
	for l in lines:
		if not is_instance_valid(l):
			continue
		var key := String(l.get_meta("key"))
		var need := int(l.get_meta("need"))
		var have: int = Game.coins if key == "coins" else (Game.aureus if key == "aureus" else Game.count_item(key))
		var name: String = "sestertii" if key == "coins" else ("aurei" if key == "aureus" else ("bread or wine" if key == "provisions" else String(Balance.get_value("items.%s.name" % key, key)).to_lower()))
		l.text = "%s  %d / %d" % [TranslationServer.translate(name), mini(have, need), need]
		l.add_theme_color_override("font_color", INK if have >= need else SHORT)


static func progress(parent: Node) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120, 5)
	bar.max_value = 1.0
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar


static func row(parent: Node) -> HBoxContainer:
	var r := HBoxContainer.new()
	parent.add_child(r)
	return r


static func column(parent: Node) -> VBoxContainer:
	var c := VBoxContainer.new()
	parent.add_child(c)
	return c


static func icon(parent: Node, item: String) -> TextureRect:
	var t := TextureRect.new()
	var path: String = ICONS + Game.item_base(item) + ".png"
	t.texture = load(path) if ResourceLoader.exists(path) else null
	t.custom_minimum_size = Vector2(16, 16)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## A scrolling list area, for panels whose contents can grow longer than the screen.
static func scroll(parent: Node, size: Vector2) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.custom_minimum_size = size
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(s)
	# The list keeps clear of the scroll bar, so buttons at the end of a line are not drawn under it.
	var gap := MarginContainer.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.add_theme_constant_override("margin_right", 8)
	s.add_child(gap)
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.add_child(c)
	return c


## A gamepad player moves between buttons with the d-pad, so they become focusable and the first one takes focus.
static func pad_focus(root: Control) -> void:
	if Input.get_connected_joypads().is_empty() or not root.is_inside_tree():
		return
	var first: Button = null
	for b in root.find_children("*", "Button", true, false):
		b.focus_mode = Control.FOCUS_ALL
		if not first and b.is_visible_in_tree() and not b.disabled:
			first = b
	var focused := root.get_viewport().gui_get_focus_owner()
	if first and (focused == null or not root.is_ancestor_of(focused)):
		first.grab_focus()


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


## A price as words, such as "250 sestertii, 6 stone, 2 bread or wine".
static func cost_text(cost: Dictionary) -> String:
	var parts := []
	if int(cost.get("coins", 0)) > 0:
		parts.append(plural(int(cost["coins"]), "sestertius", "sestertii"))
	if int(cost.get("aureus", 0)) > 0:
		parts.append(plural(int(cost["aureus"]), "aureus", "aurei"))
	for key in cost:
		if key in ["coins", "aureus"] or int(cost[key]) <= 0:
			continue
		var name: String = TranslationServer.translate("bread or wine") if key == "provisions" else TranslationServer.translate(String(Balance.get_value("items.%s.name" % key, key))).to_lower()
		parts.append("%d %s" % [int(cost[key]), name])
	return ", ".join(parts) if not parts.is_empty() else TranslationServer.translate("free")


## Goods as words, such as "2 lavender bundle + 1 olive oil".
static func goods_text(goods: Dictionary) -> String:
	var parts := []
	for item in goods:
		parts.append("%d %s" % [int(goods[item]), TranslationServer.translate(String(Balance.get_value("items.%s.name" % item, item))).to_lower()])
	return " + ".join(parts)


static func plural(n: int, one: String, many: String) -> String:
	return "%d %s" % [n, TranslationServer.translate(one if n == 1 else many)]


static func duration(seconds: float) -> String:
	var s := int(ceil(seconds))
	if s >= 3600:
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%dm %02ds" % [s / 60, s % 60]
	return "%ds" % s


static func make_theme() -> Theme:
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
	t.set_stylebox("disabled", "Button", _textured(BUTTON_TEX, 4, Color(0.5, 0.44, 0.42), 3))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(1)
	focus.border_color = Color(1, 0.95, 0.7)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.94))
	t.set_color("font_pressed_color", "Button", Color(1, 0.93, 0.78))
	t.set_color("font_hover_pressed_color", "Button", Color(1, 0.93, 0.78))
	t.set_color("font_disabled_color", "Button", Color(0.93, 0.88, 0.82))
	# A clear scrollbar: a dark track with a terracotta handle, wide enough to see and to grab.
	var track := _flat(Color(0.29, 0.18, 0.14, 0.3), 2)
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_stylebox("scroll_focus", "VScrollBar", track)
	t.set_stylebox("grabber", "VScrollBar", _flat(Color(0.7, 0.38, 0.25), 2))
	t.set_stylebox("grabber_highlight", "VScrollBar", _flat(Color(0.8, 0.46, 0.3), 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", _flat(Color(0.6, 0.3, 0.2), 2))
	# Sliders: the knob is a small pixel block that travels the whole track, end to end.
	t.set_stylebox("slider", "HSlider", _flat(Color(0.29, 0.18, 0.14, 0.35), 0, 2))
	t.set_stylebox("grabber_area", "HSlider", _flat(Color(0.7, 0.38, 0.25), 0, 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", _flat(Color(0.8, 0.46, 0.3), 0, 2))
	var knob := _knob()
	t.set_icon("grabber", "HSlider", knob)
	t.set_icon("grabber_highlight", "HSlider", knob)
	t.set_icon("grabber_disabled", "HSlider", knob)
	t.set_constant("center_grabber", "HSlider", 0)
	var field := _flat(Color(0.99, 0.96, 0.88), 3, 2)
	field.border_color = Color(0.55, 0.36, 0.25)
	field.set_border_width_all(1)
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", field)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", INK)
	t.set_stylebox("background", "ProgressBar", _flat(Color(0.29, 0.18, 0.14, 0.3), 0))
	t.set_stylebox("fill", "ProgressBar", _flat(Color(0.7, 0.38, 0.25), 0))
	return t


static func _flat(c: Color, width: int, height := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.content_margin_left = width
	s.content_margin_right = width
	s.content_margin_top = height
	s.content_margin_bottom = height
	return s


static func _knob() -> ImageTexture:
	var img := Image.create(5, 9, false, Image.FORMAT_RGBA8)
	img.fill(CREAM)
	for y in 9:
		img.set_pixel(0, y, Color(0.36, 0.2, 0.15))
		img.set_pixel(4, y, Color(0.36, 0.2, 0.15))
	for x in 5:
		img.set_pixel(x, 0, Color(0.36, 0.2, 0.15))
		img.set_pixel(x, 8, Color(0.36, 0.2, 0.15))
	return ImageTexture.create_from_image(img)


## A stretchable panel or button skin cut from one small image: the corners stay sharp, the middle stretches.
static func _textured(tex: Texture2D, border: int, tint: Color, pad: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	# The generated images have transparent margins, so the skin is cut from the visible part only.
	s.region_rect = tex.get_image().get_used_rect()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_texture_margin(side, border)
		s.set_content_margin(side, pad + 1)
	s.modulate_color = tint
	return s


## A 1px frame just outside a shape; drawn as four filled strips because an unfilled rect straddles pixel edges.
static func outline(item: CanvasItem, r: Rect2, colour: Color) -> void:
	item.draw_rect(Rect2(r.position.x - 1, r.position.y - 1, r.size.x + 2, 1), colour)
	item.draw_rect(Rect2(r.position.x - 1, r.end.y, r.size.x + 2, 1), colour)
	item.draw_rect(Rect2(r.position.x - 1, r.position.y, 1, r.size.y), colour)
	item.draw_rect(Rect2(r.end.x, r.position.y, 1, r.size.y), colour)
