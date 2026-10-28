extends Node
## The trailer's edit: plays the recorded shots in order with their own sound under the music, the black caption cards
## between them, captions over some shots and the end card with the logo. tools/trailer/make_trailer.py renders it in
## movie mode, so this runs exactly once per frame and the result is the finished trailer.

const FPS := 30.0
## One beat of the music, in seconds; every cut lands on a beat.
const BEAT := 0.857
const MUSIC := "res://assets/audio/music/solitary_expedition.ogg"
## The game records its effects and ambience quietly beside the music, so they are raised to be heard under it.
const MUSIC_DB := -4.0
const SOUND_DB := 9.0
const INK := Color(0.29, 0.18, 0.14)
## Where the scroll's line of text sits, from the top of its picture, so it is centred on the sheet between the rolls.
const SCROLL_TEXT_TOP := -1
const SCROLL_TEXT_HEIGHT := 54
const CREAM := Color(0.99, 0.95, 0.86)
## The cut list. A shot plays from `from` seconds into its recording; a card is black with one line of text.
const EDIT := [
	{"shot": "hook", "from": 1.5, "beats": 8, "fade_in": 0.8},
	{"card": "Uncle Marcus has left you
his farm.", "beats": 3},
	{"shot": "ruin", "from": 1.0, "beats": 4},
	{"card": "It has seen better days.", "beats": 3},
	{"shot": "plant", "from": 1.5, "beats": 6},
	{"shot": "cart", "from": 1.4, "beats": 3},
	{"shot": "coins", "from": 14.0, "beats": 4},
	{"shot": "helper", "from": 1.5, "beats": 3},
	{"shot": "bakery", "from": 1.5, "beats": 3},
	{"shot": "villa", "from": 0.8, "beats": 6},
	{"shot": "pasture", "from": 1.5, "beats": 3},
	{"shot": "vineyard", "from": 1.5, "beats": 3},
	{"shot": "grove", "from": 1.5, "beats": 3},
	{"shot": "pet", "from": 1.6, "beats": 4, "zoom": 2.0, "centre": Vector2(960, 810)},
	{"shot": "hoopoe", "from": 1.8, "beats": 5, "zoom": 2.0, "centre": Vector2(960, 810)},
	{"shot": "inside", "from": 1.5, "beats": 3},
	{"shot": "town", "from": 1.5, "beats": 3},
	{"shot": "timelapse", "from": 1.5, "beats": 6, "caption": "Your helpers work while you rest.", "mute": true},
	{"card": "Make it the finest estate
in the hills.", "beats": 3},
	{"shot": "night", "from": 1.5, "beats": 7},
	{"end": "endcard", "from": 1.0, "beats": 8},
]

var _shots_dir := ""
var _frame := 0
var _starts: Array = []
var _total_frames := 0
var _picture: TextureRect
var _texture: ImageTexture
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
	var t := 0
	for seg in EDIT:
		_starts.append(t)
		t += int(round(float(seg["beats"]) * BEAT * FPS))
	_total_frames = t
	_build()
	_music = AudioStreamPlayer.new()
	_music.stream = load(MUSIC)
	add_child(_music)
	_sound = AudioStreamPlayer.new()
	add_child(_sound)
	# A preview can start part way through, to look at one moment without rendering the whole trailer.
	_frame = int(from * FPS)
	_music.play(from)


func _build() -> void:
	_texture = ImageTexture.create_from_image(Image.create(1920, 1080, false, Image.FORMAT_RGB8))
	_picture = TextureRect.new()
	_picture.texture = _texture
	_picture.size = Vector2(1920, 1080)
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_picture)
	# Cards, captions and the end card are drawn at the game's own 480 by 270 and scaled up like the game.
	_overlay = SubViewport.new()
	_overlay.size = Vector2i(480, 270)
	_overlay.transparent_bg = true
	_overlay.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(_overlay)
	var shown := TextureRect.new()
	shown.texture = _overlay.get_texture()
	shown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shown.size = Vector2(1920, 1080)
	shown.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shown)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.size = Vector2(480, 270)
	_overlay.add_child(_black)
	# Text is drawn at twice the interface's pixel font size, still a whole number of its pixels, to read at a glance.
	_card_text = _label(Vector2(20, 100), 440, 70)
	_caption = _label(Vector2(0, 20), 480, 20)
	_caption.add_theme_color_override("font_outline_color", INK)
	_caption.add_theme_constant_override("outline_size", 3)
	_logo = TextureRect.new()
	_logo.texture = load("res://tools/trailer/logo.png")
	_logo.position = Vector2(roundf((480 - _logo.texture.get_width()) / 2.0), 30)
	_overlay.add_child(_logo)
	_scroll = TextureRect.new()
	_scroll.texture = load("res://tools/trailer/scroll.png")
	_scroll.position = Vector2(roundf((480 - _scroll.texture.get_width()) / 2.0), 134)
	_overlay.add_child(_scroll)
	_wishlist = _label(_scroll.position + Vector2(0, SCROLL_TEXT_TOP), _scroll.texture.get_width(), SCROLL_TEXT_HEIGHT)
	_wishlist.text = "Wishlist now on Steam"
	_wishlist.add_theme_color_override("font_color", INK)


func _label(at: Vector2, width: float, height: float) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", UiKit._crisp(UiKit.FONT))
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", CREAM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The pixel font's own line height leaves a whole blank line between lines; this closes it to a small gap.
	l.add_theme_constant_override("line_spacing", -8)
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
	var seg: Dictionary = EDIT[k]
	var local := float(_frame - _starts[k]) / FPS
	var length := float(seg["beats"]) * BEAT
	if k != _current:
		_current = k
		_start_segment(seg)
	_draw_segment(seg, local, length)
	# The music fades away over the end card's last seconds.
	var left := float(_total_frames - _frame) / FPS
	_music.volume_db = MUSIC_DB + linear_to_db(clampf(left / 3.0, 0.0001, 1.0))
	_frame += 1


func _start_segment(seg: Dictionary) -> void:
	_sound.stop()
	var name := String(seg.get("shot", seg.get("end", "")))
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
	var name := String(seg.get("shot", seg.get("end", "")))
	var index := int(round((float(seg["from"]) + local) * FPS))
	var path := _shots_dir.path_join(name).path_join("f%08d.png" % index)
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		img.convert(Image.FORMAT_RGB8)
		_texture.update(img)
	# Small moments are shown twice as large, a whole number of times so the pixels stay square.
	var zoom := float(seg.get("zoom", 1.0))
	var centre: Vector2 = seg.get("centre", Vector2(960, 540))
	_picture.scale = Vector2(zoom, zoom)
	_picture.position = (Vector2(960, 540) - centre * zoom).clamp(Vector2(1920, 1080) * (1.0 - zoom), Vector2.ZERO)
	var fade_in := float(seg.get("fade_in", 0.0))
	_picture.modulate = Color.WHITE * (clampf(local / fade_in, 0.0, 1.0) if fade_in > 0.0 else 1.0)
	_picture.modulate.a = 1.0
	if seg.has("caption"):
		_caption.text = String(seg["caption"])
		_caption.modulate.a = clampf(minf((local - 0.6) / 0.4, (length - local) / 0.4), 0.0, 1.0)
	if is_end:
		# The logo settles in first, then the scroll unrolls beneath it.
		_logo.modulate.a = clampf((local - 0.4) / 0.8, 0.0, 1.0)
		_logo.position.y = 30 + roundf(4.0 * (1.0 - _logo.modulate.a))
		var s := clampf((local - 1.6) / 0.6, 0.0, 1.0)
		_scroll.modulate.a = s
		_wishlist.modulate.a = s
	# Sound from each shot fades in and out quickly at its cuts, so cuts never click.
	_sound.volume_db = SOUND_DB + linear_to_db(clampf(minf(local / 0.08, (length - local) / 0.08), 0.0001, 1.0))
