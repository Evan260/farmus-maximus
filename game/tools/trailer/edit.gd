extends Node
## The edits of the trailer and of the short vertical cut for phones: each plays its recorded shots in order with their
## own sound under the music, with black caption cards, captions over shots and the end card with the logo.
## tools/trailer/make_trailer.py renders one in movie mode, so this runs exactly once per frame.

const FPS := 30.0
## One beat of the music, in seconds; every cut lands on a beat.
const BEAT := 0.857
const MUSIC := "res://assets/audio/music/solitary_expedition.ogg"
## The game records its effects and ambience quietly beside the music, so they are raised to be heard under it.
const MUSIC_DB := -4.0
const SOUND_DB := 9.0
## The ambience runs unbroken under the whole cut, about as far beneath the music as in the game.
const AMBIENCE_DB := -4.0
## Seconds the ambience takes to blend from one loop into the next, such as day into night.
const AMBIENCE_BLEND := 1.2
const INK := Color(0.29, 0.18, 0.14)
## Where the scroll's line of text sits, from the top of its picture, so it is centred on the sheet between the rolls.
const SCROLL_TEXT_TOP := -1
const SCROLL_TEXT_HEIGHT := 54
const CREAM := Color(0.99, 0.95, 0.86)
## The trailer's cut list, told in order: the farm as it was left, then the farmhouse restored stage by stage to the
## grand estate. A shot plays from `from` seconds into its recording; a card is black with one line of text. `amb` is
## the ambience from then on: day, night or rain.
const TRAILER := [
	{"card": "Uncle Marcus has left you\nhis farm.", "beats": 4, "amb": "day"},
	{"shot": "ruin", "from": 1.0, "beats": 5, "fade_in": 0.8},
	{"card": "It has seen better days.", "beats": 3},
	{"shot": "restore", "from": 0.8, "beats": 6},
	{"shot": "plant", "from": 1.5, "beats": 5},
	{"shot": "cart", "from": 1.4, "beats": 3},
	{"shot": "market_ui", "from": 0.9, "beats": 5},
	{"shot": "coins", "from": 14.0, "beats": 4},
	{"shot": "villa", "from": 0.8, "beats": 6},
	{"shot": "bakery_ui", "from": 1.3, "beats": 5},
	{"shot": "pasture", "from": 1.5, "beats": 3},
	{"shot": "vineyard", "from": 1.5, "beats": 3},
	{"shot": "grove", "from": 1.5, "beats": 3, "amb": "rain"},
	{"card": "Make it the finest estate\nin the hills.", "beats": 3, "amb": "day"},
	{"shot": "grand", "from": 0.8, "beats": 6},
	{"shot": "shrine_ui", "from": 1.3, "beats": 5},
	{"shot": "pet", "from": 1.6, "beats": 4, "zoom": 2.0, "centre": Vector2(960, 810)},
	{"desk": "desk", "from": 1.0, "beats": 7, "caption": "It keeps farming while you work."},
	{"shot": "timelapse", "from": 1.5, "beats": 5, "caption": "Your helpers work while you rest.", "mute": true},
	{"shot": "inside", "from": 1.5, "beats": 3, "amb": "night"},
	{"shot": "night", "from": 1.5, "beats": 6},
	{"end": "endcard", "from": 1.0, "beats": 7},
]
## The short cut for phones: no cards, a caption from the first frame, and quicker cuts.
const SHORT := [
	{"shot": "ruin", "from": 1.0, "beats": 4, "caption": "POV: your uncle
left you a ruined
Roman farm", "caption_at": 0.0, "amb": "day"},
	{"shot": "villa", "from": 0.8, "beats": 6, "caption": "so you bring it
back to life"},
	{"shot": "plant", "from": 1.6, "beats": 3},
	{"shot": "helper", "from": 1.5, "beats": 2},
	{"shot": "bakery", "from": 1.5, "beats": 2, "amb": "night"},
	{"shot": "pasture", "from": 1.5, "beats": 2, "amb": "day"},
	{"shot": "vineyard", "from": 1.5, "beats": 2},
	{"shot": "pet", "from": 1.6, "beats": 3},
	{"shot": "hoopoe", "from": 2.2, "beats": 3},
	{"shot": "timelapse", "from": 1.5, "beats": 4, "caption": "it keeps working
while you sleep", "mute": true},
	{"shot": "night", "from": 1.5, "beats": 3, "amb": "night"},
	{"end": "endcard", "from": 1.0, "beats": 6},
]
## Day 1 to the grand estate: one shot, the villa reaching a new stage every two beats, the day counting up.
const TRANSFORM := [
	{"shot": "stages", "from": 0.286, "beats": 2, "caption": "Day 1\nI inherited a ruin", "caption_at": 0.0, "amb": "day"},
	{"shot": "stages", "from": 2.0, "beats": 2, "caption": "Day 3", "caption_at": 0.0},
	{"shot": "stages", "from": 3.714, "beats": 2, "caption": "Day 9", "caption_at": 0.0},
	{"shot": "stages", "from": 5.428, "beats": 2, "caption": "Day 30", "caption_at": 0.0},
	{"shot": "stages", "from": 7.142, "beats": 2, "caption": "Day 60", "caption_at": 0.0},
	{"shot": "stages", "from": 8.856, "beats": 2, "caption": "Day 90", "caption_at": 0.0},
	{"shot": "stages", "from": 10.57, "beats": 4, "caption": "Day 120", "caption_at": 0.0},
	{"end": "endcard", "from": 1.0, "beats": 5},
]
## Yes, you can pet the dog, and then everything else.
const PETS := [
	{"shot": "pet", "from": 1.6, "beats": 3, "caption": "Yes, you can\npet the dog", "caption_at": 0.0, "amb": "day"},
	{"shot": "cat", "from": 1.6, "beats": 3, "caption": "and the cat", "caption_at": 0.0},
	{"shot": "donkey", "from": 1.6, "beats": 3, "caption": "and the donkey", "caption_at": 0.0},
	{"shot": "goat", "from": 1.6, "beats": 3, "caption": "and the goats", "caption_at": 0.0},
	{"shot": "stork", "from": 1.6, "beats": 3, "caption": "and the stork?", "caption_at": 0.0},
	{"shot": "hoopoe", "from": 2.0, "beats": 4, "caption": "and... whatever\nthis is", "caption_at": 0.0},
	{"end": "endcard", "from": 1.0, "beats": 5},
]
## No music, only the farm: rain, the oven's fire, the harvest and the night.
const ASMR := [
	{"shot": "grove", "from": 1.0, "beats": 5, "caption": "turn your\nsound on", "caption_at": 0.0, "amb": "rain"},
	{"shot": "bakery", "from": 1.5, "beats": 4, "amb": "night"},
	{"shot": "plant", "from": 1.6, "beats": 5, "amb": "day"},
	{"shot": "pasture", "from": 1.5, "beats": 4},
	{"shot": "night", "from": 1.5, "beats": 6, "amb": "night"},
	{"end": "endcard", "from": 1.0, "beats": 5},
]
## How each cut is laid out: its frame, how many screen pixels make one overlay pixel, its caption size, where its text
## and logo sit in overlay pixels, where in the music it starts, and optionally no music and louder ambience.
const CUTS := {
	"trailer": {"edit": TRAILER, "size": Vector2i(1920, 1080), "pixel": 4, "caption_size": 16, "caption_y": 20, "logo_y": 30, "scroll_y": 134, "music_from": 0.0},
	"ruin_to_life": {"edit": SHORT, "size": Vector2i(1080, 1920), "pixel": 3, "caption_size": 24, "caption_y": 100, "logo_y": 150, "scroll_y": 262, "music_from": 41.1},
	"day_1_vs_day_120": {"edit": TRANSFORM, "size": Vector2i(1080, 1920), "pixel": 3, "caption_size": 24, "caption_y": 100, "logo_y": 150, "scroll_y": 262, "music_from": 41.1},
	"pet_the_dog": {"edit": PETS, "size": Vector2i(1080, 1920), "pixel": 3, "caption_size": 24, "caption_y": 100, "logo_y": 150, "scroll_y": 262, "music_from": 0.0},
	"cozy_sounds": {"edit": ASMR, "size": Vector2i(1080, 1920), "pixel": 3, "caption_size": 24, "caption_y": 100, "logo_y": 150, "scroll_y": 262, "music_from": 0.0, "music": false, "ambience_db": 4.0},
}

var _shots_dir := ""
var _cut: Dictionary = CUTS["trailer"]
var _edit: Array = TRAILER
var _size := Vector2(1920, 1080)
var _frame := 0
var _starts: Array = []
var _total_frames := 0
var _picture: TextureRect
var _texture: ImageTexture
## A real desktop's screenshot and the strip laid over it, for the shot of the farm along the bottom of a screen, and
## how tall the desktop's taskbar is; without a screenshot that shot is left out of the cut.
var _desktop: Texture2D
var _taskbar := 0
var _strip: TextureRect
var _strip_texture: ImageTexture
var _overlay: SubViewport
var _black: ColorRect
var _card_text: Label
var _caption: Label
var _logo: TextureRect
var _scroll: TextureRect
var _wishlist: Label
var _music: AudioStreamPlayer
var _sound: AudioStreamPlayer
var _current := -1
## The day, night and rain loops, all playing from the start, and how loud each is now, from 0 to 1.
var _beds := {}
var _bed_gain := {}
var _bed := "day"


func _ready() -> void:
	# The game's own systems start with this scene too: nothing may save, and only the trailer's own sound plays.
	Saves.enabled = false
	RenderingServer.set_default_clear_color(Color.BLACK)
	for bus in ["Music", "Ambience", "Effects"]:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), true)
	var from := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
		elif arg.begins_with("--from="):
			from = float(arg.trim_prefix("--from="))
		elif arg.begins_with("--cut="):
			_cut = CUTS[arg.trim_prefix("--cut=")]
		elif arg.begins_with("--desktop="):
			var shot := Image.load_from_file(arg.trim_prefix("--desktop="))
			if shot:
				_desktop = ImageTexture.create_from_image(shot)
		elif arg.begins_with("--taskbar="):
			_taskbar = int(arg.trim_prefix("--taskbar="))
	_edit = _cut["edit"]
	if _desktop == null:
		_edit = _edit.filter(func(seg): return not seg.has("desk"))
	_size = Vector2(_cut["size"])
	var t := 0
	for seg in _edit:
		_starts.append(t)
		t += int(round(float(seg["beats"]) * BEAT * FPS))
	_total_frames = t
	_build()
	_music = AudioStreamPlayer.new()
	_music.stream = load(MUSIC)
	add_child(_music)
	_sound = AudioStreamPlayer.new()
	add_child(_sound)
	for name in ["day", "night", "rain"]:
		var loop: AudioStream = load("res://assets/audio/ambience/%s.ogg" % name).duplicate()
		loop.loop = true
		var bed := AudioStreamPlayer.new()
		bed.stream = loop
		bed.volume_db = -80.0
		add_child(bed)
		_beds[name] = bed
		_bed_gain[name] = 0.0
	# A preview can start part way through, to look at one moment without rendering the whole trailer.
	_frame = int(from * FPS)
	if _cut.get("music", true):
		_music.play(float(_cut["music_from"]) + from)
	for name in _beds:
		_beds[name].play(from)
	# A preview starts in the ambience set last before it.
	for k in _starts.size():
		if _starts[k] <= _frame and _edit[k].has("amb"):
			_bed = String(_edit[k]["amb"])
	_bed_gain[_bed] = 1.0


func _build() -> void:
	_texture = ImageTexture.create_from_image(Image.create(int(_size.x), int(_size.y), false, Image.FORMAT_RGB8))
	_picture = TextureRect.new()
	_picture.texture = _texture
	_picture.size = _size
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_picture)
	_strip = TextureRect.new()
	_strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_strip.visible = false
	add_child(_strip)
	# Cards, captions and the end card are drawn in big pixels and scaled up, like the game.
	var area := _size / float(_cut["pixel"])
	_overlay = SubViewport.new()
	_overlay.size = Vector2i(area)
	_overlay.transparent_bg = true
	_overlay.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_overlay)
	var shown := TextureRect.new()
	shown.texture = _overlay.get_texture()
	shown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shown.size = _size
	shown.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shown)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.size = area
	_overlay.add_child(_black)
	# Text is drawn at twice the interface's pixel font size, still a whole number of its pixels, to read at a glance.
	_card_text = _label(Vector2(20, area.y / 2.0 - 35.0), area.x - 40.0, 70)
	# Phones are read at arm's length, so the short's captions are half as big again, still whole pixels of the font.
	_caption = _label(Vector2(10, float(_cut["caption_y"])), area.x - 20.0, 100, int(_cut["caption_size"]))
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_caption.add_theme_color_override("font_outline_color", INK)
	_caption.add_theme_constant_override("outline_size", 3)
	_logo = TextureRect.new()
	_logo.texture = load("res://tools/trailer/logo.png")
	_logo.position = Vector2(roundf((area.x - _logo.texture.get_width()) / 2.0), float(_cut["logo_y"]))
	_overlay.add_child(_logo)
	_scroll = TextureRect.new()
	_scroll.texture = load("res://tools/trailer/scroll.png")
	_scroll.position = Vector2(roundf((area.x - _scroll.texture.get_width()) / 2.0), float(_cut["scroll_y"]))
	_overlay.add_child(_scroll)
	_wishlist = _label(_scroll.position + Vector2(0, SCROLL_TEXT_TOP), _scroll.texture.get_width(), SCROLL_TEXT_HEIGHT)
	_wishlist.text = "Wishlist now on Steam"
	_wishlist.add_theme_color_override("font_color", INK)


func _label(at: Vector2, width: float, height: float, size := 16) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", UiKit._crisp(UiKit.FONT))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", CREAM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The pixel font's own line height leaves a whole blank line between lines; this closes it to a small gap.
	l.add_theme_constant_override("line_spacing", -size / 2)
	l.position = at
	l.size = Vector2(width, height)
	_overlay.add_child(l)
	return l


func _process(_delta: float) -> void:
	if _frame >= _total_frames:
		get_tree().quit()
		return
	var k := _starts.size() - 1
	while _starts[k] > _frame:
		k -= 1
	var seg: Dictionary = _edit[k]
	var local := float(_frame - _starts[k]) / FPS
	var length := float(seg["beats"]) * BEAT
	if k != _current:
		_current = k
		_start_segment(seg)
	_draw_segment(seg, local, length)
	# The music and the ambience fade away together over the end card's last seconds.
	var left := float(_total_frames - _frame) / FPS
	var ending := clampf(left / 3.0, 0.0001, 1.0)
	_music.volume_db = MUSIC_DB + linear_to_db(ending)
	if seg.has("amb"):
		_bed = String(seg["amb"])
	for name in _beds:
		_bed_gain[name] = move_toward(_bed_gain[name], 1.0 if name == _bed else 0.0, 1.0 / (AMBIENCE_BLEND * FPS))
		_beds[name].volume_db = float(_cut.get("ambience_db", AMBIENCE_DB)) + linear_to_db(maxf(_bed_gain[name] * ending, 0.0001))
	_frame += 1


func _start_segment(seg: Dictionary) -> void:
	_sound.stop()
	var name := String(seg.get("shot", seg.get("end", seg.get("desk", ""))))
	if name == "":
		return
	var wav := _shots_dir.path_join(name).path_join("f.wav")
	# A time-lapse plays its day's sounds many times over, so it is left to the music alone.
	if FileAccess.file_exists(wav) and not seg.get("mute", false):
		_sound.stream = AudioStreamWAV.load_from_file(wav)
		_sound.play(float(seg["from"]))


func _draw_segment(seg: Dictionary, local: float, length: float) -> void:
	var is_card := seg.has("card")
	var is_end := seg.has("end")
	_black.visible = is_card
	_card_text.visible = is_card
	_caption.visible = seg.has("caption")
	_logo.visible = is_end
	_scroll.visible = is_end
	_wishlist.visible = is_end
	if is_card:
		_card_text.text = String(seg["card"])
		# The line fades in and out on the black, so cards never jump.
		_card_text.modulate.a = clampf(minf(local / 0.35, (length - local) / 0.35), 0.0, 1.0)
		return
	var name := String(seg.get("shot", seg.get("end", seg.get("desk", ""))))
	var index := int(round((float(seg["from"]) + local) * FPS))
	var path := _shots_dir.path_join(name).path_join("f%08d.png" % index)
	_strip.visible = seg.has("desk")
	_picture.texture = _desktop if seg.has("desk") and _desktop else _texture
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if seg.has("desk"):
			img.convert(Image.FORMAT_RGBA8)
			# The strip's frames are sized as it ran; it sits centred along the bottom of the desktop, above its taskbar.
			if _strip_texture == null:
				_strip_texture = ImageTexture.create_from_image(img)
				_strip.texture = _strip_texture
				_strip.position = Vector2(roundf((_size.x - img.get_width()) / 2.0), _size.y - _taskbar - img.get_height())
			_strip_texture.update(img)
		else:
			img.convert(Image.FORMAT_RGB8)
			_texture.update(img)
	# Small moments are shown twice as large, a whole number of times so the pixels stay square.
	var zoom := float(seg.get("zoom", 1.0))
	var centre: Vector2 = seg.get("centre", _size / 2.0)
	_picture.scale = Vector2(zoom, zoom)
	_picture.position = (_size / 2.0 - centre * zoom).clamp(_size * (1.0 - zoom), Vector2.ZERO)
	var fade_in := float(seg.get("fade_in", 0.0))
	_picture.modulate = Color.WHITE * (clampf(local / fade_in, 0.0, 1.0) if fade_in > 0.0 else 1.0)
	_picture.modulate.a = 1.0
	if seg.has("caption"):
		_caption.text = String(seg["caption"])
		# A caption fades in a moment into its shot, unless it opens the cut, where it is there from the first frame.
		var shown_at := float(seg.get("caption_at", 0.6))
		var appear := clampf((local - shown_at) / 0.4, 0.0, 1.0) if shown_at > 0.0 else 1.0
		_caption.modulate.a = minf(appear, clampf((length - local) / 0.4, 0.0, 1.0))
	if is_end:
		# The logo settles in first, then the scroll unrolls beneath it.
		_logo.modulate.a = clampf((local - 0.4) / 0.8, 0.0, 1.0)
		_logo.position.y = float(_cut["logo_y"]) + roundf(4.0 * (1.0 - _logo.modulate.a))
		var s := clampf((local - 1.6) / 0.6, 0.0, 1.0)
		_scroll.modulate.a = s
		_wishlist.modulate.a = s
	# Sound from each shot fades in and out quickly at its cuts, so cuts never click.
	_sound.volume_db = SOUND_DB + linear_to_db(clampf(minf(local / 0.08, (length - local) / 0.08), 0.0001, 1.0))
