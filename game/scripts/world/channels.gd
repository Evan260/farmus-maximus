extends Node2D
## The aqueduct channels along the front of the home farm, with water running through them once they are built. The
## water comes down a stone pier from the aqueduct behind the farm and runs out into a culvert under the road.

const STONE := Color8(147, 111, 75)
const STONE_SHADE := Color8(124, 93, 66)
const STONE_LIGHT := Color8(225, 182, 110)
const MORTAR := Color8(83, 66, 58)
const DARK := Color8(49, 41, 41)
const WATER := Color(0.33, 0.47, 0.6)
const FALL := Color(0.62, 0.76, 0.88, 0.9)
const FOAM := Color(0.86, 0.93, 1.0, 0.95)
## The top of the pier, level with the aqueduct's deck in the land behind.
const PIER_TOP := 194

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
	draw_rect(Rect2(from_x, 268, to_x - from_x, 2), WATER)
	draw_rect(Rect2(from_x, 270, to_x - from_x, 1), dark)
	# Glints travel along the water so it reads as flowing.
	for x in range(int(from_x), int(to_x), 9):
		var offset := int(fmod(_t * 12.0 + x * 0.37, 9.0))
		draw_rect(Rect2(x + offset, 268, 2, 1), Color(0.8, 0.9, 1.0, 0.8))
	_draw_pier()
	_draw_culvert()


## A stone pier carrying a branch of the aqueduct down to the farm: the water pours from a spout at the top into a
## little basin that feeds the channel.
func _draw_pier() -> void:
	var left := int(from_x) - 12
	var step := int(_t * 10.0)
	draw_rect(Rect2(left, PIER_TOP, 12, 271 - PIER_TOP), STONE)
	for y in range(PIER_TOP + 4, 270, 5):
		draw_rect(Rect2(left, y, 12, 1), MORTAR)
		var joint := left + (3 if (y / 5) % 2 == 0 else 8)
		draw_rect(Rect2(joint, y + 1, 1, 4), MORTAR)
	draw_rect(Rect2(left, PIER_TOP, 1, 271 - PIER_TOP), STONE_LIGHT.darkened(0.15))
	draw_rect(Rect2(left + 10, PIER_TOP, 2, 271 - PIER_TOP), STONE_SHADE)
	draw_rect(Rect2(left - 1, PIER_TOP - 2, 14, 2), STONE_LIGHT)
	draw_rect(Rect2(left - 1, PIER_TOP, 14, 1), MORTAR)
	# The spout juts out towards the farm with water spilling over its lip.
	draw_rect(Rect2(left + 12, PIER_TOP + 3, 4, 2), STONE)
	draw_rect(Rect2(left + 12, PIER_TOP + 5, 4, 1), MORTAR)
	draw_rect(Rect2(left + 12, PIER_TOP + 2, 4, 1), WATER)
	var fall_x := left + 15
	for y in range(PIER_TOP + 3, 264):
		draw_rect(Rect2(fall_x, y, 2, 1), FOAM if posmod(y - step * 2, 7) == 0 else FALL)
	# The basin at the foot of the pier.
	draw_rect(Rect2(left + 11, 263, 10, 1), STONE_LIGHT)
	draw_rect(Rect2(left + 11, 264, 1, 6), STONE)
	draw_rect(Rect2(left + 12, 264, 8, 4), WATER)
	draw_rect(Rect2(left + 11, 270, 10, 1), MORTAR)
	draw_rect(Rect2(fall_x - 1 + 2 * (step % 2), 264, 1, 1), FOAM)
	draw_rect(Rect2(fall_x + 2 - 2 * (step % 2), 265, 1, 1), FOAM)


## Where the channel ends it runs into a stone culvert and away under the road.
func _draw_culvert() -> void:
	var x := int(to_x)
	draw_rect(Rect2(x, 265, 7, 7), STONE)
	draw_rect(Rect2(x, 265, 7, 1), STONE_LIGHT)
	draw_rect(Rect2(x + 6, 266, 1, 6), STONE_SHADE)
	draw_rect(Rect2(x, 267, 4, 4), DARK)
	draw_rect(Rect2(x, 268, 1, 2), WATER)
