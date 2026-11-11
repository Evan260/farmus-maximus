class_name WorkshopParts
## The picture pieces a workshop window is made of, in the manner of a furnace screen: framed slots that hold a good
## with a count, an arrow that fills as a batch is made, and small tags for what an upgrade brings.

const ICONS32 := "res://assets/sprites/icons32/"
const SLOT_FILL := Color(0.83, 0.71, 0.52)
const SLOT_EDGE := Color(0.42, 0.26, 0.18)
const SLOT_SHADE := Color(0.62, 0.48, 0.33)


## A framed slot showing a good's picture and a count in its corner.
static func slot(parent: Node, item: String, size := 40) -> Label:
	# A plain panel rather than a container, so the count can be pinned to the bottom-right corner over the picture.
	var frame := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_FILL
	style.border_color = SLOT_EDGE
	style.set_border_width_all(2)
	style.border_width_top = 3
	frame.add_theme_stylebox_override("panel", style)
	frame.custom_minimum_size = Vector2(size, size)
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(frame)
	var pic := TextureRect.new()
	var path := ICONS32 + Game.item_base(item) + ".png"
	pic.texture = load(path) if ResourceLoader.exists(path) else null
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(pic)
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var count := Label.new()
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.add_theme_color_override("font_color", UiKit.CREAM)
	count.add_theme_color_override("font_outline_color", SLOT_EDGE)
	count.add_theme_constant_override("outline_size", 3)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(count)
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.offset_right = -3
	count.offset_bottom = -1
	return count


## A helper's head and shoulders, cut from the top of their standing picture, for a window too small for all of them.
static func face(parent: Node, helper: String) -> TextureRect:
	var t := TextureRect.new()
	var path := "res://assets/sprites/people/%s/east.png" % helper
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		var used := tex.get_image().get_used_rect()
		var cut := AtlasTexture.new()
		cut.atlas = tex
		cut.region = Rect2(used.position.x - 1, used.position.y, used.size.x + 2, mini(16, used.size.y))
		t.texture = cut
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(t)
	return t


## A small caption under a slot, such as how many go into one batch.
static func caption(parent: Node, text: String) -> Label:
	var l := UiKit.label(parent, text)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", UiKit.MUTED)
	return l


## A slot with its caption below it, both centred in a column.
static func slot_with_caption(parent: Node, item: String, text: String) -> Label:
	var col := UiKit.column(parent)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var count := slot(col, item)
	caption(col, text)
	return count


class Arrow extends Control:
	## How far the batch has come, from 0 to 1; the arrow fills from its tail to its point.
	var value := 0.0:
		set(v):
			if not is_equal_approx(v, value):
				value = v
				queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(36, 18)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var mid := floorf(size.y / 2.0)
		var shaft_end := size.x - 9.0
		var fill_to := roundf(size.x * clampf(value, 0.0, 1.0))
		# The shaft, then the head as stacked rows that narrow to a point.
		for x in int(size.x):
			var half := 2.0 if x < shaft_end else maxf(0.0, (size.x - 1.0 - x) * 0.9)
			if x >= shaft_end:
				half = minf(8.0, half)
			var c: Color = UiKit.HEADING if x < fill_to else WorkshopParts.SLOT_SHADE
			draw_rect(Rect2(x, mid - half, 1, half * 2.0 + 1.0), c)


## A short word or two on a small tinted plate, such as what the next level brings.
static func tag(parent: Node, text: String) -> Label:
	var plate := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_FILL
	style.border_color = SLOT_SHADE
	style.set_border_width_all(1)
	style.content_margin_left = 3
	style.content_margin_right = 3
	plate.add_theme_stylebox_override("panel", style)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(plate)
	return UiKit.label(plate, text)
