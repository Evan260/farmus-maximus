extends "res://scripts/ui/window_panel.gd"
## The farmer's journal, drawn as an open book. Bookmarks choose a section; every entry stays in the left-page list,
## while the right page tells the selected entry's story. Undiscovered entries remain as dark silhouettes.

const SECTIONS := ["Crops", "Goods", "Buildings", "Helpers", "Animals", "Finds", "Sightings", "Festivals", "Milestones", "Achievements"]
const PAGE_W := 166
const PAGE_H := 196
const TILE := 34
## How many page edges show under each page, and the inner margin of the writing.
const STACK := 3
const SPINE := 4
const MARGIN := 9
const TEXT_W := 136
const SILHOUETTE := Color(0.22, 0.16, 0.13)
const LEATHER := Color(0.33, 0.2, 0.13)
const PAPER := Color(0.95, 0.89, 0.74)
const TAB := Color(0.83, 0.71, 0.52)
const EDGE := Color(0.55, 0.4, 0.28)
const FLIP_TIME := 0.78
const FLIP_SLICES := 48
const FLIP_ROWS := 24
## Match the game's 3x window scale so printed sprites retain their pixel coverage while the leaf is warped.
const CAPTURE_SCALE := 3

var section := "Crops"
var selected := ""
var _pictures := {}
var _book: Control
var _page_views: Array[Control] = []
var _flipping := false
static var _paper_cache := {}


func _init() -> void:
	super("Farmer's journal")
	var cover := StyleBoxFlat.new()
	cover.bg_color = LEATHER
	cover.border_color = Color(0.22, 0.13, 0.09)
	cover.set_border_width_all(2)
	cover.set_content_margin_all(7)
	add_theme_stylebox_override("panel", cover)
	_title.add_theme_color_override("font_color", UiKit.CREAM)


func signature() -> String:
	return "%s|%s|%d|%d" % [section, selected, Game.journal.entries.size(), Game.journal.achievements.size()]


func build() -> void:
	set_title(tr("Farmer's journal"))
	var spread := UiKit.row(body)
	spread.add_theme_constant_override("separation", 0)
	var marks := UiKit.column(spread)
	marks.add_theme_constant_override("separation", 1)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 5)
	marks.add_child(gap)
	for s in SECTIONS:
		_bookmark(marks, s)
	var space := Control.new()
	space.custom_minimum_size = Vector2(5, 0)
	spread.add_child(space)
	var book := Control.new()
	book.custom_minimum_size = Vector2(STACK * 2 + PAGE_W * 2 + SPINE, PAGE_H + STACK)
	book.draw.connect(func(): _draw_book(book))
	spread.add_child(book)
	_book = book
	var left := _page(book, STACK, true)
	var left_view := left.get_parent() as ScrollContainer
	var right_x := STACK + PAGE_W + SPINE
	var right_view := ScrollContainer.new()
	right_view.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_view.position = Vector2(right_x + MARGIN, MARGIN)
	right_view.size = Vector2(PAGE_W - MARGIN - 4, PAGE_H - MARGIN * 2)
	book.add_child(right_view)
	UiKit.touch_scroll(right_view)
	var right := UiKit.column(right_view)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_views = [left_view, right_view]
	var entries := _entries()
	var found := entries.filter(func(e): return _found(e["id"])).size()
	if not entries.any(func(e): return String(e["id"]) == selected):
		selected = ""
	_grid(left, entries, "%s   %d / %d" % [tr(section), found, entries.size()])
	if selected != "":
		_detail(right, selected)
	else:
		_section_story(right, entries)


## A divider tab beside the book; the open section's tab is paper coloured.
func _bookmark(parent: Node, s: String) -> void:
	var open := s == section
	var b := Button.new()
	b.text = tr(s)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(66, 0)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = PAPER if open else (TAB.lightened(0.1) if state.begins_with("hover") else TAB)
		box.border_color = EDGE
		box.set_border_width_all(1)
		box.content_margin_left = 5
		box.content_margin_right = 3
		box.content_margin_top = 2
		box.content_margin_bottom = 2
		if state == "focus" and not open:
			box.draw_center = false
			box.border_color = UiKit.CREAM
		b.add_theme_stylebox_override(state, box)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, UiKit.INK if open else UiKit.INK.lightened(0.15))
	b.pressed.connect(func(): _turn_to(s))
	parent.add_child(b)


## Change journal sections with the same paper-leaf turn used by the logbook.
func _turn_to(to: String) -> void:
	var target := SECTIONS.find(to)
	if _flipping or target < 0 or to == section or not is_instance_valid(_book):
		return
	_flipping = true
	var old_book := _book
	var direction := 1 if target > SECTIONS.find(section) else -1
	var turning_side := 1 if direction > 0 else 0
	var front := await _capture_page_offscreen(old_book, turning_side)
	if not is_instance_valid(old_book) or _book != old_book:
		_flipping = false
		return
	var fixed_side := 0 if direction > 0 else 1
	var fixed := await _capture_page_offscreen(old_book, fixed_side)
	if not is_instance_valid(old_book) or _book != old_book:
		_flipping = false
		return
	Sfx.play("page_turn")
	section = to
	selected = ""
	show_page()
	if not is_instance_valid(_book):
		_flipping = false
		return
	var reverse_side := 0 if direction > 0 else 1
	var overlay := _flip_overlay(_book, direction, front, fixed, front)
	var back := await _capture_page_offscreen(_book, reverse_side)
	if is_instance_valid(overlay):
		overlay.set_meta("back", back)
		overlay.queue_redraw()


## Capture paper and its laid-out controls together so the turning leaf keeps its print at every angle.
func _capture_page_offscreen(book: Control, side: int) -> Texture2D:
	if not is_instance_valid(book) or not book.is_inside_tree() or side >= _page_views.size():
		return _paper(side == 0)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(PAGE_W, PAGE_H) * CAPTURE_SCALE
	viewport.transparent_bg = false
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var root := Control.new()
	root.size = Vector2(PAGE_W, PAGE_H)
	root.scale = Vector2(CAPTURE_SCALE, CAPTURE_SCALE)
	# The SubViewport does not inherit the HUD's theme, so give the duplicated controls the game's exact pixel fonts and ink.
	root.theme = UiKit.make_theme()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(root)
	var paper := TextureRect.new()
	paper.texture = _paper(side == 0)
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.size = Vector2(PAGE_W, PAGE_H)
	root.add_child(paper)
	var page := _page_views[side].duplicate() as Control
	page.position = Vector2(MARGIN, MARGIN)
	page.size = Vector2(PAGE_W - MARGIN - 4, PAGE_H - MARGIN * 2)
	root.add_child(page)
	await RenderingServer.frame_post_draw
	if not is_instance_valid(viewport):
		return _paper(side == 0)
	var texture := ImageTexture.create_from_image(viewport.get_texture().get_image())
	viewport.queue_free()
	return texture


## Put a textured leaf above the new spread and curl it around the centre seam.
func _flip_overlay(book: Control, direction: int, front: Texture2D, fixed: Texture2D, back: Texture2D) -> Control:
	var overlay := Control.new()
	overlay.name = "JournalPageTurn"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.z_index = 20
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.set_meta("direction", direction)
	overlay.set_meta("progress", 0.0)
	overlay.set_meta("front", front)
	overlay.set_meta("fixed", fixed)
	overlay.set_meta("back", back)
	overlay.draw.connect(func(): _draw_flip(overlay))
	overlay.tree_exiting.connect(func(): _flipping = false)
	book.add_child(overlay)
	var tween := overlay.create_tween()
	tween.tween_method(func(value: float):
		overlay.set_meta("progress", value)
		overlay.queue_redraw(), 0.0, 1.0, FLIP_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_finish_flip.bind(overlay))
	return overlay


## Hold the exact flat landing for a drawn frame before removing the leaf.
func _finish_flip(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		return
	overlay.set_meta("progress", 1.0)
	overlay.queue_redraw()
	await RenderingServer.frame_post_draw
	if is_instance_valid(overlay):
		_flipping = false
		overlay.queue_free()


## Draw the page as a finely divided mesh, keeping the paper opaque through its landing.
func _draw_flip(canvas: Control) -> void:
	var progress: float = float(canvas.get_meta("progress"))
	var direction: int = int(canvas.get_meta("direction"))
	var reverse := progress >= 0.5
	var texture: Texture2D = canvas.get_meta("back" if reverse else "front")
	var angle := PI * progress if direction > 0 else PI * (1.0 + progress)
	var hinge := STACK + PAGE_W + SPINE if direction > 0 else STACK + PAGE_W
	hinge -= direction * SPINE * smoothstep(0.0, 1.0, progress)
	var curl := sin(PI * progress)
	var flip_uv := (direction < 0) != reverse
	var fixed_x := STACK if direction > 0 else STACK + PAGE_W + SPINE
	var fixed_alpha := 0.0 if progress >= 1.0 else 1.0
	canvas.draw_texture_rect(canvas.get_meta("fixed"), Rect2(fixed_x, 0, PAGE_W, PAGE_H), false,
		Color(1, 1, 1, fixed_alpha))
	if progress >= 1.0:
		var landing_x := STACK if direction > 0 else STACK + PAGE_W + SPINE
		canvas.draw_texture_rect(texture, Rect2(landing_x, 0, PAGE_W, PAGE_H), false)
		_draw_spine(canvas)
		return
	var points_by_cell: Array[PackedVector2Array] = []
	var uvs_by_cell: Array[PackedVector2Array] = []
	var colors_by_cell: Array[PackedColorArray] = []
	for i in FLIP_SLICES:
		var u0 := float(i) / FLIP_SLICES
		var u1 := float(i + 1) / FLIP_SLICES
		var sx0 := 1.0 - u0 if flip_uv else u0
		var sx1 := 1.0 - u1 if flip_uv else u1
		for j in FLIP_ROWS:
			var v0 := float(j) / FLIP_ROWS
			var v1 := float(j + 1) / FLIP_ROWS
			var y0 := v0 * PAGE_H
			var y1 := v1 * PAGE_H
			var p00 := _flip_point(u0, y0, progress, direction, angle, hinge)
			var p10 := _flip_point(u1, y0, progress, direction, angle, hinge)
			var p11 := _flip_point(u1, y1, progress, direction, angle, hinge)
			var p01 := _flip_point(u0, y1, progress, direction, angle, hinge)
			var points := PackedVector2Array([p00, p10, p11, p01])
			var shadow_shift := Vector2(direction * 4.0 * curl, 2.0 * curl)
			var shadow_color := Color(SILHOUETTE, 0.16 * curl)
			var shadow_points := PackedVector2Array([
				p00 + shadow_shift, p10 + shadow_shift, p11 + shadow_shift, p01 + shadow_shift])
			var shadow_colors := PackedColorArray([shadow_color, shadow_color, shadow_color, shadow_color])
			_draw_flip_triangle(canvas, shadow_points[0], shadow_points[1], shadow_points[2], shadow_colors[0], shadow_colors[1], shadow_colors[2])
			_draw_flip_triangle(canvas, shadow_points[0], shadow_points[2], shadow_points[3], shadow_colors[0], shadow_colors[2], shadow_colors[3])
			var uvs := PackedVector2Array([Vector2(sx0, v0), Vector2(sx1, v0), Vector2(sx1, v1), Vector2(sx0, v1)])
			var bend_light := sin(PI * (u0 + u1) * 0.5) * curl
			var light := clampf(0.92 - bend_light * 0.28 + 0.07 * absf(cos(angle)), 0.55, 1.0)
			var color := Color(light, light, light, 1.0)
			points_by_cell.append(points)
			uvs_by_cell.append(uvs)
			colors_by_cell.append(PackedColorArray([color, color, color, color]))
	for i in points_by_cell.size():
		_draw_flip_triangle(canvas, points_by_cell[i][0], points_by_cell[i][1], points_by_cell[i][2],
			colors_by_cell[i][0], colors_by_cell[i][1], colors_by_cell[i][2],
			uvs_by_cell[i][0], uvs_by_cell[i][1], uvs_by_cell[i][2], texture)
		_draw_flip_triangle(canvas, points_by_cell[i][0], points_by_cell[i][2], points_by_cell[i][3],
			colors_by_cell[i][0], colors_by_cell[i][2], colors_by_cell[i][3],
			uvs_by_cell[i][0], uvs_by_cell[i][2], uvs_by_cell[i][3], texture)
	_draw_spine(canvas)


## Split warped cells explicitly; the automatic polygon triangulator rejects some folded quads.
func _draw_flip_triangle(canvas: Control, a: Vector2, b: Vector2, c: Vector2,
		color_a: Color, color_b: Color, color_c: Color,
		uv_a := Vector2.ZERO, uv_b := Vector2.ZERO, uv_c := Vector2.ZERO, texture: Texture2D = null) -> void:
	if absf((b - a).cross(c - a)) < 0.001:
		return
	canvas.draw_polygon(PackedVector2Array([a, b, c]), PackedColorArray([color_a, color_b, color_c]),
		PackedVector2Array([uv_a, uv_b, uv_c]), texture)


## Bow the leaf, tighten its free edge into a curl, and align its final rightward landing with the flat page.
func _flip_point(u: float, y: float, progress: float, direction: int, angle: float, hinge: float) -> Vector2:
	var bend := sin(PI * u) * sin(PI * progress)
	var roll := pow(u, 3.0) * sin(PI * progress)
	var landing_shift := smoothstep(0.9, 1.0, progress) if direction < 0 else 0.0
	var x := hinge + u * PAGE_W * cos(angle) - direction * bend * 11.0 - direction * roll * sin(PI * y / PAGE_H) * 48.0 + landing_shift
	var edge_y := (y - PAGE_H * 0.5) / (PAGE_H * 0.5)
	return Vector2(x, y + bend * edge_y * 4.0 + roll * edge_y * 20.0)


## The left page holds the story of the chosen entry and scrolls when the story runs long, so the book never grows.
func _page(book: Control, x: int, _left: bool) -> VBoxContainer:
	var area := ScrollContainer.new()
	area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.position = Vector2(x + MARGIN, MARGIN)
	area.size = Vector2(PAGE_W - MARGIN - 4, PAGE_H - MARGIN * 2)
	book.add_child(area)
	UiKit.touch_scroll(area)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(col)
	return col


## Two pages of old paper with the edges of the pages under them showing at the sides and bottom, and a shadow
## running into the fold between them.
func _draw_book(book: Control) -> void:
	var right_x := STACK + PAGE_W + SPINE
	for k in range(STACK, 0, -1):
		var shade := PAPER.darkened(0.12 + 0.1 * (k % 2))
		book.draw_rect(Rect2(STACK - k, k, PAGE_W, PAGE_H), shade)
		book.draw_rect(Rect2(right_x + k, k, PAGE_W, PAGE_H), shade)
	book.draw_rect(Rect2(0, STACK, 1, PAGE_H), EDGE)
	book.draw_rect(Rect2(right_x + PAGE_W + STACK - 1, STACK, 1, PAGE_H), EDGE)
	book.draw_texture(_paper(true), Vector2(STACK, 0))
	book.draw_texture(_paper(false), Vector2(right_x, 0))
	book.draw_rect(Rect2(STACK, 0, PAGE_W, 1), PAPER)
	book.draw_rect(Rect2(right_x, 0, PAGE_W, 1), PAPER)
	_draw_spine(book)


## Keep the textured gutter visible over the turning leaf and stop it at the worn page block.
func _draw_spine(canvas: Control) -> void:
	var x := STACK + PAGE_W
	canvas.draw_rect(Rect2(x, 0, 1, PAGE_H), Color(0.59, 0.44, 0.3))
	canvas.draw_rect(Rect2(x + 1, 0, 1, PAGE_H), Color(0.43, 0.31, 0.22))
	canvas.draw_rect(Rect2(x + 2, 0, 1, PAGE_H), Color(0.29, 0.21, 0.17))
	canvas.draw_rect(Rect2(x + 3, 0, 1, PAGE_H), Color(0.52, 0.39, 0.28))


## A page of paper: a fine grain, a few fibres and age spots, edges a little browned, and a shadow towards the fold.
func _paper(gutter_right: bool) -> Texture2D:
	if _paper_cache.has(gutter_right):
		return _paper_cache[gutter_right]
	var img := Image.create(PAGE_W, PAGE_H, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 if gutter_right else 23
	for y in PAGE_H:
		for x in PAGE_W:
			var c := PAPER
			if rng.randf() < 0.14:
				c = c.darkened(0.035)
			var inner := PAGE_W - 1 - x if gutter_right else x
			var edge := mini(PAGE_W - 1 - inner, PAGE_H - 1 - y)
			if edge < 4:
				c = c.darkened(0.07 * (1.0 - edge / 4.0))
			if inner < 16:
				c = c.darkened(0.2 * pow(1.0 - inner / 16.0, 2.0))
			img.set_pixel(x, y, c)
	for i in 70:
		var x := rng.randi_range(3, PAGE_W - 8)
		var y := rng.randi_range(3, PAGE_H - 4)
		for k in rng.randi_range(2, 5):
			img.set_pixel(x + k, y, img.get_pixel(x + k, y).darkened(0.05))
	for i in 9:
		var at := Vector2i(rng.randi_range(6, PAGE_W - 8), rng.randi_range(6, PAGE_H - 8))
		var spot := Color(0.72, 0.52, 0.32)
		img.set_pixelv(at, img.get_pixelv(at).lerp(spot, 0.22))
		img.set_pixelv(at + Vector2i(1, 0), img.get_pixelv(at + Vector2i(1, 0)).lerp(spot, 0.12))
	var tex := ImageTexture.create_from_image(img)
	_paper_cache[gutter_right] = tex
	return tex


func _heading(page: Node, text: String) -> void:
	UiKit.section(page, text)


func _entries() -> Array:
	if section == "Achievements":
		return Balance.get_value("achievements", []).map(func(a): return {"id": "achievement:" + String(a["id"]), "name": a["name"]})
	# Fine and excellent goods are shown as badges on each good's page rather than as pages of their own.
	return Game.journal.catalogue().filter(func(e): return e["section"] == section and not String(e["id"]).begins_with("quality:"))


func _found(id: String) -> bool:
	if id.begins_with("achievement:"):
		return Game.journal.achievements.has(id.get_slice(":", 1))
	return Game.journal.has(id)


func _grid(page: VBoxContainer, list: Array, heading: String) -> void:
	_heading(page, heading)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	page.add_child(grid)
	for e in list:
		var id := String(e["id"])
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(TILE, TILE)
		tile.focus_mode = Control.FOCUS_NONE
		tile.icon = _picture(id)
		tile.expand_icon = true
		tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.87, 0.79, 0.62) if id != selected else Color(0.98, 0.93, 0.8)
		box.border_color = Color(0.62, 0.46, 0.32) if id != selected else Color(0.7, 0.38, 0.25)
		box.set_border_width_all(1)
		box.set_content_margin_all(1)
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			tile.add_theme_stylebox_override(state, box)
		if not _found(id):
			for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
				tile.add_theme_color_override(state, SILHOUETTE)
		# Big pictures are shrunk smoothly; icons already drawn at this size stay crisp.
		if tile.icon and maxf(tile.icon.get_width(), tile.icon.get_height()) > TILE:
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tile.pressed.connect(func(): Sfx.play("click", -8.0); selected = "" if selected == id else id; refresh())
		grid.add_child(tile)


## Give the right page a section-specific piece of journal writing before an entry is selected.
func _section_story(page: VBoxContainer, entries: Array) -> void:
	var discovered: Array = entries.filter(func(e): return _found(e["id"]))
	if discovered.is_empty():
		_heading(page, tr(section))
		UiKit.para(page, tr("Not discovered yet."), TEXT_W).add_theme_color_override("font_color", UiKit.FADED)
		return
	var id := String(discovered[0]["id"])
	_heading(page, tr(_name(id)))
	var story := _describe(id)
	if story.is_empty():
		story = tr("A record from the %s pages of the journal.") % tr(section.to_lower())
	UiKit.para(page, story, TEXT_W)


func _detail(page: VBoxContainer, id: String) -> void:
	var got := _found(id)
	var frame := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.87, 0.79, 0.62)
	box.border_color = EDGE
	box.set_border_width_all(1)
	box.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", box)
	page.add_child(frame)
	var pic := TextureRect.new()
	pic.texture = _picture(id)
	pic.custom_minimum_size = Vector2(TEXT_W - 10, 72)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if pic.texture and maxf(pic.texture.get_width(), pic.texture.get_height()) > 72:
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if not got:
		pic.modulate = SILHOUETTE
	frame.add_child(pic)
	# An achievement still to earn shows its name and what it asks for, so the player knows what to aim at.
	if not got and id.begins_with("achievement:"):
		_heading(page, tr(_name(id)))
		UiKit.para(page, _describe(id), TEXT_W)
		_achievement_progress(page, id.get_slice(":", 1))
		return
	if not got:
		_heading(page, "? ? ?")
		UiKit.para(page, tr("Not discovered yet."), TEXT_W).add_theme_color_override("font_color", UiKit.FADED)
		return
	_heading(page, tr(_name(id)))
	UiKit.para(page, _describe(id), TEXT_W)
	if id.begins_with("item:") and not Balance.get_value("items.%s.no_quality" % id.get_slice(":", 1), false):
		var badges := UiKit.row(page)
		var names: Array = Balance.get_value("quality.names", ["Common", "Fine", "Excellent"])
		for q in 3:
			var has: bool = q == 0 or Game.journal.has("quality:%s:%d" % [id.get_slice(":", 1), q])
			var l := UiKit.label(badges, tr(String(names[q])))
			l.add_theme_color_override("font_color", UiKit.INK if has else Color(0.62, 0.55, 0.45))


func _achievement_progress(page: VBoxContainer, key: String) -> void:
	for a in Balance.get_value("achievements", []):
		if a["id"] != key:
			continue
		var done: Array = Game.journal.progress(a["when"])
		var text := tr("Not earned yet.")
		if a["when"].has("journal_share"):
			text = tr("Not earned yet: the journal is %d%% full so far.") % done[0]
		elif not done.is_empty():
			text = tr("Not earned yet: %d of %d so far.") % [mini(done[0], done[1]), done[1]]
		UiKit.para(page, text, TEXT_W).add_theme_color_override("font_color", UiKit.FADED)


func _name(id: String) -> String:
	if id.begins_with("helper:"):
		var h := Game.helper_info(id.get_slice(":", 1))
		return tr("%s the %s") % [h.get("name", ""), UiKit.mid(tr(String(h.get("role", ""))))]
	for e in _entries():
		if e["id"] == id:
			return String(e["name"])
	return id


## A few plain sentences about an entry, built from the game's own data so they always match the numbers.
func _describe(id: String) -> String:
	var kind := id.get_slice(":", 0)
	var key := id.get_slice(":", 1)
	var notes: Dictionary = Balance.get_value("journal.notes", {})
	match kind:
		"crop":
			var c := Game.crop_info(key)
			var zone := tr(" and the ").join(Game.crop_zones(key).map(func(z): return UiKit.mid(tr(String(Game.zone_info(z).get("name", ""))))))
			var text := tr("Grows on the %s. Ready after %s") % [zone, UiKit.duration(float(c.get("grow_seconds", 60)))]
			text += (tr(", then again every %s.") % UiKit.duration(float(c["regrow_seconds"]))) if c.get("perennial", false) else tr(", then needs replanting.")
			return text + " " + tr("Each harvest gives %d %s.") % [int(c.get("yield", 1)), UiKit.item_words(String(c.get("item", key)), int(c.get("yield", 1)))]
		"item":
			var lines := [tr("Worth about %d sestertii at market.") % int(Game.base_price(key))]
			for crop in Balance.get_value("crops", {}):
				if Game.crop_info(crop).get("item", "") == key:
					lines.append(tr("Harvested from %s.") % UiKit.mid(tr(String(Game.crop_info(crop).get("name", crop)))))
					break
			for b in Balance.get_value("buildings", {}):
				for r in Game.building_info(b).get("recipes", []):
					if r.get("out", {}).has(key):
						lines.append(tr("Made in the %s.") % UiKit.mid(tr(String(Game.building_info(b).get("name", b)))))
					if r.get("in", {}).has(key):
						lines.append(tr("Used by the %s.") % UiKit.mid(tr(String(Game.building_info(b).get("name", b)))))
			return " ".join(lines)
		"building":
			var info := Game.building_info(key)
			var zone := String(Game.zone_info(String(info.get("zone", "home"))).get("name", ""))
			var outs := []
			for r in info.get("recipes", []):
				for item in r.get("out", {}):
					outs.append(UiKit.mid(tr(String(Balance.get_value("items.%s.name" % item, item)))))
			var what := tr("Makes %s.") % ", ".join(outs) if not outs.is_empty() else ""
			return (tr("Stands on the %s.") % UiKit.mid(tr(zone))) + " " + what
		"helper":
			var h := Game.helper_info(key)
			return "%s. \"%s\"" % [tr(String(h.get("does", ""))), tr(String(h.get("quote", "")))]
		"festival":
			for f in Balance.get_value("calendar.festivals", []):
				if f["id"] == key:
					return tr(String(f.get("about", "")))
		"achievement":
			for a in Balance.get_value("achievements", []):
				if a["id"] == key:
					return tr(String(a.get("desc", "")))
	return tr(String(notes.get(id, "")))


func _picture(id: String) -> Texture2D:
	if _pictures.has(id):
		return _pictures[id]
	var tex := _find_picture(id)
	_pictures[id] = tex
	return tex


func _find_picture(id: String) -> Texture2D:
	var kind := id.get_slice(":", 0)
	var key := id.get_slice(":", 1)
	var paths := {
		"crop": [], "item": ["res://assets/sprites/icons32/%s.png" % key],
		"building": ["res://assets/sprites/buildings/%s_working.png" % key],
		"helper": ["res://assets/sprites/people/%s/east.png" % key],
		"achievement": ["res://assets/sprites/icons32/%s.png" % ("laurel" if key == "triumph" else "aureus")],
	}
	var named := {
		"animal:dog": "dog/east", "animal:donkey": "donkey/east", "animal:cat": "animals/cat_small/east", "animal:chicken": "animals/chicken/stand",
		"animal:goat": "animals/goat/east", "animal:fox": "animals/fox/east", "animal:rabbit": "animals/rabbit/sit", "animal:hoopoe": "animals/hoopoe/stand",
		"animal:stork": "animals/stork/nest", "find:old_coin": "icons32/sestertius", "find:truffle": "icons32/truffle", "find:rare_seed": "icons32/white_lavender",
		"sighting:fox": "animals/fox/east", "sighting:hoopoe": "animals/hoopoe/stand", "sighting:cat_and_dog": "animals/cat_small/sleep_east/frame_05",
		"milestone:all_zones": "villa/stage4", "milestone:all_buildings": "buildings/mill_working", "milestone:grand_estate": "villa/stage7",
		"milestone:all_helpers": "people/farmhand/east", "milestone:all_festivals": "decorations/garland_arch", "milestone:excellent_wine": "icons32/aged_wine",
		"festival:cerealia": "icons32/bread", "festival:floralia": "decorations/garland_arch", "festival:vinalia": "decorations/pergola",
		"festival:saturnalia": "decorations/saturnalia_lanterns",
	}
	if kind == "crop":
		return PlotViewScript.texture_for(key, "bloom")
	var list: Array = paths.get(kind, [])
	if named.has(id):
		list = ["res://assets/sprites/%s.png" % named[id]]
	for path in list:
		if ResourceLoader.exists(path):
			return _trimmed(load(path))
	return _drawn(id)


const PlotViewScript := preload("res://scripts/plot_view.gd")


## A picture cut down to its visible pixels, so it fills its frame.
func _trimmed(tex: Texture2D) -> Texture2D:
	var used := tex.get_image().get_used_rect()
	if used.size == Vector2i(tex.get_width(), tex.get_height()):
		return tex
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(used)
	return a


## Small pictures drawn in code, for creatures and sights that have no sprite of their own.
func _drawn(id: String) -> Texture2D:
	var art := {
		"animal:bees": ["..WW..", ".W..W.", "YKYKY.", "YKYKYK", ".YKYK."],
		"animal:butterflies": ["P.....P", "PP...PP", "PPPKPPP", ".PPKPP.", "..P.P.."],
		"sighting:white_butterfly": ["W.....W", "WW...WW", "WWWKWWW", ".WWKWW.", "..W.W.."],
		"animal:birds": ["K.....K", ".K...K.", "..KKK..", "...K...", "..K.K.."],
		"animal:fireflies": ["..g..", ".gGg.", "gGYGg", ".gGg.", "..g.."],
		"animal:dragonfly": ["WW.WW", ".WTW.", "..T..", "..T..", "..T.."],
		"animal:snail": ["..BB.", ".BbbB", "GBbbB", "GGGGG"],
		"animal:lizard": ["......G", "G.G.GG.", "GGGGG..", ".G.G..."],
		"sighting:shooting_star": ["......W", "....wW.", "..ww...", "ww....."],
		"sighting:rainbow": ["..RRRR..", ".RooooR.", "RoyyyyoR", "oy....yo", "y......y"],
		"sighting:mist": ["WWW.WWWW", "........", ".WWWW.WW", "........", "WW.WWWWW"],
		"sighting:aurora": ["v...vv.v", "vt.vttvt", "tA.tAAtA", "A..A..A.", "........"],
	}
	var colours := {"W": Color(0.97, 0.96, 0.93), "Y": Color(0.95, 0.76, 0.2), "K": Color(0.2, 0.15, 0.12), "P": Color(0.7, 0.55, 0.88),
		"g": Color(0.8, 1.0, 0.5, 0.45), "G": Color(0.45, 0.6, 0.3), "T": Color(0.2, 0.55, 0.65), "B": Color(0.45, 0.3, 0.2), "b": Color(0.62, 0.45, 0.3),
		"w": Color(1, 1, 0.85, 0.6), "R": Color(0.85, 0.3, 0.3), "o": Color(0.95, 0.6, 0.25), "y": Color(0.95, 0.88, 0.35),
		"A": Color(0.35, 0.95, 0.6), "t": Color(0.25, 0.7, 0.8), "v": Color(0.6, 0.4, 0.9, 0.7)}
	colours["G"] = Color(0.75, 1.0, 0.45) if id == "animal:fireflies" else colours["G"]
	var rows: Array = art.get(id, ["KKK", "K.K", "KKK"])
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in String(rows[y]).length():
			var ch := String(rows[y])[x]
			if colours.has(ch):
				img.set_pixel(x, y, colours[ch])
	return ImageTexture.create_from_image(img)
