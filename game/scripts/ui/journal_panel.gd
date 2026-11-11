extends "res://scripts/ui/window_panel.gd"
## The farmer's journal, drawn as an open book. Bookmarks choose a section; every entry stays in the left-page list,
## while the right page tells the selected entry's story. Undiscovered entries remain as dark silhouettes.

const SECTIONS := ["Crops", "Goods", "Buildings", "Helpers", "Animals", "Finds", "Sightings", "Festivals", "Milestones", "Achievements"]
const PAGE_W := 166
const PAGE_H := 196
const TILE := 34
## The tile's border and margin take two pixels on each side of its picture.
const ICON_PIXELS := TILE - 4
const ICON_ART_PIXELS := 28
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

var section := "Crops"
var selected := ""
var _pictures := {}
var _book: Control
var _page_views: Array[Control] = []
var _turning := false
## A section asked for while a page is turning, taken as soon as it lands.
var _queued := ""
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


## Turns the leaf to another section: the pages as they are now are pictured, the new section is laid out underneath,
## and a PageTurn leaf carries the old page over with the new one on its back.
func _turn_to(to: String) -> void:
	var target := SECTIONS.find(to)
	if target < 0 or to == section:
		return
	if _turning:
		_queued = to
		return
	if not is_instance_valid(_book) or not _book.is_inside_tree():
		return
	_turning = true
	var book := _book
	var direction := 1 if target > SECTIONS.find(section) else -1
	var shots := await PageTurn.capture(self, [_shot(1 if direction > 0 else 0), _shot(0 if direction > 0 else 1)], Windowing.ui_scale)
	# The journal may have been closed while its pages were pictured, and is then left closed.
	if not is_instance_valid(book) or not book.is_inside_tree() or _book != book:
		_turning = false
		return
	Sfx.play("page_turn")
	section = to
	selected = ""
	show_page()
	var turn := PageTurn.new()
	turn.direction = direction
	turn.left_page = Rect2(STACK, 0, PAGE_W, PAGE_H)
	turn.right_page = Rect2(STACK + PAGE_W + SPINE, 0, PAGE_W, PAGE_H)
	turn.front = shots[0]
	turn.behind = shots[1]
	turn.gutter = _draw_spine
	turn.landed.connect(_landed)
	turn.tree_exiting.connect(func(): _turning = false)
	_book.add_child(turn)
	var backs := await PageTurn.capture(self, [_shot(0 if direction > 0 else 1)], Windowing.ui_scale)
	if is_instance_valid(turn):
		turn.back = backs[0]


## A section asked for while the last page was turning follows as soon as the leaf lands.
func _landed() -> void:
	_turning = false
	if _queued != "":
		var next := _queued
		_queued = ""
		_turn_to(next)


## A page of the journal as it is laid out, to be pictured with its paper: 0 the left page, 1 the right.
func _shot(side: int) -> Dictionary:
	return {"page": _page_views[side], "paper": _paper(side == 0), "at": Vector2(MARGIN, MARGIN),
		"size": Vector2(PAGE_W, PAGE_H), "theme": UiKit.make_theme()}
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
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
		tile.pressed.connect(func(): Sfx.play("click", -8.0); selected = "" if selected == id else id; refresh())
		grid.add_child(tile)


## Give the right page a section-specific piece of journal writing before an entry is selected.
func _section_story(page: VBoxContainer, entries: Array) -> void:
	var discovered: Array = entries.filter(func(e): return _found(e["id"]))
	if discovered.is_empty():
		_heading(page, tr(section))
		UiKit.para(page, tr("Not discovered yet."), TEXT_W).add_theme_color_override("font_color", UiKit.MUTED)
		return
	var id := String(discovered[0]["id"])
	_heading(page, tr(_name(id)))
	var story := _describe(id)
	if story.is_empty():
		story = tr("A record from the %s pages of the journal.") % UiKit.mid(tr(section))
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
	pic.texture = _picture(id, 2)
	pic.custom_minimum_size = Vector2(TEXT_W - 10, 72)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
		UiKit.para(page, tr("Not discovered yet."), TEXT_W).add_theme_color_override("font_color", UiKit.MUTED)
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
		UiKit.para(page, text, TEXT_W).add_theme_color_override("font_color", UiKit.MUTED)


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


func _picture(id: String, times := 1) -> Texture2D:
	var key := "%s@%d" % [id, times]
	if _pictures.has(key):
		return _pictures[key]
	var tex := _uniform_icon(_find_picture(id))
	if tex and times > 1:
		var big := tex.get_image()
		big.resize(big.get_width() * times, big.get_height() * times, Image.INTERPOLATE_NEAREST)
		tex = ImageTexture.create_from_image(big)
	_pictures[key] = tex
	return tex


## Fits a picture into one icon square, enlarged a whole number of times or averaged down into its own colours, so it stays crisp.
func _uniform_icon(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var art := tex.get_image()
	if art.is_compressed():
		art.decompress()
	art.convert(Image.FORMAT_RGBA8)
	var used := art.get_used_rect()
	if used.size == Vector2i.ZERO:
		return tex
	art = art.get_region(used)
	var longest := maxi(art.get_width(), art.get_height())
	if longest <= ICON_ART_PIXELS:
		var times := ICON_ART_PIXELS / longest
		art.resize(art.get_width() * times, art.get_height() * times, Image.INTERPOLATE_NEAREST)
	else:
		art = _shrunk(art, float(longest) / ICON_ART_PIXELS)
	var canvas := Image.create(ICON_PIXELS, ICON_PIXELS, false, Image.FORMAT_RGBA8)
	var offset := (Vector2i(ICON_PIXELS, ICON_PIXELS) - art.get_size()) / 2
	canvas.blit_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), offset)
	return ImageTexture.create_from_image(canvas)


## A picture made `f` times smaller, each pixel the average of its block snapped to the nearest of the picture's own colours.
static func _shrunk(art: Image, f: float) -> Image:
	var palette := {}
	for y in art.get_height():
		for x in art.get_width():
			var c := art.get_pixel(x, y)
			if c.a > 0.5:
				palette[Color(c, 1.0)] = true
	var colours := palette.keys()
	var w := maxi(1, roundi(art.get_width() / f))
	var h := maxi(1, roundi(art.get_height() / f))
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var sum := Color(0, 0, 0, 0)
			var solid := 0
			var count := 0
			for sy in range(mini(int(y * f), art.get_height() - 1), clampi(int((y + 1) * f), int(y * f) + 1, art.get_height())):
				for sx in range(mini(int(x * f), art.get_width() - 1), clampi(int((x + 1) * f), int(x * f) + 1, art.get_width())):
					count += 1
					var c := art.get_pixel(sx, sy)
					if c.a > 0.5:
						sum += c
						solid += 1
			# A block that is mostly clear stays clear, so the outline keeps its shape.
			if solid * 2 < count:
				continue
			var mean := sum / solid
			var best: Color = colours[0]
			var nearest := INF
			for c: Color in colours:
				var d := (c.r - mean.r) ** 2 + (c.g - mean.g) ** 2 + (c.b - mean.b) ** 2
				if d < nearest:
					nearest = d
					best = c
			out.set_pixel(x, y, best)
	return out


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
		"animal:bees": "journal/journal_bees", "animal:butterflies": "journal/journal_butterflies", "animal:birds": "journal/journal_birds",
		"animal:fireflies": "journal/journal_fireflies", "animal:dragonfly": "journal/journal_dragonfly", "animal:snail": "journal/journal_snail",
		"animal:lizard": "journal/journal_lizard", "sighting:white_butterfly": "journal/journal_white_butterfly",
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
		"sighting:shooting_star": ["......W", "....wW.", "..ww...", "ww....."],
		"sighting:rainbow": ["..RRRR..", ".RooooR.", "RoyyyyoR", "oy....yo", "y......y"],
		"sighting:mist": ["WWW.WWWW", "........", ".WWWW.WW", "........", "WW.WWWWW"],
		"sighting:aurora": ["v...vv.v", "vt.vttvt", "tA.tAAtA", "A..A..A.", "........"],
	}
	var colours := {"W": Color(0.97, 0.96, 0.93), "w": Color(1, 1, 0.85, 0.6), "R": Color(0.85, 0.3, 0.3), "o": Color(0.95, 0.6, 0.25),
		"y": Color(0.95, 0.88, 0.35), "A": Color(0.35, 0.95, 0.6), "t": Color(0.25, 0.7, 0.8), "v": Color(0.6, 0.4, 0.9, 0.7)}
	var rows: Array = art.get(id, ["KKK", "K.K", "KKK"])
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var top := (24 - rows.size()) / 2
	for y in rows.size():
		var row := String(rows[y])
		var left := (24 - row.length()) / 2
		for x in row.length():
			var ch := row[x]
			if colours.has(ch):
				img.set_pixel(left + x, top + y, colours[ch])
	return ImageTexture.create_from_image(img)
