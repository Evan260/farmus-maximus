extends Node
## The farmhouse as it is rebuilt: its picture for each stage, the scaffold and ladders while builders work, the
## windows that light up at night, and the golden wreath over the door after a Triumph.

## The estate scene this works for.
var m: Estate
## The villa stage the farmhouse is drawn at, so a stage reached without its signal can still be shown being finished.
var shown_stage := 0
## The golden laurel wreath over the villa door, hung for the Triumph.
var _wreath: Sprite2D
## One light per villa window, each with its own evening: when it is lit, when it goes out, and its flicker.
var _windows: Array = []
var _windows_night := -1


func villa_texture() -> Texture2D:
	var stages := Game.villa_stages()
	var stage: Dictionary = stages[clampi(Game.villa_stage - 1, 0, stages.size() - 1)]
	var path := "res://assets/sprites/villa/%s.png" % stage.get("sprite", "stage1")
	return load(path) if ResourceLoader.exists(path) else load("res://assets/sprites/villa/stage2.png")


func villa_rect() -> Rect2:
	return Rect2(m._villa.position, m._villa.region_rect.size)


## The farmhouse's hover outline, and while it is being restored a progress bar over its roof like the other buildings'.
func draw_villa_overlay() -> void:
	var r := villa_rect()
	if m._villa_hovered:
		UiKit.outline(m._villa_outline, r, Color(1, 0.96, 0.85, 0.7))
	if not Game.villa_build["active"]:
		return
	var total := float(Game.villa_stages()[mini(Game.villa_stage, Game.villa_stages().size() - 1)].get("build_seconds", 1))
	var fill := clampf(1.0 - float(Game.villa_build["time_left"]) / maxf(total, 1.0), 0.0, 1.0)
	var bar := Rect2(roundf(r.position.x + r.size.x / 2.0 - 16.0), r.position.y - 6, 32, 3)
	m._villa_outline.draw_rect(bar, Color(0.2, 0.14, 0.12, 0.8))
	m._villa_outline.draw_rect(Rect2(bar.position + Vector2.ONE, Vector2(roundf(30.0 * fill), 1)), Color(0.98, 0.84, 0.4))


## Where the farmhouse's ladders stand, in pixels from its left edge; they are set as shares of its width, since each
## stage of the farmhouse is drawn a different size.
func villa_ladders() -> Array:
	var width := villa_rect().size.x
	return Balance.get_value("villa.ladders", []).map(func(share): return roundf(width * float(share)))


func place_villa() -> void:
	shown_stage = Game.villa_stage
	var tex := villa_texture()
	m._villa.texture = tex
	var used := tex.get_image().get_used_rect()
	m._villa.region_rect = used
	m._villa.position = Vector2(round(Estate.VILLA_BASE.x - used.size.x / 2.0), Estate.VILLA_BASE.y - used.size.y + 1)
	m._villa_shadow.texture = Lighting.ellipse_texture(used.size.x + 12, 7, Estate.SHADOW)
	m._villa_shadow.position = Vector2(m._villa.position.x - 6, Estate.VILLA_BASE.y - 5)
	make_windows(tex, used)
	hang_wreath(tex, used)
	if m._villa_scaffold:
		m._villa_scaffold.rect = villa_rect()
		m._villa_scaffold.ladders = villa_ladders()
		m._villa_scaffold.visible = Game.villa_build["active"] or m._villa_scaffold.share > 0.0 and m._villa_scaffold.visible
		m._villa_scaffold.queue_redraw()
	# Storks only nest on a well-kept roof, so they arrive with the peristyle garden.
	m._stork.visible = m._stork.texture != null and Game.villa_stage >= 5 and not Game.villa_build["active"]
	if m._stork.texture:
		m._stork.position = Vector2(m._villa.position.x + used.size.x * 0.68, m._villa.position.y - m._stork.texture.get_height() + 12)


## Once the Triumph is earned, a golden laurel wreath hangs over the villa's front door, found as the top of the
## door's dark wood in the middle of the house.
func hang_wreath(tex: Texture2D, used: Rect2i) -> void:
	if _wreath == null:
		_wreath = m._add_texture(load("res://assets/sprites/decorations/laurel_wreath.png"), Vector2.ZERO)
		m.world.move_child(_wreath, m._villa.get_index() + 1)
		Game.achievement_unlocked.connect(func(a): if a["id"] == "triumph": place_villa())
	_wreath.visible = Game.journal.achievements.has("triumph") and Game.villa_stage > 1
	if not _wreath.visible:
		return
	var img := tex.get_image()
	var mid := used.position.x + used.size.x / 2
	var door := func(y: int) -> bool:
		var c := img.get_pixel(mid, y)
		return c.a > 0.5 and c.v < 0.42 and c.s > 0.3
	var top := used.end.y - 1
	while top > used.position.y and not door.call(top):
		top -= 1
	while top > used.position.y and door.call(top - 1):
		top -= 1
	var size := _wreath.texture.get_size()
	_wreath.position = m._villa.position + Vector2(mid - used.position.x, top - used.position.y) - Vector2(roundf(size.x / 2.0), size.y + 1)


## Finds the villa's windows (its glass-blue pixels, grouped into panes, and panes close together into one window) and
## gives each window a lamp inside that lights all its panes and spills out onto the wall and the ground.
func make_windows(tex: Texture2D, used: Rect2i) -> void:
	for w in _windows:
		for pane in w["panes"]:
			pane.queue_free()
		w["lamp"].queue_free()
	_windows = []
	_windows_night = -1
	# The ruin has no glass, only dark holes, so it stays dark.
	if Game.villa_stage <= 1:
		return
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var glass := {}
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.b > c.r + 0.08 and c.b > c.g + 0.02:
				glass[Vector2i(x, y)] = true
	# Each pane of glass, however small, as a list of its pixels and its bounding box.
	var panes: Array = []
	var boxes: Array[Rect2i] = []
	while not glass.is_empty():
		var pane: Array = [glass.keys()[0]]
		glass.erase(pane[0])
		var k := 0
		while k < pane.size():
			var p: Vector2i = pane[k]
			k += 1
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				if glass.has(p + d):
					glass.erase(p + d)
					pane.append(p + d)
		var box := Rect2i(pane[0], Vector2i.ONE)
		for p in pane:
			box = box.expand(p).expand(p + Vector2i.ONE)
		panes.append(pane)
		boxes.append(box)
	# Panes a few pixels apart, split only by glazing bars or a frame, belong to the same window.
	var group := range(boxes.size())
	var changed := true
	while changed:
		changed = false
		for i in boxes.size():
			for j in boxes.size():
				if group[i] != group[j] and boxes[i].grow(4).intersects(boxes[j]):
					var keep := mini(group[i], group[j])
					var drop := maxi(group[i], group[j])
					for k in group.size():
						if group[k] == drop:
							group[k] = keep
					changed = true
	for g in range(boxes.size()):
		var members := range(boxes.size()).filter(func(k): return group[k] == g)
		var pixels := {}
		for k in members:
			for p in panes[k]:
				pixels[p] = true
		# A speck of blue on its own is a fleck in the stone, not a window.
		if pixels.size() < 6:
			continue
		var outline := boxes[members[0]]
		for k in members:
			outline = outline.merge(boxes[k])
		# Inside a window's outline, the darkest glass in the arches can be too dark to read as blue, so any dark,
		# bluish pixel there counts as glass too, and the whole window lights as one.
		for x in range(outline.position.x, outline.end.x):
			for y in range(outline.position.y, outline.end.y):
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.b >= c.r and (c.r + c.g + c.b) / 3.0 < 0.4:
					pixels[Vector2i(x, y)] = true
		var light := Image.create(outline.size.x, outline.size.y, false, Image.FORMAT_RGBA8)
		for p in pixels:
			light.set_pixelv(p - outline.position, Color(1.0, 0.8, 0.42, 0.95))
		var sprite := m._add_texture(ImageTexture.create_from_image(light), m._villa.position + Vector2(outline.position - used.position), m._glow_layer)
		sprite.modulate.a = 0.0
		var lamp := Lamp.new()
		lamp.position = m._villa.position + Vector2(outline.position - used.position) + Vector2(outline.size) / 2.0 + Vector2(0, 3)
		lamp.radius = clampf(outline.size.x * 2.2, 18.0, 34.0)
		lamp.power = 0.9
		m.world.add_child(lamp)
		_windows.append({"panes": [sprite], "lamp": lamp, "phase": randf() * TAU, "speed": randf_range(0.8, 1.3)})


## Each evening some windows are lit, one after another as dusk falls, and go out at different hours; a few light again before dawn.
## A lit window flickers gently, like a candle or an oil lamp.
func light_windows(night: float) -> void:
	if _windows.is_empty():
		return
	if _windows_night != Game.calendar.day:
		_windows_night = Game.calendar.day
		var rng := RandomNumberGenerator.new()
		rng.seed = Game.calendar.day * 7919 + _windows.size()
		for w in _windows:
			w["lit"] = rng.randf() < 0.75
			w["on"] = rng.randf_range(18.6, 20.2)
			w["off"] = rng.randf_range(21.5, 25.5)
			w["dawn"] = rng.randf() < 0.3
	var hour := Game.day_time
	var t := Time.get_ticks_msec() / 1000.0
	for w in _windows:
		var since := fposmod(hour - 12.0, 24.0)
		var evening := smoothstep(float(w["on"]) - 12.0, float(w["on"]) - 11.7, since) * (1.0 - smoothstep(float(w["off"]) - 12.0, float(w["off"]) - 11.8, since))
		var morning := (smoothstep(5.0, 5.3, hour) * (1.0 - smoothstep(6.8, 7.2, hour))) if w["dawn"] else 0.0
		var on := maxf(evening if w["lit"] else 0.0, morning)
		var flicker := 1.0 if Settings.reduced_motion else 0.84 + 0.09 * sin(t * 5.1 * float(w["speed"]) + float(w["phase"])) + 0.07 * sin(t * 11.7 * float(w["speed"]) + float(w["phase"]) * 1.7)
		var glow := clampf(on * flicker * maxf(night, 0.35), 0.0, 1.0)
		for pane in w["panes"]:
			pane.modulate.a = glow
		w["lamp"].shine(glow * night)
