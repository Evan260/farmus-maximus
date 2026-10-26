extends Node2D
## Wooden scaffolding standing in front of a building while it is worked on: poles, planks at each storey, cross
## braces and ladders. It is drawn to fit whatever building it stands against, and rises out of the ground or sinks
## back into it as the work starts and ends.

const POLE := Color8(156, 112, 64)
const POLE_DARK := Color8(108, 74, 44)
const PLANK_TOP := Color8(184, 140, 86)
const PLANK := Color8(140, 100, 58)
const PLANK_UNDER := Color8(92, 62, 40)
const BRACE := Color8(118, 82, 50)
const RAIL := Color8(126, 88, 52)

## The building's outline in estate pixels; the scaffold stands on its bottom edge.
var rect := Rect2()
## Where ladders stand, in pixels from the building's left edge.
var ladders: Array = []
## How many plank floors it has; 0 puts one every storey's height up the building.
var storeys := 0
## How much of the scaffold has come up out of the ground, from 0 to 1.
var share := 1.0:
	set(value):
		share = value
		queue_redraw()


func rise(seconds := 2.0) -> void:
	_slide(0.0, 1.0, seconds)


func sink(seconds := 2.0) -> Tween:
	return _slide(1.0, 0.0, seconds)


func _slide(from: float, to: float, seconds: float) -> Tween:
	share = from
	var tween := create_tween()
	tween.tween_property(self, "share", to, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


func _draw() -> void:
	if share <= 0.0:
		return
	var ground := rect.end.y
	var height := roundf(rect.size.y * 0.8)
	# Everything is drawn lowered by the part still under the ground, and cut off at the ground line.
	var drop := roundf(height * (1.0 - share))
	var top := ground - height
	var left := rect.position.x + 4.0
	var right := rect.end.x - 6.0
	var poles: Array[float] = []
	var x := left
	while x < right:
		poles.append(x)
		x += 30.0
	poles.append(right)
	var levels := plank_rows(rect, storeys)
	for k in poles.size() - 1:
		for l in levels.size():
			var low := levels[l] + 3.0
			var high := levels[l + 1] + 3.0 if l + 1 < levels.size() else top + 2.0
			_brace(poles[k] + 2.0, poles[k + 1], low, high, drop, ground, (k + l) % 2 == 0)
	for p in poles:
		_rect(Rect2(p, top, 1, height), POLE, drop, ground)
		_rect(Rect2(p + 1, top, 1, height), POLE_DARK, drop, ground)
	for l in levels:
		_rect(Rect2(left - 2, l, right - left + 6, 1), PLANK_TOP, drop, ground)
		_rect(Rect2(left - 2, l + 1, right - left + 6, 1), PLANK, drop, ground)
		_rect(Rect2(left - 2, l + 2, right - left + 6, 1), PLANK_UNDER, drop, ground)
	for at in ladders:
		var lx := rect.position.x + float(at) - 5.0
		_rect(Rect2(lx, top - 4, 1, height + 4), RAIL, drop, ground)
		_rect(Rect2(lx + 9, top - 4, 1, height + 4), RAIL, drop, ground)
		var rung := top - 2.0
		while rung < ground:
			_rect(Rect2(lx + 1, rung, 8, 1), POLE, drop, ground)
			rung += 4.0


## The rows of the plank floors, from the lowest up: the tops of the planks, where a builder's feet stand.
static func plank_rows(r: Rect2, floors := 0) -> Array[float]:
	var ground := r.end.y
	var top := ground - roundf(r.size.y * 0.8)
	var rows: Array[float] = []
	if floors > 0:
		for k in floors:
			rows.append(roundf(ground - (ground - top) * float(k + 1) / float(floors + 1)))
		return rows
	var y := ground - 14.0
	while y > top + 4.0:
		rows.append(y)
		y -= 17.0
	return rows


## A diagonal brace from one pole to the next across one storey, one pixel at a time.
func _brace(from_x: float, to_x: float, low: float, high: float, drop: float, ground: float, rising: bool) -> void:
	var steps := int(to_x - from_x)
	for i in steps:
		var t := float(i) / maxf(1.0, steps - 1)
		var yy := roundf(lerpf(low, high, t if rising else 1.0 - t))
		_rect(Rect2(from_x + i, yy, 1, 1), BRACE, drop, ground)


func _rect(r: Rect2, colour: Color, drop: float, ground: float) -> void:
	r.position.y += drop
	if r.position.y >= ground:
		return
	r.size.y = minf(r.size.y, ground - r.position.y)
	draw_rect(r, colour)
