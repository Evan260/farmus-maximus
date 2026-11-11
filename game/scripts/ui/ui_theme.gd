class_name UiTheme
## The interface's look: the parchment theme, the colours of its text, and the pixel fonts for each language.

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
## Dark ink for text on parchment, and cream for text on terracotta buttons or straight over the scene.
const INK := Color(0.29, 0.18, 0.14)
const CREAM := Color(0.99, 0.95, 0.86)
## Secondary text: lighter than the main ink but still dark and solid, so it reads on dim or poor screens.
const MUTED := Color(0.4, 0.27, 0.2)
const RED := Color(0.66, 0.2, 0.14)
const HEADING := Color(0.55, 0.27, 0.18)


static func build() -> Theme:
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
