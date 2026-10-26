class_name GroundPlants
## Little tufts of grass and weeds for untended ground, drawn pixel by pixel because at this size a few blades read
## better than a shrunken painting.

const GREENS := [Color8(70, 96, 44), Color8(98, 124, 56), Color8(138, 156, 74)]
const STRAW := [Color8(128, 108, 64), Color8(160, 136, 82), Color8(190, 166, 104)]
const FLOWERS := [Color8(232, 200, 84), Color8(236, 230, 212), Color8(196, 150, 200)]

static var _cache: Array[Texture2D] = []
static var _tall: Array[Texture2D] = []


## A dozen different tufts, the same every time the game runs.
static func textures() -> Array[Texture2D]:
	if _cache.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 41
		for i in 12:
			_cache.append(_tuft(rng, i % 4 == 3, i % 3 == 1))
	return _cache


## Long grass the scythe has missed, for field edges and fence lines: taller, thinner and often gone to seed.
static func tall_textures() -> Array[Texture2D]:
	if _tall.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for i in 10:
			_tall.append(_tuft(rng, i % 3 == 2, i % 4 == 1, Vector2i(8, 13)))
	return _tall


static func _tuft(rng: RandomNumberGenerator, dry: bool, flowering: bool, heights := Vector2i(4, 8)) -> Texture2D:
	var w := rng.randi_range(6, 10)
	var h := rng.randi_range(heights.x, heights.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var colours: Array = STRAW if dry else GREENS
	var tips: Array[Vector2i] = []
	for blade in rng.randi_range(3, 6):
		var x := rng.randi_range(1, w - 2)
		var tall := rng.randi_range(2, h)
		var lean := rng.randi_range(-1, 1)
		for k in tall:
			var px := clampi(x + (lean * k) / 3, 0, w - 1)
			var shade: Color = colours[0] if k == 0 else (colours[2] if k == tall - 1 else colours[1])
			img.set_pixel(px, h - 1 - k, shade)
			if k == tall - 1:
				tips.append(Vector2i(px, h - 1 - k))
	if flowering and not dry:
		var flower: Color = FLOWERS[rng.randi() % FLOWERS.size()]
		for t in tips.slice(0, rng.randi_range(1, 2)):
			img.set_pixelv(t, flower)
	return ImageTexture.create_from_image(img)
