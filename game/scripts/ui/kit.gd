class_name UiKit
## Shared building blocks for the interface: the parchment theme, labels, buttons, item icons and price text.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const FUSION := "res://assets/fonts/"
## Languages whose letters the 8-pixel fonts lack (Cyrillic, and the Polish and Turkish accented letters), so their
## whole interface uses a 10-pixel font instead.
const TEN_PIXEL := ["ru", "uk", "be", "bg", "pl", "tr"]
const PANEL_TEX := preload("res://assets/ui/panel.png")

## The interface fonts made so far, one per language, and the shared 10-pixel font.
static var _fonts := {}
static var _ten_pixel: FontFile
const BUTTON_TEX := preload("res://assets/ui/button.png")
const ICONS := "res://assets/sprites/icons/"
## Dark ink for text on parchment, and cream for text on terracotta buttons or straight over the scene.
const INK := Color(0.29, 0.18, 0.14)
const CREAM := Color(0.99, 0.95, 0.86)
## Secondary text: lighter than the main ink but still dark and solid, so it reads on dim or poor screens.
const MUTED := Color(0.4, 0.27, 0.2)
const RED := Color(0.66, 0.2, 0.14)
const HEADING := Color(0.55, 0.27, 0.18)
## The parchment of a window, the darker paper of a tab that is not open, and the line round tabs.
const TAB_OPEN := Color8(243, 220, 171)
const TAB_SHUT := Color8(219, 186, 136)
const TAB_EDGE := Color8(158, 104, 70)


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


## Gives a control a tip shown when the pointer rests on it, drawn by the Tips autoload at the interface's scale.
static func tip_on(c: Control, text: String) -> Control:
	c.set_meta("tip", text)
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		c.mouse_filter = Control.MOUSE_FILTER_PASS
	return c


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
## A row of tabs over a page, with a rule along its foot that the open tab stands on, joined to the page below it.
static func tab_row(parent: Node) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 1)
	r.draw.connect(func(): r.draw_rect(Rect2(0, r.size.y - 1, r.size.x, 1), TAB_EDGE))
	parent.add_child(r)
	var indent := Control.new()
	indent.custom_minimum_size = Vector2(3, 0)
	r.add_child(indent)
	return r


## A paper tab in a `tab_row`: the open one is taller and the colour of the page, the others shorter and darker.
static func tab_button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var open: bool = state.ends_with("pressed")
		var box := StyleBoxFlat.new()
		box.anti_aliasing = false
		box.bg_color = TAB_OPEN if open else (TAB_SHUT.lightened(0.12) if state == "hover" else TAB_SHUT)
		box.border_color = TAB_EDGE
		box.border_width_left = 1
		box.border_width_right = 1
		box.border_width_top = 1
		box.border_width_bottom = 0 if open else 1
		box.corner_radius_top_left = 2
		box.corner_radius_top_right = 2
		box.content_margin_left = 7
		box.content_margin_right = 7
		box.content_margin_top = 4 if open else 2
		box.content_margin_bottom = 3 if open else 2
		b.add_theme_stylebox_override(state, box)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color"]:
		b.add_theme_color_override(c, MUTED)
	for c in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, INK)
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
	# A gap above the heading shows it starts something new rather than finishing what came before.
	if parent.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 4)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(gap)
	var l := label(parent, text)
	l.add_theme_color_override("font_color", HEADING)
	var rule := ColorRect.new()
	rule.color = Color(0.55, 0.27, 0.18, 0.35)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)
	return l


## A thin line with space above and below, between items of a list that each run to several lines.
static func divider(parent: Node) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	for part in [Vector2(0, 5), Vector2(0, 1), Vector2(0, 5)]:
		var c := ColorRect.new()
		c.custom_minimum_size = part
		c.color = Color(0.55, 0.27, 0.18, 0.35) if part.y == 1 else Color(0, 0, 0, 0)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(c)


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
		var name: String = "sestertii" if key == "coins" else ("aurei" if key == "aureus" else ("bread or wine" if key == "provisions" else String(Balance.get_value("items.%s.name" % key, key))))
		l.text = "%s  %d / %d" % [mid(TranslationServer.translate(name)), mini(have, need), need]
		l.add_theme_color_override("font_color", INK if have >= need else RED)


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


## Lets a finger drag a scrolling area up and down on a touch screen.
static func touch_scroll(s: ScrollContainer) -> void:
	var t: Node = load("res://scripts/ui/touch_scroll.gd").new()
	t.scroll = s
	s.add_child(t)


## A scrolling list area, for panels whose contents can grow longer than the screen.
static func scroll(parent: Node, size: Vector2) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.custom_minimum_size = size
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# A button the d-pad moves to further down the list is scrolled into view.
	s.follow_focus = true
	parent.add_child(s)
	touch_scroll(s)
	# The list keeps clear of the scroll bar, so buttons at the end of a line are not drawn under it.
	var gap := MarginContainer.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.add_theme_constant_override("margin_right", 8)
	s.add_child(gap)
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.add_child(c)
	return c


## A gamepad player moves between buttons with the d-pad, so they become focusable; after a rebuild the focus goes back to the button most like the one that had it.
static func pad_focus(root: Control, was := {}) -> void:
	if Input.get_connected_joypads().is_empty() or not root.is_inside_tree():
		return
	var buttons := root.find_children("*", "Button", true, false)
	var usable: Array[Button] = []
	for b in buttons:
		b.focus_mode = Control.FOCUS_ALL
		if b.is_visible_in_tree() and not b.disabled:
			usable.append(b)
	var focused := root.get_viewport().gui_get_focus_owner()
	if usable.is_empty() or (focused != null and root.is_ancestor_of(focused)):
		return
	var pick := usable[0]
	# A window's close button comes first, but a reflex press of A should not shut the window it just opened.
	for b in usable:
		if b.text != "":
			pick = b
			break
	if not was.is_empty():
		# A button with the same text wins, the nearest to the old place first; otherwise whichever now stands nearest it.
		var best := INF
		for b in usable:
			var gap := absf(buttons.find(b) - int(was["index"])) + (0.0 if b.text == String(was["text"]) else 1000.0)
			if gap <= best:
				best = gap
				pick = b
	pick.grab_focus()


## The focused button's text and place among root's buttons, so pad_focus can find its equal once root is rebuilt.
static func focus_hint(root: Control) -> Dictionary:
	if not root.is_inside_tree():
		return {}
	var focused := root.get_viewport().gui_get_focus_owner()
	if not focused is Button or not root.is_ancestor_of(focused):
		return {}
	return {"text": (focused as Button).text, "index": root.find_children("*", "Button", true, false).find(focused)}


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


## A price as words, such as "250 sestertii, 6 stone, 2 bread or wine".
static func cost_text(cost: Dictionary) -> String:
	var parts := []
	if int(cost.get("coins", 0)) > 0:
		parts.append(plural(int(cost["coins"]), TranslationServer.translate("sestertius"), TranslationServer.translate("sestertii")))
	if int(cost.get("aureus", 0)) > 0:
		parts.append(plural(int(cost["aureus"]), TranslationServer.translate("aureus"), TranslationServer.translate("aurei")))
	for key in cost:
		if key in ["coins", "aureus"] or int(cost[key]) <= 0:
			continue
		parts.append("%d %s" % [int(cost[key]), item_words(key, int(cost[key]))])
	return ", ".join(parts) if not parts.is_empty() else TranslationServer.translate("free")


## Goods as words, such as "2 lavender bundles + 1 olive oil".
static func goods_text(goods: Dictionary) -> String:
	var parts := []
	for item in goods:
		parts.append("%d %s" % [int(goods[item]), item_words(item, int(goods[item]))])
	return " + ".join(parts)


## A good's name as it reads after a number in the middle of a sentence: "1 lavender bundle", "10 lavender bundles".
## Each language translates the plural in the form its own sentences need, which in some is the singular.
static func item_words(key: String, n: int) -> String:
	if key == "provisions":
		return TranslationServer.translate("bread or wine")
	var name := String(Balance.get_value("items.%s.name" % key, key))
	if n != 1:
		name = String(Balance.get_value("items.%s.plural" % key, name))
	return mid(TranslationServer.translate(name))


## A translated name as it reads in the middle of a sentence: lowercased, except in German, where nouns keep their capital.
static func mid(text: String) -> String:
	return text if TranslationServer.get_locale().begins_with("de") else text.to_lower()


## A count with the word that follows it, both words already in the player's language.
static func plural(n: int, one: String, many: String) -> String:
	return "%d %s" % [n, one if n == 1 else many]


static func duration(seconds: float) -> String:
	var s := int(ceil(seconds))
	if s >= 3600:
		return TranslationServer.translate("%dh %02dm") % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return TranslationServer.translate("%dm %02ds") % [s / 60, s % 60]
	return TranslationServer.translate("%ds") % s


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = ui_font()
	t.default_font_size = text_size()
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


## The interface font for the current language: the Silkscreen pixel font, falling back to a pixel font with the
## accented letters and the Chinese, Japanese and Korean characters it lacks, in the forms the language uses.
## Each language's font is made once and kept, because text drawn with a font that is then thrown away loses its
## letters and shows as solid blocks.
static func ui_font(locale := "") -> Font:
	if locale == "":
		locale = TranslationServer.get_locale()
	if not _fonts.has(locale):
		_fonts[locale] = _make_ui_font(locale)
	return _fonts[locale]


static func _make_ui_font(locale: String) -> Font:
	var cyrillic := ten_pixel_font()
	if locale.get_slice("_", 0) in TEN_PIXEL:
		return cyrillic
	var han := "zh_hans"
	if locale.begins_with("zh_TW") or locale.begins_with("zh_HK") or locale.begins_with("zh_Hant"):
		han = "zh_tw"
	elif locale.begins_with("ja"):
		han = "ja"
	elif locale.begins_with("ko"):
		han = "ko"
	var font := _crisp(FONT)
	# Cyrillic comes last, so a language list can still name Russian in its own letters.
	font.fallbacks = [_crisp(load(FUSION + "fusion-pixel-8px-proportional-%s.ttf.woff2" % han)), cyrillic]
	return font


## The 10-pixel font with Cyrillic and every accented Latin letter, drawn at size 10.
static func ten_pixel_font() -> FontFile:
	if _ten_pixel == null:
		_ten_pixel = _crisp(load(FUSION + "fusion-pixel-10px-proportional-latin.ttf.woff2"))
	return _ten_pixel


## The interface's text size in pixels, which is the size its pixel font is drawn for.
static func text_size(locale := "") -> int:
	if locale == "":
		locale = TranslationServer.get_locale()
	return 10 if locale.get_slice("_", 0) in TEN_PIXEL else 8


## A copy of a pixel font drawn without smoothing, so it stays crisp at the game's low resolution.
static func _crisp(source: FontFile) -> FontFile:
	var font: FontFile = source.duplicate()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return font


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


## A speech bubble over someone's head: a small parchment note with a tail pointing down at them, which fades after
## a few seconds. One person speaks at a time, so a new bubble replaces any still showing. With `follow`, which returns
## where the speaker is now, the bubble stays over them as they walk or the view scrolls, and hides while they are out of view.
static func speech(parent: Control, at: Vector2, text: String, follow := Callable()) -> void:
	if text == "":
		return
	for old in parent.get_children():
		if old.has_meta("speech"):
			old.queue_free()
	var bubble := PanelContainer.new()
	bubble.set_meta("speech", true)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.99, 0.95, 0.86)
	box.border_color = INK
	box.set_border_width_all(1)
	box.set_content_margin_all(4)
	bubble.add_theme_stylebox_override("panel", box)
	parent.add_child(bubble)
	para(bubble, text, 140)
	bubble.reset_size()
	var tail := Control.new()
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.draw.connect(func():
		for k in 4:
			tail.draw_rect(Rect2(-3 + k, k, 7 - k * 2, 1), INK if k == 3 else Color(0.99, 0.95, 0.86))
			tail.draw_rect(Rect2(-4 + k, k, 1, 1), INK)
			tail.draw_rect(Rect2(3 - k, k, 1, 1), INK))
	bubble.add_child(tail)
	var place := func(_t := 0.0) -> void:
		var spot: Vector2 = follow.call() if follow.is_valid() else at
		bubble.visible = Rect2(Vector2.ZERO, parent.size).has_point(spot)
		var pos := (spot - Vector2(bubble.size.x / 2.0, bubble.size.y + 4)).round()
		bubble.position = pos.clamp(Vector2(2, 2), parent.size - bubble.size - Vector2(2, 2))
		tail.position = Vector2(roundf(spot.x - bubble.position.x), bubble.size.y - 1)
	# The bubble's size settles once its text is laid out, so it is placed a frame later.
	(func() -> void:
		await parent.get_tree().process_frame
		if not is_instance_valid(bubble):
			return
		bubble.reset_size()
		place.call()).call()
	fade_in(bubble, 0.15)
	var tween := bubble.create_tween()
	tween.tween_interval(3.5)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
	tween.tween_callback(bubble.queue_free)
	if follow.is_valid():
		bubble.create_tween().tween_method(place, 0.0, 1.0, 4.0)


## A 1px frame just outside a shape; drawn as four filled strips because an unfilled rect straddles pixel edges.
static func outline(item: CanvasItem, r: Rect2, colour: Color) -> void:
	item.draw_rect(Rect2(r.position.x - 1, r.position.y - 1, r.size.x + 2, 1), colour)
	item.draw_rect(Rect2(r.position.x - 1, r.end.y, r.size.x + 2, 1), colour)
	item.draw_rect(Rect2(r.position.x - 1, r.position.y, 1, r.size.y), colour)
	item.draw_rect(Rect2(r.end.x, r.position.y, 1, r.size.y), colour)
