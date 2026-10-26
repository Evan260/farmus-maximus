extends Node2D
## A wooden "for sale" sign standing in land the player does not own yet; clicking it buys the deed.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const FONT_SIZE := 8
const LINE := 9
const PAD := Vector2(5, 4)
## How tall the posts stand between the ground and the board.
const POST := 10
## How deep the posts sink into the grass, so the sign is planted rather than resting on the ground line.
const SINK := 3
const INK := Color8(42, 29, 41)
const WOOD_DARK := Color8(78, 50, 40)
const WOOD := Color8(128, 84, 54)
const WOOD_LIGHT := Color8(156, 104, 64)
const GRAIN := Color8(110, 70, 46)
const NAIL := Color8(70, 66, 70)
const SHADOW := Color(0.18, 0.14, 0.08, 0.3)

var zone_id := ""
var hovered := false
var _lines: Array[String] = []
var _board := Rect2()


func _process(_delta: float) -> void:
	visible = not Game.zone_owned(zone_id)
	var z := Game.zone_info(zone_id)
	var lines: Array[String] = [String(z.get("name", "")).to_upper(), "FOR SALE %d" % int(z.get("deed", 0))]
	if lines != _lines:
		_lines = lines
		var width := 0.0
		for line in _lines:
			width = maxf(width, FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
		# The board is sized to its text, so a longer name or price never spills over the edge.
		var size := Vector2(ceilf(width) + PAD.x * 2, LINE * _lines.size() + PAD.y * 2 - 2)
		_board = Rect2(Vector2(-roundf(size.x / 2), SINK - POST - size.y), size)
	queue_redraw()


func _draw() -> void:
	var b := _board
	var legs := b.size.x / 2 - 8
	draw_rect(Rect2(b.position.x + 2, SINK - 1, b.size.x - 4, 1), SHADOW)
	draw_rect(Rect2(b.position.x - 1, SINK, b.size.x + 2, 1), SHADOW)
	for x in [-legs - 2, legs - 1]:
		draw_rect(Rect2(x, b.end.y, 1, POST), WOOD_LIGHT)
		draw_rect(Rect2(x + 1, b.end.y, 1, POST), WOOD)
		draw_rect(Rect2(x + 2, b.end.y, 1, POST), WOOD_DARK)
		draw_rect(Rect2(x, b.end.y, 3, 1), INK)
	draw_rect(b, INK)
	var inner := b.grow(-1)
	draw_rect(inner, WOOD)
	# Three planks with dark seams between them, each lit along its top edge.
	var plank := inner.size.y / 3.0
	for i in 3:
		var y := roundf(inner.position.y + i * plank)
		draw_rect(Rect2(inner.position.x, y, inner.size.x, 1), WOOD_LIGHT)
		if i > 0:
			draw_rect(Rect2(inner.position.x, y - 1, inner.size.x, 1), WOOD_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(zone_id)
	for i in int(inner.size.x / 9):
		var at := Vector2(inner.position.x + rng.randi_range(2, int(inner.size.x) - 6), inner.position.y + rng.randi_range(2, int(inner.size.y) - 2))
		draw_rect(Rect2(at, Vector2(rng.randi_range(2, 4), 1)), GRAIN)
	for x in [inner.position.x + 1, inner.end.x - 2]:
		draw_rect(Rect2(x, inner.position.y + 1, 1, 1), NAIL)
		draw_rect(Rect2(x, inner.end.y - 2, 1, 1), NAIL)
	var ascent := FONT.get_ascent(FONT_SIZE)
	for i in _lines.size():
		var w := FONT.get_string_size(_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at := Vector2(roundf(-w / 2), b.position.y + PAD.y + i * LINE + roundf(ascent) - 2)
		draw_string(FONT, at + Vector2(0, 1), _lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, INK)
		draw_string(FONT, at, _lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.99, 0.95, 0.86))
	if hovered:
		UiKit.outline(self, b, Color(1, 0.96, 0.85, 0.8))


func contains(point: Vector2) -> bool:
	return visible and world_rect().has_point(point)


func world_rect() -> Rect2:
	return Rect2(position + _board.position, Vector2(_board.size.x, SINK - _board.position.y))
