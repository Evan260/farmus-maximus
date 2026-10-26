extends Node2D
## The aqueduct channels along the front of the home farm, with water running through them once they are built. The
## water comes out of a castellum, the little stone house where a branch of the aqueduct is shared out, runs under a
## footbridge where the walkway to the farmhouse crosses it, and drains into a culvert under the road.

const STONE := Color8(147, 111, 75)
const STONE_SHADE := Color8(124, 93, 66)
const STONE_LIGHT := Color8(225, 182, 110)
const MORTAR := Color8(83, 66, 58)
const DARK := Color8(49, 41, 41)
const WATER := Color(0.33, 0.47, 0.6)
const FALL := Color(0.62, 0.76, 0.88, 0.9)
const FOAM := Color(0.86, 0.93, 1.0, 0.95)
const CASTELLUM := preload("res://assets/sprites/farm/castellum.png")
## Where the castellum's arched outlet sits in its picture, and where the picture's walls meet the ground.
const OUTLET_X := 28
const BASE_Y := 41

var from_x := 476.0
var to_x := 972.0
## The walkway to the farmhouse, which crosses the channel on a footbridge.
var bridge_from := 815.0
var bridge_to := 859.0
var _t := 0.0
var _house: Sprite2D


func _ready() -> void:
	_house = Sprite2D.new()
	_house.texture = CASTELLUM
	_house.centered = false
	_house.position = Vector2(from_x - OUTLET_X, 267 - BASE_Y)
	add_child(_house)


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
	_draw_outflow()
	_draw_bridge()
	_draw_culvert()


## Water tumbling out of the castellum's arch into the head of the channel.
func _draw_outflow() -> void:
	var step := int(_t * 10.0)
	var x := int(from_x) - 2
	for y in range(264, 268):
		draw_rect(Rect2(x, y, 4, 1), FOAM if posmod(y - step, 3) == 0 else FALL)
	draw_rect(Rect2(x - 1 + 2 * (step % 3), 268, 1, 1), FOAM)
	draw_rect(Rect2(x + 4 - (step % 2), 268, 1, 1), FOAM)


## A low stone footbridge carrying the walkway over the water, with a small arch the channel runs through.
func _draw_bridge() -> void:
	var a := int(bridge_from)
	var w := int(bridge_to - bridge_from)
	draw_rect(Rect2(a, 265, w, 6), STONE)
	draw_rect(Rect2(a, 265, w, 1), STONE_LIGHT)
	draw_rect(Rect2(a, 266, w, 1), Color8(192, 160, 114))
	draw_rect(Rect2(a, 270, w, 1), MORTAR)
	for x in [a, a + w - 1]:
		draw_rect(Rect2(x, 264, 1, 7), STONE_SHADE)
	var mid := a + w / 2
	draw_rect(Rect2(mid - 6, 268, 12, 2), DARK)
	draw_rect(Rect2(mid - 5, 267, 10, 1), DARK)
	draw_rect(Rect2(mid - 4, 269, 8, 1), WATER)


## Where the channel ends it runs into a stone culvert and away under the road.
func _draw_culvert() -> void:
	var x := int(to_x)
	draw_rect(Rect2(x, 265, 7, 7), STONE)
	draw_rect(Rect2(x, 265, 7, 1), STONE_LIGHT)
	draw_rect(Rect2(x + 6, 266, 1, 6), STONE_SHADE)
	draw_rect(Rect2(x, 267, 4, 4), DARK)
	draw_rect(Rect2(x, 268, 1, 2), WATER)
