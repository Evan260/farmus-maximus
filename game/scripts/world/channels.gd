extends Node2D
## The aqueduct channels along the front of the home farm, with water running through them once they are built.

var from_x := 480.0
var to_x := 816.0
var _t := 0.0


func _process(delta: float) -> void:
	visible = Game.upgrade_value("channels") > 0.0
	if visible:
		_t += delta * (0.0 if Settings.reduced_motion else 1.0)
		queue_redraw()


func _draw() -> void:
	var stone := Color(0.62, 0.55, 0.47)
	var dark := Color(0.45, 0.39, 0.34)
	draw_rect(Rect2(from_x, 267, to_x - from_x, 1), stone)
	draw_rect(Rect2(from_x, 268, to_x - from_x, 2), Color(0.33, 0.47, 0.6))
	draw_rect(Rect2(from_x, 270, to_x - from_x, 1), dark)
	# Glints travel along the water so it reads as flowing.
	for x in range(int(from_x), int(to_x), 9):
		var offset := int(fmod(_t * 12.0 + x * 0.37, 9.0))
		draw_rect(Rect2(x + offset, 268, 2, 1), Color(0.8, 0.9, 1.0, 0.8))
