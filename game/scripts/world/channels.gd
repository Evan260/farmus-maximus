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
const SOIL := Color8(92, 64, 44)
const SOIL_DARK := Color8(66, 44, 32)
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
## The castellum part built: footings, half-built walls, and walls waiting for their roof.
var _stages: Array[Texture2D] = []


func _ready() -> void:
	_house = Sprite2D.new()
	_house.texture = CASTELLUM
	_house.centered = false
	_house.position = Vector2(from_x - OUTLET_X, 267 - BASE_Y)
	add_child(_house)
	_stages = _building_stages()


func _process(delta: float) -> void:
	visible = Game.upgrade_value("channels") > 0.0 or Game.projects.has("channels")
	if visible:
		_t += delta * (0.0 if Settings.reduced_motion else 1.0)
		queue_redraw()
	# The castellum goes up first, course by course, before the channel is dug from it.
	var p := _progress()
	_house.texture = _stages[mini(int(p / 0.1), _stages.size() - 1)] if _building() and p < 0.3 else CASTELLUM


## The castellum at three points in its building, cut from the finished picture: its footings, its walls half up,
## and its walls finished but not yet roofed. Each top course is left ragged, as stone is laid unevenly.
func _building_stages() -> Array[Texture2D]:
	var src := CASTELLUM.get_image()
	src.convert(Image.FORMAT_RGBA8)
	var used := src.get_used_rect()
	# The walls start below the last row that is mostly roof tile.
	var wall_top := used.position.y
	for y in range(used.position.y, used.end.y):
		var tiles := 0
		var solid := 0
		for x in range(used.position.x, used.end.x):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				solid += 1
				if (c.h < 0.06 or c.h > 0.95) and c.s > 0.45:
					tiles += 1
		if solid > 0 and tiles * 2 > solid:
			wall_top = y + 1
	var out: Array[Texture2D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for share in [0.22, 0.55, 1.0]:
		var img := src.duplicate() as Image
		var height := float(used.end.y - wall_top)
		for x in range(used.position.x, used.end.x):
			var cut := used.end.y - int(roundf(height * share)) + (rng.randi_range(0, 2) if share < 1.0 else 0)
			for y in range(0, cut):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
		out.append(ImageTexture.create_from_image(img))
	return out


func _building() -> bool:
	return Game.projects.has("channels")


## How far the work has come, from 0 when it starts to 1 when the water can flow.
func _progress() -> float:
	if not _building():
		return 1.0
	return clampf(1.0 - float(Game.projects["channels"]) / maxf(1.0, Game.upgrade_seconds("channels")), 0.0, 1.0)


## Where the lining of the channel has reached: it is dug from the castellum outwards after the house is up.
func front() -> float:
	return lerpf(from_x, to_x, clampf((_progress() - 0.3) / 0.7, 0.0, 1.0))


func _draw() -> void:
	if _building():
		_draw_works()
		return
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


## The channel while it is built: stone lining up to where the diggers have reached, still dry, and a heap of dug
## earth and stones at the front; the footbridge and the culvert go in as the work passes them.
func _draw_works() -> void:
	var reach := front()
	var stone := Color(0.62, 0.55, 0.47)
	if reach > from_x:
		draw_rect(Rect2(from_x, 267, reach - from_x, 1), stone)
		draw_rect(Rect2(from_x, 268, reach - from_x, 2), DARK)
		draw_rect(Rect2(from_x, 270, reach - from_x, 1), Color(0.45, 0.39, 0.34))
	if _progress() >= 0.3 and reach < to_x:
		var x := int(reach)
		for i in 9:
			var w := 9 - i
			draw_rect(Rect2(x + i / 2, 266 - i / 2, w, 1), SOIL if i % 3 else SOIL_DARK)
		draw_rect(Rect2(x - 3, 265, 2, 2), STONE)
		draw_rect(Rect2(x + 8, 266, 3, 2), STONE_SHADE)
		draw_rect(Rect2(x - 7, 267, 2, 1), STONE_LIGHT)
	if reach >= bridge_to:
		_draw_bridge()
	if reach >= to_x - 1.0:
		_draw_culvert()


## Water tumbling out of the castellum's arch into the head of the channel.
func _draw_outflow() -> void:
	var step := int(_t * 10.0)
	var x := int(from_x) - 2
	for y in range(264, 268):
		draw_rect(Rect2(x, y, 4, 1), FOAM if posmod(y - step, 3) == 0 else FALL)
	draw_rect(Rect2(x - 1 + 2 * (step % 3), 268, 1, 1), FOAM)
	draw_rect(Rect2(x + 4 - (step % 2), 268, 1, 1), FOAM)


## Where the walkway crosses, the water runs under it through a little culvert: the path's own sandy surface carries
## on over the top, and a dark mouth with a stone lip shows on each side.
func _draw_bridge() -> void:
	var a := int(bridge_from)
	var b := int(bridge_to)
	var sand := [Color8(176, 142, 98), Color8(192, 160, 114), Color8(154, 122, 82)]
	for x in range(a, b):
		for y in range(266, 272):
			draw_rect(Rect2(x, y, 1, 1), sand[(x * 7 + y * 3) % 5 % 3])
	for side in [a - 1, b - 2]:
		draw_rect(Rect2(side, 268, 3, 2), DARK)
		draw_rect(Rect2(side, 267, 3, 1), STONE_LIGHT.darkened(0.1))
		draw_rect(Rect2(side, 270, 3, 1), STONE_SHADE)


## Where the channel ends the water soaks away into a patch of dark, wet earth beyond a rounded stone end.
func _draw_culvert() -> void:
	var x := int(to_x)
	draw_rect(Rect2(x, 267, 2, 1), STONE_LIGHT.darkened(0.1))
	draw_rect(Rect2(x + 1, 268, 1, 2), STONE)
	draw_rect(Rect2(x, 270, 2, 1), STONE_SHADE)
	var wet := Color8(74, 54, 40)
	for k in 9:
		draw_rect(Rect2(x + 2 + k, 268 + (k % 2), 1, 2 if k < 6 else 1), wet.lightened(0.04 * k))
