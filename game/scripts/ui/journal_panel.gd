extends "res://scripts/ui/window_panel.gd"
## The farmer's journal, drawn as an open book. Bookmarks down the side choose a section; the right page shows
## every entry in it, with undiscovered ones as dark silhouettes; the left page tells the story of the chosen one.

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

var section := "Crops"
var selected := ""
var _pictures := {}
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
	var left := _page(book, STACK, true)
	var right_x := STACK + PAGE_W + SPINE
	if selected == "":
		_intro(left)
	else:
		_detail(left, selected)
	var right := UiKit.column(book)
	right.position = Vector2(right_x + MARGIN, MARGIN)
	right.custom_minimum_size = Vector2(PAGE_W - MARGIN - 4, 0)
	_grid(right)


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
	b.pressed.connect(func(): Sfx.play("tab", -4.0); section = s; selected = ""; show_page())
	parent.add_child(b)


## The left page holds the story of the chosen entry and scrolls when the story runs long, so the book never grows.
func _page(book: Control, x: int, _left: bool) -> VBoxContainer:
	var area := ScrollContainer.new()
	area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.position = Vector2(x + MARGIN, MARGIN)
	area.size = Vector2(PAGE_W - MARGIN - 4, PAGE_H - MARGIN * 2)
	book.add_child(area)
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
	for x in SPINE:
		book.draw_rect(Rect2(STACK + PAGE_W + x, 0, 1, PAGE_H + STACK), PAPER.darkened(0.5 - 0.08 * absf(x - (SPINE - 1) / 2.0)))


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
			var edge := mini(PAGE_W - 1 - inner, mini(y, PAGE_H - 1 - y))
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


func _intro(page: VBoxContainer) -> void:
	_heading(page, tr("The Farmer's Journal"))
	UiKit.para(page, tr("Everything you discover on the estate is written down here: every crop you grow, every good you make, the buildings you restore, the people who help you, the animals that visit and the rare sights you witness."), TEXT_W)
	UiKit.para(page, tr("Choose a bookmark, then a page. Pages still to be found are dark shapes: keep farming and keep watching."), TEXT_W).add_theme_color_override("font_color", UiKit.FADED)
	UiKit.label(page, tr("Pages filled: %d%%") % int(round(Game.journal.share() * 100.0)))
	UiKit.label(page, tr("Achievements: %d of %d") % [Game.journal.achievements.size(), Balance.get_value("achievements", []).size()])


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


func _grid(page: VBoxContainer) -> void:
	var list := _entries()
	var found := list.filter(func(e): return _found(e["id"])).size()
	_heading(page, "%s   %d / %d" % [tr(section), found, list.size()])
	var area := UiKit.scroll(page, Vector2(PAGE_W - MARGIN - 4, PAGE_H - 34))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	area.add_child(grid)
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
		tile.pressed.connect(func(): Sfx.play("click", -8.0); selected = id; refresh())
		grid.add_child(tile)


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


func _name(id: String) -> String:
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
			var zone := tr(" and the ").join(Game.crop_zones(key).map(func(z): return tr(String(Game.zone_info(z).get("name", ""))).to_lower()))
			var text := tr("Grows on the %s. Ready after %s") % [zone, UiKit.duration(float(c.get("grow_seconds", 60)))]
			text += (tr(", then again every %s.") % UiKit.duration(float(c["regrow_seconds"]))) if c.get("perennial", false) else tr(", then needs replanting.")
			return text + " " + tr("Each harvest gives %d %s.") % [int(c.get("yield", 1)), tr(String(Balance.get_value("items.%s.name" % c.get("item", key), key))).to_lower()]
		"item":
			var lines := [tr("Worth about %d sestertii at market.") % int(Game.base_price(key))]
			for crop in Balance.get_value("crops", {}):
				if Game.crop_info(crop).get("item", "") == key:
					lines.append(tr("Harvested from %s.") % tr(String(Game.crop_info(crop).get("name", crop))).to_lower())
					break
			for b in Balance.get_value("buildings", {}):
				for r in Game.building_info(b).get("recipes", []):
					if r.get("out", {}).has(key):
						lines.append(tr("Made in the %s.") % tr(String(Game.building_info(b).get("name", b))).to_lower())
					if r.get("in", {}).has(key):
						lines.append(tr("Used by the %s.") % tr(String(Game.building_info(b).get("name", b))).to_lower())
			return " ".join(lines)
		"building":
			var info := Game.building_info(key)
			var zone := String(Game.zone_info(String(info.get("zone", "home"))).get("name", ""))
			var outs := []
			for r in info.get("recipes", []):
				for item in r.get("out", {}):
					outs.append(tr(String(Balance.get_value("items.%s.name" % item, item))).to_lower())
			var what := tr("Makes %s.") % ", ".join(outs) if not outs.is_empty() else ""
			return (tr("Stands on the %s.") % tr(zone).to_lower()) + " " + what
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
		"achievement": ["res://assets/sprites/icons32/aureus.png"],
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
	}
	var colours := {"W": Color(0.97, 0.96, 0.93), "Y": Color(0.95, 0.76, 0.2), "K": Color(0.2, 0.15, 0.12), "P": Color(0.7, 0.55, 0.88),
		"g": Color(0.8, 1.0, 0.5, 0.45), "G": Color(0.45, 0.6, 0.3), "T": Color(0.2, 0.55, 0.65), "B": Color(0.45, 0.3, 0.2), "b": Color(0.62, 0.45, 0.3),
		"w": Color(1, 1, 0.85, 0.6), "R": Color(0.85, 0.3, 0.3), "o": Color(0.95, 0.6, 0.25), "y": Color(0.95, 0.88, 0.35)}
	colours["G"] = Color(0.75, 1.0, 0.45) if id == "animal:fireflies" else colours["G"]
	var rows: Array = art.get(id, ["KKK", "K.K", "KKK"])
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in String(rows[y]).length():
			var ch := String(rows[y])[x]
			if colours.has(ch):
				img.set_pixel(x, y, colours[ch])
	return ImageTexture.create_from_image(img)
