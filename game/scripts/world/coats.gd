class_name Coats
## Coat colours for the dog and the cat. Only the fur's warm brown and ginger pixels change, so collars, eyes and the
## pale chest stay as drawn, and every animation frame is recoloured the same way.

const DOG := {"golden": "Golden", "black": "Black", "chocolate": "Chocolate", "cream": "Cream", "grey": "Grey", "red": "Red"}
const CAT := {"ginger": "Ginger tabby", "grey": "Grey tabby", "black": "Black", "white": "White", "brown": "Brown tabby"}

static var _cache := {}


static func options(animal: String) -> Dictionary:
	return DOG if animal == "dog" else CAT


static func recolour(tex: Texture2D, animal: String, coat: String) -> Texture2D:
	if coat == "" or coat == options(animal).keys()[0]:
		return tex
	var key := "%s|%s" % [tex.resource_path, coat]
	if _cache.has(key):
		return _cache[key]
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0 or c.h < 0.02 or c.h > 0.16 or c.s < 0.3:
				continue
			img.set_pixel(x, y, _shift(c, coat))
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out


static func _shift(c: Color, coat: String) -> Color:
	match coat:
		"black":
			return Color.from_hsv(c.h, c.s * 0.25, c.v * 0.32 + 0.05, c.a)
		"chocolate", "brown":
			return Color.from_hsv(0.055, c.s * 0.8, c.v * 0.62, c.a)
		"cream", "white":
			return Color.from_hsv(0.1, c.s * 0.22, 0.74 + c.v * 0.24, c.a)
		"grey":
			return Color.from_hsv(0.6, c.s * 0.08, c.v * 0.82, c.a)
		"red":
			return Color.from_hsv(0.032, c.s * 0.92, c.v * 0.7, c.a)
	return c
