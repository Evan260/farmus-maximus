extends Node
## The wild growth around the farm: tufts, weeds and wildflowers across the grass, flowers by the beehives, a fringe
## of grass along the buildings, and the overgrowth that clears as the estate is tended.

## The estate scene this works for.
var m: Estate
## Weeds and bushes grown up around each building still in ruins, by building.
var _overgrowth := {}


## Tufts, weeds and wildflowers across the estate's grass, with a band of long uncut grass along its back edge where
## it meets the walls and buildings; the ground picture says where the grass is, and the planting beds are kept clear.
func scatter_meadow() -> void:
	var ground: Image = (load(Estate.BG + "ground.png") as Texture2D).get_image()
	var grassy := func(x: float, y: float) -> bool:
		var c := ground.get_pixel(clampi(int(x) + 40, 0, ground.get_width() - 1), clampi(int(y), 0, ground.get_height() - 1))
		return c.a > 0.0 and c.g > c.r + 0.06
	var clear_of_beds := func(x: float, y: float) -> bool:
		return not m.plot_views.any(func(p): return absf(x - p.position.x - 15.0) < 20.0 and absf(y - p.position.y) < 12.0)
	var node := Node2D.new()
	m.world.add_child(node)
	m.world.move_child(node, m.plot_views[0].get_index())
	# Grass in the pasture grows behind the fence and the animals rather than over them.
	var pasture_grass := Node2D.new()
	m.world.add_child(pasture_grass)
	m.world.move_child(pasture_grass, m._pasture.get_index())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var plants := []
	var x := 0.0
	while x < m.estate_width:
		# The castellum stands at the head of the water channel, and no grass grows across its front.
		if grassy.call(x, 240.0) and clear_of_beds.call(x, 238.0) and absf(x - Estate.CASTELLUM_X) > 26.0:
			var tall: Array[Texture2D] = GroundPlants.tall_textures()
			plants.append([tall[rng.randi() % tall.size()], Vector2(x, 238 + rng.randi_range(0, 2))])
		x += rng.randf_range(3.0, 9.0)
	for i in int(m.estate_width / 9.0):
		var at := Vector2(rng.randf_range(0.0, m.estate_width), rng.randf_range(244.0, 267.0))
		if grassy.call(at.x, at.y) and clear_of_beds.call(at.x, at.y) and absf(at.x - Estate.CASTELLUM_X) > 30.0:
			var tufts: Array[Texture2D] = GroundPlants.textures()
			plants.append([tufts[rng.randi() % tufts.size()], at])
	plants.sort_custom(func(a, b): return a[1].y < b[1].y)
	for entry in plants:
		var plant := Sprite2D.new()
		plant.texture = entry[0]
		plant.centered = false
		plant.flip_h = rng.randf() < 0.5
		plant.position = (entry[1] - Vector2(roundf(entry[0].get_width() / 2.0), entry[0].get_height())).round()
		var in_pasture: bool = entry[1].x > Estate.Pasture.FENCE_LEFT - 16.0 and entry[1].x < Estate.Pasture.FENCE_RIGHT + 10.0
		(pasture_grass if in_pasture else node).add_child(plant)
		m._sway(plant)


## Wild flowers at the foot of the beehives, where the bees have the least way to go.
func flowers_by_hives() -> void:
	var hives: Rect2 = m.building_views.filter(func(v): return v.id == "beehives")[0].world_rect()
	var node := Node2D.new()
	m.world.add_child(node)
	m.world.move_child(node, m.plot_views[0].get_index())
	var flowers := GroundPlants.flower_textures()
	for k in 5:
		var tex: Texture2D = flowers[(k * 2 + 1) % flowers.size()]
		var at := Vector2(hives.position.x - 6 + k * (hives.size.x + 12) / 4.0, hives.end.y + 2 + (k % 2) * 2).round()
		var plant := m._add_texture(tex, at - Vector2(roundf(tex.get_width() / 2.0), tex.get_height()), node)
		m._sway(plant)


## A fringe of grass and a few strands of vine along a building's foot, so it sits in the ground rather than on it.
func root_in_ground(rect: Rect2, seed: int, after: Node) -> void:
	var node := Node2D.new()
	m.world.add_child(node)
	m.world.move_child(node, after.get_index() + 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var tufts := GroundPlants.textures()
	var x := rect.position.x + rng.randf_range(0.0, 6.0)
	while x < rect.end.x - 4.0:
		var tex: Texture2D = tufts[rng.randi() % tufts.size()]
		var plant := Sprite2D.new()
		plant.texture = tex
		plant.centered = false
		plant.flip_h = rng.randf() < 0.5
		plant.position = Vector2(roundf(x), rect.end.y + rng.randi_range(0, 2) - tex.get_height())
		node.add_child(plant)
		x += rng.randf_range(6.0, 16.0)
	var vines := []
	for i in rng.randi_range(2, 4):
		vines.append([roundf(rng.randf_range(rect.position.x + 4.0, rect.end.x - 4.0)), rng.randi_range(4, 10), rng.randi_range(0, 1000)])
	node.draw.connect(func() -> void:
		for v in vines:
			for k in int(v[1]):
				var vx: float = v[0] + (1.0 if (int(v[2]) + k) % 5 == 0 else 0.0)
				node.draw_rect(Rect2(vx, rect.end.y - 1 - k, 1, 1), Color8(70, 98, 46))
				if (k + int(v[2])) % 3 == 0:
					node.draw_rect(Rect2(vx + (1 if k % 2 else -1), rect.end.y - 1 - k, 1, 1), Color8(104, 132, 60)))


## A building nobody has started to repair stands in weeds, long grass and brambles; they are cleared when work begins.
func sync_overgrowth() -> void:
	for v in m.building_views:
		var wild := String(Game.buildings[v.id]["state"]) in ["ruin", "owned"]
		if wild and not _overgrowth.has(v.id):
			_overgrowth[v.id] = grow_wild(v)
		elif not wild and _overgrowth.has(v.id):
			var node: Node2D = _overgrowth[v.id]
			_overgrowth.erase(v.id)
			for part in [node, node.get_meta("ground")]:
				var fade: Tween = part.create_tween()
				fade.tween_property(part, "modulate:a", 0.0, 1.5)
				fade.tween_callback(part.queue_free)


func grow_wild(v: Node2D) -> Node2D:
	var node := Node2D.new()
	m.world.add_child(node)
	m.world.move_child(node, v.get_index() + 1)
	var r: Rect2 = v.world_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(v.id)
	var plants := []
	# A few big weeds and brambles against the walls...
	var kinds := ["grass", "grass", "weeds", "weeds", "bramble", "thistle"]
	var x := r.position.x - 8.0 + rng.randf_range(0.0, 10.0)
	while x < r.end.x:
		var tex: Texture2D = load("res://assets/sprites/wild/%s.png" % kinds[rng.randi() % kinds.size()])
		var used := tex.get_image().get_used_rect()
		plants.append([tex, Vector2(roundf(x - used.position.x), roundf(r.end.y + rng.randi_range(0, 2) - used.end.y)), used.end.y])
		x += used.size.x * rng.randf_range(1.3, 2.2)
	# ...and little tufts scattered over the ground in front, kept off the planting beds. They are drawn with the beds,
	# over the ground strip, rather than with the building behind it.
	var ground := Node2D.new()
	m.world.add_child(ground)
	m.world.move_child(ground, m.plot_views[0].get_index())
	node.set_meta("ground", ground)
	var tufts := GroundPlants.textures()
	for i in int(r.size.x / 6.0):
		var at := Vector2(roundf(rng.randf_range(r.position.x - 30.0, r.end.x + 30.0)), roundf(rng.randf_range(r.end.y + 4.0, 267.0)))
		if m.plot_views.any(func(p): return absf(at.x - p.position.x - 15.0) < 22.0 and absf(at.y - p.position.y) < 12.0):
			continue
		# The castellum at the head of the water channel stands on clear ground.
		if absf(at.x - 470.0) < 30.0:
			continue
		var tex: Texture2D = tufts[rng.randi() % tufts.size()]
		plants.append([tex, at - Vector2(roundf(tex.get_width() / 2.0), tex.get_height()), at.y, ground])
	# Plants lower on the ground stand in front of those behind them.
	plants.sort_custom(func(a, b): return a[1].y + a[0].get_height() < b[1].y + b[0].get_height())
	for entry in plants:
		var plant := Sprite2D.new()
		plant.texture = entry[0]
		plant.centered = false
		plant.flip_h = rng.randf() < 0.5
		plant.position = entry[1]
		(entry[3] if entry.size() > 3 else node).add_child(plant)
		m._sway(plant)
	return node
