class_name UiKit
## Shared building blocks for the interface: the parchment theme, labels, buttons, item icons and price text.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const PANEL_TEX := preload("res://assets/ui/panel.png")
const BUTTON_TEX := preload("res://assets/ui/button.png")
const ICONS := "res://assets/sprites/icons/"
## Dark ink for text on parchment, and cream for text on terracotta buttons or straight over the scene.
const INK := Color(0.29, 0.18, 0.14)
const CREAM := Color(0.99, 0.95, 0.86)
const FADED := Color(0.29, 0.18, 0.14, 0.45)


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
	t.custom_minimum_size = Vector2(12, 12)
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
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(c)
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
	t.set_stylebox("disabled", "Button", _textured(BUTTON_TEX, 4, Color(0.62, 0.58, 0.56, 0.8), 3))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(1)
	focus.border_color = Color(1, 0.95, 0.7)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.94))
	t.set_color("font_pressed_color", "Button", Color(1, 0.93, 0.78))
	t.set_color("font_hover_pressed_color", "Button", Color(1, 0.93, 0.78))
	t.set_color("font_disabled_color", "Button", Color(0.92, 0.86, 0.8, 0.75))
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color(0.29, 0.18, 0.14, 0.35)
	t.set_stylebox("scroll", "VScrollBar", bar)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.62, 0.36, 0.26)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	return t


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
