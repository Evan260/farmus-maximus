class_name Coats
## Coat colours for the dog and the cat. Only the fur's warm brown and ginger pixels change, so collars, eyes and the
## pale chest stay as drawn, and every animation frame is recoloured the same way.

const DOG := {"golden": "Golden", "black": "Black", "chocolate": "Chocolate", "cream": "Cream", "grey": "Grey", "red": "Red"}
const CAT := {"ginger": "Ginger tabby", "grey": "Grey tabby", "black": "Black", "white": "White", "brown": "Brown tabby"}
## Hens and goats come in a few looks too, chosen at random so a flock is not all alike.
const HEN := ["brown", "white", "black", "blue", "ginger"]
const GOAT := ["patched", "white", "dark_patched", "grey_patched", "black"]

## Breeds, each its own shape and build; the first of each is the one the coat colours were made for.
const BREEDS := {
	"dog": {"hound": "Farm hound", "molossian": "Molossian mastiff", "sighthound": "Sighthound", "lapdog": "Melitan lapdog", "sheepdog": "Sheepdog"},
	"cat": {"tabby": "Tabby", "longhair": "Long-haired", "spotted": "Spotted", "stocky": "Stocky"},
}

static var _cache := {}


## The coats a pet can wear: the farm hound and the tabby come in several, the other breeds in their own colours.
static func options(animal: String, breed := "") -> Dictionary:
	if breed != "" and breed != BREEDS[animal].keys()[0]:
		return {"natural": "Natural coat"}
	return DOG if animal == "dog" else CAT


## The folder holding a breed's pictures.
static func breed_dir(animal: String, breed: String) -> String:
	if animal == "dog":
		return "res://assets/sprites/dog/" if breed in ["", "hound"] or not BREEDS["dog"].has(breed) else "res://assets/sprites/dog_breeds/%s/" % breed
	return "res://assets/sprites/animals/cat_small/" if breed in ["", "tabby"] or not BREEDS["cat"].has(breed) else "res://assets/sprites/animals/cat_breeds/%s/small/" % breed


static func recolour(tex: Texture2D, animal: String, coat: String) -> Texture2D:
	if animal in ["hen", "goat"]:
		return _recolour_livestock(tex, animal, coat)
	if coat in ["", "natural"] or coat == options(animal).keys()[0]:
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


## Hens change only their brown feathers, so the red comb and yellow beak and legs stay; goats change their brown
## patches, and a black goat its pale coat too.
static func _recolour_livestock(tex: Texture2D, animal: String, coat: String) -> Texture2D:
	if coat == "" or coat == (HEN if animal == "hen" else GOAT)[0]:
		return tex
	var key := "%s|%s|%s" % [tex.resource_path, animal, coat]
	if _cache.has(key):
		return _cache[key]
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var out := c
			if animal == "hen" and c.h > 0.045 and c.h < 0.095 and c.s > 0.45:
				match coat:
					"white": out = Color.from_hsv(0.11, c.s * 0.12, 0.78 + c.v * 0.2, c.a)
					"black": out = Color.from_hsv(0.62, 0.18, c.v * 0.3 + 0.06, c.a)
					"blue": out = Color.from_hsv(0.6, 0.14, c.v * 0.62 + 0.08, c.a)
					"ginger": out = Color.from_hsv(0.055, minf(1.0, c.s * 1.1), minf(1.0, c.v * 1.08), c.a)
			elif animal == "goat":
				var patch := c.h > 0.05 and c.h < 0.1 and c.s > 0.45
				var pale := c.s < 0.36 and c.v > 0.68
				match coat:
					"white":
						if patch: out = Color.from_hsv(0.1, 0.18, 0.72 + c.v * 0.25, c.a)
					"dark_patched":
						if patch: out = Color.from_hsv(0.07, 0.35, c.v * 0.35, c.a)
					"grey_patched":
						if patch: out = Color.from_hsv(0.6, 0.06, c.v * 0.85, c.a)
					"black":
						if patch: out = Color.from_hsv(0.07, 0.3, c.v * 0.3, c.a)
						elif pale: out = Color.from_hsv(0.08, 0.2, c.v * 0.32 + 0.05, c.a)
			img.set_pixel(x, y, out)
	var tex_out := ImageTexture.create_from_image(img)
	_cache[key] = tex_out
	return tex_out


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
