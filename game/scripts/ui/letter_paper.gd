class_name LetterPaper
## An old letter's sheet of parchment, drawn once for the uncle's letter at the start: worn, tea-stained and darker at
## its edges, folded in three for sending, with a ragged edge where it was cut, and a broken red wax seal.

const PARCH := Color(0.94, 0.86, 0.67)
const INK := Color(0.33, 0.21, 0.15)
const WAX := Color(0.66, 0.14, 0.13)


static func sheet(size: Vector2i, seed: int = 7) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var stains: Array = []
	for k in 5:
		stains.append([Vector2(rng.randf_range(0, size.x), rng.randf_range(0, size.y)), rng.randf_range(10.0, 28.0), rng.randf_range(0.03, 0.07)])
	var folds := [roundi(size.y / 3.0), roundi(size.y * 2 / 3.0)]
	for y in size.y:
		for x in size.x:
			# A ragged edge: a pixel or two bitten out here and there.
			var edge := mini(mini(x, size.x - 1 - x), mini(y, size.y - 1 - y))
			if edge == 0 and rng.randf() < 0.35 or edge == 1 and rng.randf() < 0.08:
				continue
			var c := PARCH.darkened(rng.randf_range(0.0, 0.04))
			# Older at the edges, where hands and weather reached it.
			c = c.darkened(clampf(0.16 - edge * 0.012, 0.0, 0.16))
			for s in stains:
				var d: float = Vector2(x, y).distance_to(s[0]) / float(s[1])
				if d < 1.0:
					c = c.lerp(Color(0.72, 0.54, 0.32), float(s[2]) * (1.0 - d * d))
			# The folds: a lit ridge with a shaded line beneath it.
			if y in folds:
				c = c.lightened(0.06)
			elif y - 1 in folds:
				c = c.darkened(0.08)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## The broken seal the letter was closed with: a red disc pressed with a ring, cracked across.
static func seal() -> ImageTexture:
	var img := Image.create(15, 15, false, Image.FORMAT_RGBA8)
	var c := Vector2(7, 7)
	for y in 15:
		for x in 15:
			var d := Vector2(x, y).distance_to(c)
			if d < 6.6:
				var col := WAX
				if d > 3.4 and d < 4.6:
					col = WAX.darkened(0.25)
				elif d < 2.2:
					col = WAX.lightened(0.12)
				if x - y == 1 or x - y == 2:
					col = WAX.darkened(0.45)
				img.set_pixel(x, y, col)
	img.set_pixel(5, 3, WAX.lightened(0.4))
	img.set_pixel(4, 4, WAX.lightened(0.3))
	return ImageTexture.create_from_image(img)
