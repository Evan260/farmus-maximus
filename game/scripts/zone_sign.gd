extends Node2D
## A wooden "for sale" sign standing in land the player does not own yet; clicking it buys the deed.

var zone_id := ""
var hovered := false
var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Regular.ttf"))
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(0.99, 0.95, 0.86))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-50, -37)
	_label.size = Vector2(100, 22)
	add_child(_label)


func _process(_delta: float) -> void:
	visible = not Game.zone_owned(zone_id)
	var z := Game.zone_info(zone_id)
	_label.text = "%s\nFOR SALE %d" % [String(z.get("name", "")), int(z.get("deed", 0))]
	queue_redraw()


func _draw() -> void:
	var post := Color(0.36, 0.24, 0.16)
	var board := Color(0.55, 0.38, 0.24)
	draw_rect(Rect2(-30, -14, 3, 14), post)
	draw_rect(Rect2(27, -14, 3, 14), post)
	draw_rect(Rect2(-52, -40, 104, 27), Color(0.3, 0.2, 0.14))
	draw_rect(Rect2(-51, -39, 102, 25), board)
	if hovered:
		draw_rect(Rect2(-53, -41, 106, 29), Color(1, 0.96, 0.85, 0.8), false, 1.0)


func contains(point: Vector2) -> bool:
	return visible and Rect2(position + Vector2(-52, -40), Vector2(104, 40)).has_point(point)


func world_rect() -> Rect2:
	return Rect2(position + Vector2(-52, -40), Vector2(104, 40))
