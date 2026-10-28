extends Node2D
## The pasture: a wooden fence, and as many hens and goats out on the grass as the barn holds.

const Walker := preload("res://scripts/world/walker.gd")
const ANIMALS := "res://assets/sprites/animals/"

var left := 1925.0
var right := 2395.0
## The fence runs from the vineyard's edge to the estate's end, stopping at the barn's walls.
const FENCE_LEFT := 1905.0
const FENCE_RIGHT := 2398.0
const BARN_LEFT := 2010.0
const BARN_RIGHT := 2115.0
const WOOD := [Color8(92, 62, 40), Color8(124, 88, 56), Color8(156, 116, 74), Color8(128, 118, 104)]
const GRASS := [Color8(70, 96, 44), Color8(98, 124, 56), Color8(140, 158, 76)]
var _hens: Array = []
var _goats: Array = []
var _sync := 0.0
var _last_hour := 0.0
var _fence: Texture2D


func _ready() -> void:
	_last_hour = Game.day_time
	# Animals further back are drawn first, so one nearer the front always stands in front of it.
	y_sort_enabled = true


func _process(delta: float) -> void:
	# The rooster greets the morning, and now and then a goat has something to say, heard only near the pasture.
	var near := _within_earshot()
	if near and not _hens.is_empty() and _last_hour < 6.0 and Game.day_time >= 6.0:
		Sfx.play("rooster", -6.0)
	_last_hour = Game.day_time
	if near and not _goats.is_empty() and randf() < delta / 90.0:
		Sfx.play("goat", -10.0)
	_sync -= delta
	if _sync <= 0.0:
		_sync = 1.0
		_match_barn()



## The fence, painted once: a weathered rail fence along the back of the pasture that stops at the barn's walls so
## its doorway opens onto the field, and a stretch running from the back of the field to the front between the
## pasture and the vineyard, its posts growing as they come nearer. Long uncut grass grows along its foot.
## True while the pasture is on screen or just beyond its edge.
func _within_earshot() -> bool:
	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	return view.position.x < right + 120.0 and view.end.x > left - 120.0


func _paint_fence() -> Texture2D:
	var w := int(FENCE_RIGHT - FENCE_LEFT) + 1
	var img := Image.create(w, 74, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2062
	var put := func(x: int, y: int, c: Color) -> void:
		if x >= 0 and x < w and y >= 0 and y < 74:
			img.set_pixel(x, y, c)
	var top := 22
	# The back fence, in two runs either side of the barn.
	for run in [[FENCE_LEFT, BARN_LEFT], [BARN_RIGHT, FENCE_RIGHT]]:
		var a := int(run[0] - FENCE_LEFT)
		var b := int(run[1] - FENCE_LEFT)
		var posts: Array[int] = [a]
		var x := a
		while x < b - 12:
			x += rng.randi_range(15, 21)
			posts.append(mini(x, b))
		if posts[-1] != b:
			posts.append(b)
		for k in posts.size() - 1:
			for rail in [3, 8]:
				var sag := rng.randi_range(0, 1)
				var tone: Color = WOOD[rng.randi() % WOOD.size()]
				for xx in range(posts[k] + 1, posts[k + 1]):
					var dip := sag if absi(xx - (posts[k] + posts[k + 1]) / 2) < 4 else 0
					put.call(xx, top + rail + dip, tone.lightened(0.12) if (xx * 7 + rail) % 11 == 0 else tone)
					put.call(xx, top + rail + 1 + dip, tone.darkened(0.3))
		for i in posts.size():
			var gate: bool = (i == posts.size() - 1 and int(run[1]) == int(BARN_LEFT)) or (i == 0 and int(run[0]) == int(BARN_RIGHT))
			_post(put, posts[i], top - rng.randi_range(0, 2) - (3 if gate else 0), 14 + (3 if gate else 0) + rng.randi_range(0, 1), 3 if gate else 2, rng)
	# Long grass the scythe never reaches, along the foot of the fence.
	for x in range(0, w):
		if x > int(BARN_LEFT - FENCE_LEFT) and x < int(BARN_RIGHT - FENCE_LEFT):
			continue
		if rng.randf() < 0.55:
			var tall := rng.randi_range(3, 8)
			var lean := rng.randi_range(-1, 1)
			for k in tall:
				var c: Color = GRASS[0] if k < 2 else (GRASS[2] if k == tall - 1 else GRASS[1])
				put.call(x + (lean * k) / 3, top + 14 - k, c)
			if rng.randf() < 0.08:
				put.call(x + lean, top + 14 - tall, Color8(214, 196, 120))
	# The side fence runs towards the viewer, posts larger as they near, so it is painted over the long grass.
	var steps := 4
	var prev := Vector2.ZERO
	for i in steps + 1:
		var t := float(i) / steps
		var foot := Vector2(lerpf(0.0, -14.0, t), lerpf(36.0, 70.0, t)).round()
		var tall := int(lerpf(14.0, 22.0, t))
		_post(put, int(foot.x) + 14, int(foot.y) - tall, tall, 2 if t < 0.5 else 3, rng)
		if i > 0:
			for rail in [0.2, 0.55]:
				var p0 := prev + Vector2(14, -lerpf(14.0, 22.0, float(i - 1) / steps) * (1.0 - rail))
				var p1 := foot + Vector2(14, -tall * (1.0 - rail))
				var n := int(maxf(absf(p1.x - p0.x), absf(p1.y - p0.y)))
				for k in n + 1:
					var q := p0.lerp(p1, float(k) / maxf(1, n)).round()
					put.call(int(q.x), int(q.y), WOOD[1])
					put.call(int(q.x), int(q.y) + 1, WOOD[0].darkened(0.2))
		prev = foot
	return ImageTexture.create_from_image(img)


## A fence post, darker on its right side, with a knot or a patch of moss now and then.
func _post(put: Callable, x: int, y: int, tall: int, wide: int, rng: RandomNumberGenerator) -> void:
	var lean := 1 if rng.randf() < 0.25 else 0
	for k in tall:
		var dx := lean if k < tall / 3 else 0
		for c in wide:
			var tone: Color = WOOD[2] if c == 0 else (WOOD[0] if c == wide - 1 else WOOD[1])
			put.call(x + c + dx, y + k, tone)
	put.call(x + lean, y, WOOD[2].lightened(0.15))
	if rng.randf() < 0.4:
		put.call(x + 1, y + rng.randi_range(3, tall - 3), WOOD[0].darkened(0.3))
	if rng.randf() < 0.3:
		put.call(x, y + tall - 2, GRASS[1])
		put.call(x, y + tall - 3, GRASS[2])


func _match_barn() -> void:
	var animals: Dictionary = Game.buildings.get("barn", {}).get("animals", {})
	var hens := mini(int(animals.get("chicken", 0)), 10)
	while _hens.size() < hens and ResourceLoader.exists(ANIMALS + "hen/east.png"):
		_hens.append(_animal("hen", 8.0, Vector2(randf_range(248, 268), 0)))
	while _hens.size() > hens:
		_hens.pop_back().queue_free()
	var goats := mini(int(animals.get("goat", 0)), 5)
	while _goats.size() < goats and ResourceLoader.exists(ANIMALS + "goat/east.png"):
		_goats.append(_animal("goat", 9.0, Vector2(randf_range(250, 262), 0)))
	while _goats.size() > goats:
		_goats.pop_back().queue_free()


## A hen or goat in one of its coats, wandering the pasture and grazing, and going into the barn for the night.
func _animal(kind: String, pace: float, row: Vector2) -> Node2D:
	var coats: Array = Coats.HEN if kind == "hen" else Coats.GOAT
	var coat: String = coats[randi() % coats.size()]
	var a := Walker.new()
	a.dir = ANIMALS + kind + "/"
	a.dress = func(tex: Texture2D) -> Texture2D: return Coats.recolour(tex, kind, coat)
	a.min_x = left + 20
	a.max_x = right - 20
	a.speed = pace
	a.idle_anim = "graze"
	a.react_folder = "flap" if kind == "hen" else "bleat"
	a.rests_at_night = true
	a.home_x = (BARN_LEFT + BARN_RIGHT) / 2.0
	a.position = Vector2(randf_range(left + 30, right - 30), row.x)
	a.set_meta("kind", kind)
	add_child(a)
	return a


## The hen or goat under the pointer, if any, for a click to make it call out; of two overlapping, the one in front.
func animal_at(point: Vector2) -> Node2D:
	return Hit.front_most((_hens + _goats).filter(func(a): return a.contains(point)), point)


func _draw() -> void:
	if _fence == null:
		_fence = _paint_fence()
	draw_texture(_fence, Vector2(FENCE_LEFT, 200))
