extends Control
## A land deed as the temple keeps it: a parchment rolled at both ends with the land's name written on it, sealed in red
## wax once the land is yours.

const PARCH := Color(0.95, 0.87, 0.67)
const PARCH_EDGE := Color(0.76, 0.63, 0.43)
const ROLL := [Color(0.62, 0.48, 0.31), Color(0.84, 0.72, 0.5), Color(0.97, 0.91, 0.74), Color(0.84, 0.72, 0.5), Color(0.62, 0.48, 0.31)]
const INK := Color(0.36, 0.24, 0.18)
const WAX := Color(0.72, 0.16, 0.14)
const SIZE := Vector2(92, 66)

var title := ""
## "owned", "sale" or "later".
var state := "sale"
var price := 0


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := SIZE.x
	var h := SIZE.y
	var fade := 1.0 if state != "later" else 0.5
	draw_rect(Rect2(3, 6, w - 4, h - 8), Color(0.2, 0.12, 0.08, 0.25 * fade))
	draw_rect(Rect2(2, 4, w - 4, h - 8), PARCH_EDGE * Color(1, 1, 1, fade))
	draw_rect(Rect2(3, 4, w - 6, h - 8), PARCH * Color(1, 1, 1, fade))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(title)
	for i in 26:
		draw_rect(Rect2(rng.randi_range(4, int(w) - 6), rng.randi_range(6, int(h) - 8), rng.randi_range(1, 3), 1), PARCH.darkened(0.06) * Color(1, 1, 1, fade))
	# The rolled ends: five rows shaded like a cylinder, a little wider than the sheet.
	for end_y in [0.0, h - 5.0]:
		for r in ROLL.size():
			draw_rect(Rect2(0, end_y + r, w, 1), ROLL[r] * Color(1, 1, 1, fade))
	var font := UiKit.FONT
	_centred(font, tr("DEED"), 13, 8, INK.lerp(PARCH, 0.45) * Color(1, 1, 1, fade))
	_centred(font, title.to_upper(), 25, 8, INK * Color(1, 1, 1, fade))
	for line in 3:
		var y := 32 + line * 4
		draw_rect(Rect2(10, y, w - 20 - line * 9, 1), INK.lerp(PARCH, 0.7) * Color(1, 1, 1, fade))
	match state:
		"owned":
			var at := Vector2(w - 18, h - 18)
			draw_rect(Rect2(at + Vector2(-3, 4), Vector2(2, 7)), WAX.darkened(0.25))
			draw_rect(Rect2(at + Vector2(2, 4), Vector2(2, 7)), WAX.darkened(0.25))
			for y in range(-5, 6):
				var half := int(sqrt(30.0 - y * y))
				draw_rect(Rect2(at.x - half, at.y + y, half * 2 + 1, 1), WAX)
			draw_rect(Rect2(at + Vector2(-2, -3), Vector2(2, 1)), WAX.lightened(0.35))
			draw_rect(Rect2(at + Vector2(-1, -1), Vector2(3, 3)), WAX.darkened(0.2))
			draw_string(font, Vector2(10, h - 10), tr("Yours"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, INK)
		"sale":
			_centred(font, "%d %s" % [price, tr("sestertii")], h - 11, 8, INK)
		"later":
			_centred(font, tr("Not yet for sale"), h - 11, 8, INK * Color(1, 1, 1, fade))


func _centred(font: Font, text: String, baseline: float, size: int, colour: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(roundf((SIZE.x - w) / 2.0), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)
