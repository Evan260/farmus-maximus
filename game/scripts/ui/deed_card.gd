extends Control
## A land deed as the temple keeps it: a parchment scroll on wooden rods, framed and headed in red like a fine
## document, sealed in red wax with ribbons once the land is yours.

const PARCH := Color(0.95, 0.87, 0.67)
const PARCH_EDGE := Color(0.76, 0.63, 0.43)
const ROLL := [Color(0.62, 0.48, 0.31), Color(0.84, 0.72, 0.5), Color(0.97, 0.91, 0.74), Color(0.84, 0.72, 0.5), Color(0.62, 0.48, 0.31)]
const ROD := [Color(0.45, 0.28, 0.16), Color(0.62, 0.41, 0.24), Color(0.36, 0.22, 0.12)]
const INK := Color(0.36, 0.24, 0.18)
const RUBRIC := Color(0.62, 0.2, 0.14)
const GOLD := Color(0.86, 0.66, 0.24)
const WAX := Color(0.72, 0.16, 0.14)
const SIZE := Vector2(104, 70)
## How wide a line of writing can be, inside the ruled frame with a pixel or two to spare.
const ROOM := 84.0

var title := ""
## "owned", "sale" or "later".
var state := "sale"
var price := 0
var _fade := 1.0


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := SIZE.x
	var h := SIZE.y
	_fade = 1.0 if state != "later" else 0.5
	var sheet := Rect2(4, 4, w - 8, h - 8)
	_rect(Rect2(sheet.position + Vector2(1, 2), sheet.size), Color(0.2, 0.12, 0.08, 0.25))
	_rect(sheet, PARCH_EDGE)
	_rect(sheet.grow(-1), PARCH.darkened(0.05))
	_rect(sheet.grow(-2), PARCH)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(title)
	for i in 22:
		_rect(Rect2(rng.randi_range(8, int(w) - 10), rng.randi_range(9, int(h) - 11), rng.randi_range(1, 3), 1), PARCH.darkened(0.06))
	_frame(sheet.grow(-4))
	# The rolled ends: a cylinder of parchment on a rod whose turned ends stick out at the sides.
	for end_y in [1.0, h - 6.0]:
		for r in ROLL.size():
			_rect(Rect2(3, end_y + r, w - 6, 1), ROLL[r])
		for side in [0.0, w - 3.0]:
			for r in ROD.size():
				_rect(Rect2(side, end_y + 1 + r, 3, 1), ROD[r])
	var font := UiKit.ui_font()
	var size := UiKit.text_size()
	var step := size + 1
	var header := tr("DEED")
	var hw := font.get_string_size(header, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_centred(font, header, 18, size, RUBRIC)
	var mid := roundf(w / 2.0)
	# The rule and diamond either side of the heading shorten to fit the room beside it, and give way to a long one.
	var rule := minf(10.0, floorf(ROOM / 2.0 - roundf(hw / 2.0) - 6.0))
	for side in ([-1, 1] if rule >= 2.0 else []):
		var inner: float = mid + side * (roundf(hw / 2.0) + 3)
		_rect(Rect2(minf(inner, inner + side * rule), 15, rule, 1), RUBRIC.lerp(PARCH, 0.4))
		_rect(Rect2(inner + side * (rule + 2) - 1, 14, 2, 2), RUBRIC.lerp(PARCH, 0.4))
	var heading := _lines(font, _upper(title), size)
	var heading_base := 29.0 if heading.size() == 1 else 28.0
	for k in heading.size():
		_centred(font, heading[k], heading_base + k * step, size, INK)
	var foot_lines := 1
	match state:
		"owned":
			_seal(Vector2(w - 22, h - 20))
			draw_string(font, Vector2(13, h - 13), tr("Yours"), HORIZONTAL_ALIGNMENT_LEFT, -1, size, RUBRIC)
		"sale":
			var text := "%d %s" % [price, tr("sestertii")]
			# A long word for the coins gives way to the coin alone beside the number.
			if _width(font, text, size) + 7 > ROOM:
				text = str(price)
			var x := roundf((w - _width(font, text, size) - 7) / 2.0)
			_coin(Vector2(x + 2, h - 16))
			draw_string(font, Vector2(x + 7, h - 13), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)
		"later":
			var foot := _lines(font, tr("Not for sale"), size)
			foot_lines = foot.size()
			for k in foot_lines:
				_centred(font, foot[k], h - 13 - (foot_lines - 1 - k) * step, size, INK * Color(1, 1, 1, _fade))
	# The ruled lines under the name fill the room left between it and the bottom line.
	var lowest := h - 13 - (foot_lines - 1) * step - size - 1
	for line in 3:
		var y := heading_base + (heading.size() - 1) * step + 5 + line * 4
		if y > lowest:
			break
		var lw := 50.0 - line * 12.0
		_rect(Rect2(roundf((w - lw) / 2.0), y, lw, 1), INK.lerp(PARCH, 0.72))


## Text too wide for the card is split in two at the space that leaves the wider half narrowest.
func _lines(font: Font, text: String, size: int) -> PackedStringArray:
	var best := PackedStringArray([text])
	var words := text.split(" ")
	if _width(font, text, size) <= ROOM or words.size() < 2:
		return best
	var widest := INF
	for k in range(1, words.size()):
		var pair := PackedStringArray([" ".join(words.slice(0, k)), " ".join(words.slice(k))])
		var wider := maxf(_width(font, pair[0], size), _width(font, pair[1], size))
		if wider < widest:
			widest = wider
			best = pair
	return best


func _width(font: Font, text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Capitals as the language writes them: in Turkish a capital i keeps its dot.
func _upper(text: String) -> String:
	if TranslationServer.get_locale().begins_with("tr"):
		text = text.replace("i", "İ")
	return text.to_upper()


## A thin ruled frame inside the sheet with a small diamond at each corner.
func _frame(r: Rect2) -> void:
	var line := RUBRIC.lerp(PARCH, 0.55)
	_rect(Rect2(r.position.x + 3, r.position.y, r.size.x - 6, 1), line)
	_rect(Rect2(r.position.x + 3, r.end.y - 1, r.size.x - 6, 1), line)
	_rect(Rect2(r.position.x, r.position.y + 3, 1, r.size.y - 6), line)
	_rect(Rect2(r.end.x - 1, r.position.y + 3, 1, r.size.y - 6), line)
	for corner in [r.position, Vector2(r.end.x - 1, r.position.y), Vector2(r.position.x, r.end.y - 1), r.end - Vector2.ONE]:
		_rect(Rect2(corner + Vector2(-1, 0), Vector2(3, 1)), RUBRIC.lerp(PARCH, 0.25))
		_rect(Rect2(corner + Vector2(0, -1), Vector2(1, 3)), RUBRIC.lerp(PARCH, 0.25))


## A wax seal pressed with a ring, with two ribbons hanging from under it.
func _seal(at: Vector2) -> void:
	var ribbon := Color(0.55, 0.12, 0.12)
	for k in 7:
		_rect(Rect2(at.x - 4 - k / 3, at.y + 3 + k, 2, 1), ribbon)
		_rect(Rect2(at.x + 3 + k / 3, at.y + 3 + k, 2, 1), ribbon.darkened(0.15))
	for y in range(-6, 7):
		var half := int(sqrt(42.0 - y * y))
		_rect(Rect2(at.x - half, at.y + y, half * 2 + 1, 1), WAX)
	for y in range(-4, 5):
		var half := int(sqrt(18.0 - y * y))
		_rect(Rect2(at.x - half, at.y + y, 1, 1), WAX.darkened(0.25))
		_rect(Rect2(at.x + half, at.y + y, 1, 1), WAX.lightened(0.2))
	_rect(Rect2(at + Vector2(-3, -5), Vector2(3, 1)), WAX.lightened(0.4))
	_rect(Rect2(at + Vector2(-1, -2), Vector2(3, 5)), WAX.darkened(0.2))
	_rect(Rect2(at + Vector2(-2, -1), Vector2(5, 3)), WAX.darkened(0.2))


## A little gold coin beside the price.
func _coin(at: Vector2) -> void:
	_rect(Rect2(at + Vector2(-1, -2), Vector2(3, 5)), GOLD.darkened(0.25))
	_rect(Rect2(at + Vector2(-2, -1), Vector2(5, 3)), GOLD.darkened(0.25))
	_rect(Rect2(at + Vector2(-1, -1), Vector2(3, 3)), GOLD)
	_rect(Rect2(at + Vector2(-1, -1), Vector2(1, 1)), GOLD.lightened(0.4))


func _rect(r: Rect2, colour: Color) -> void:
	draw_rect(r, colour * Color(1, 1, 1, _fade))


func _centred(font: Font, text: String, baseline: float, size: int, colour: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(roundf((SIZE.x - w) / 2.0), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour * Color(1, 1, 1, _fade))
