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
	var post := Color(0.36, 0.24, 0.16)
	var dark := Color(0.3, 0.2, 0.14)
	var board := Color(0.55, 0.38, 0.24)
	var legs := _board.size.x / 2 - 8
	for x in [-legs - 2, legs - 1]:
		draw_rect(Rect2(x, _board.end.y, 3, POST), post)
	draw_rect(_board, dark)
	draw_rect(_board.grow(-1), board)
	var ascent := FONT.get_ascent(FONT_SIZE)
	for i in _lines.size():
		var w := FONT.get_string_size(_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at := Vector2(roundf(-w / 2), _board.position.y + PAD.y + i * LINE + roundf(ascent) - 2)
		draw_string(FONT, at, _lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.99, 0.95, 0.86))
	if hovered:
		draw_rect(_board.grow(1), Color(1, 0.96, 0.85, 0.8), false, 1.0)


func contains(point: Vector2) -> bool:
	return visible and world_rect().has_point(point)


func world_rect() -> Rect2:
	return Rect2(position + _board.position, Vector2(_board.size.x, SINK - _board.position.y))
