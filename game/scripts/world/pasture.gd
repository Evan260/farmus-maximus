extends Node2D
## The pasture: a wooden fence, and as many hens and goats out on the grass as the barn holds.

const Walker := preload("res://scripts/world/walker.gd")
const ANIMALS := "res://assets/sprites/animals/"

var left := 1925.0
var right := 2395.0
var _hens: Array = []
var _goats: Array = []
var _sync := 0.0
var _last_hour := 0.0
var _stand: Texture2D
var _peck: Texture2D


func _ready() -> void:
	_last_hour = Game.day_time
	if ResourceLoader.exists(ANIMALS + "chicken/stand.png"):
		_stand = load(ANIMALS + "chicken/stand.png")
		_peck = load(ANIMALS + "chicken/peck.png")


func _process(delta: float) -> void:
	# The rooster greets the morning, and now and then a goat has something to say.
	if not _hens.is_empty() and _last_hour < 6.0 and Game.day_time >= 6.0:
		Sfx.play("rooster", -6.0)
	_last_hour = Game.day_time
	if not _goats.is_empty() and randf() < delta / 90.0:
		Sfx.play("goat", -10.0)
	_sync -= delta
	if _sync <= 0.0:
		_sync = 1.0
		_match_barn()
	for h in _hens:
		h["timer"] = float(h["timer"]) - delta
		if float(h["timer"]) <= 0.0:
			h["timer"] = randf_range(0.6, 3.0)
			h["pecking"] = randf() < 0.5
			if not h["pecking"]:
				h["dir"] = 1.0 if randf() < 0.5 else -1.0
		if not h["pecking"]:
			h["x"] = clampf(float(h["x"]) + float(h["dir"]) * 10.0 * delta, left + 10, right - 10)
	queue_redraw()


func _match_barn() -> void:
	var animals: Dictionary = Game.buildings.get("barn", {}).get("animals", {})
	var hens := mini(int(animals.get("chicken", 0)), 10)
	while _hens.size() < hens:
		_hens.append({"x": randf_range(left + 20, right - 20), "y": randf_range(248, 268), "dir": 1.0, "timer": 0.0, "pecking": false})
	while _hens.size() > hens:
		_hens.pop_back()
	var goats := mini(int(animals.get("goat", 0)), 5)
	while _goats.size() < goats and ResourceLoader.exists(ANIMALS + "goat/east.png"):
		var g := Walker.new()
		g.dir = ANIMALS + "goat/"
		g.min_x = left + 20
		g.max_x = right - 20
		g.speed = 9.0
		g.idle_anim = "graze"
		g.position = Vector2(randf_range(left + 30, right - 30), randf_range(250, 262))
		add_child(g)
		_goats.append(g)
	while _goats.size() > goats:
		_goats.pop_back().queue_free()


func _draw() -> void:
	var wood := Color(0.45, 0.31, 0.2)
	var light := Color(0.58, 0.42, 0.28)
	for x in range(int(left), int(right) + 1, 18):
		draw_rect(Rect2(x, 222, 2, 14), wood)
		draw_rect(Rect2(x, 222, 2, 1), light)
	draw_rect(Rect2(left, 225, right - left, 1), light)
	draw_rect(Rect2(left, 230, right - left, 1), wood)
	if not _stand:
		return
	for h in _hens:
		var tex: Texture2D = _peck if h["pecking"] else _stand
		draw_set_transform(Vector2(roundf(float(h["x"])), float(h["y"])), 0.0, Vector2(float(h["dir"]), 1.0))
		draw_texture(tex, Vector2(-12, -21))
		draw_set_transform(Vector2.ZERO)
