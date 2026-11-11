class_name Coats
## Coat colours for the dog and the cat. Only each breed's own fur colours change, so collars, eyes and pale markings
## stay as drawn, and every animation frame is recoloured the same way.

const DOG := {"golden": "Golden", "black": "Black", "chocolate": "Chocolate", "cream": "Cream", "grey": "Grey", "red": "Red"}
## Every dog breed's coats; the first is the look its pictures are drawn in, and "natural" keeps that id for old saves.
const DOG_COATS := {
	"hound": DOG,
	"molossian": {"natural": "Brown", "fawn": "Fawn", "grey": "Grey", "black": "Black"},
	"sighthound": {"natural": "Fawn", "black": "Black and white", "grey": "Grey and white"},
	"lapdog": {"natural": "White", "apricot": "Apricot", "grey": "Grey", "black": "Black"},
	"sheepdog": {"natural": "Grey and white", "black": "Black and white", "brown": "Brown and white"},
}
const CAT := {"ginger": "Ginger tabby", "grey": "Grey tabby", "black": "Black", "white": "White", "brown": "Brown tabby"}
## Hens and goats come in a few looks too, chosen at random so a flock is not all alike.
const HEN := ["brown", "white", "black", "blue", "ginger"]
const GOAT := ["patched", "white", "dark_patched", "grey_patched", "black"]

## Breeds, each its own shape and build; the first of each is the one the coat colours were made for.
const BREEDS := {
	"dog": {"hound": "Farm hound", "molossian": "Mastiff", "sighthound": "Sighthound", "lapdog": "Lapdog", "sheepdog": "Sheepdog"},
	"cat": {"tabby": "Tabby", "longhair": "Long-haired", "spotted": "Spotted", "stocky": "Stocky"},
}


## The coats a pet can wear: every dog breed comes in several, the tabby too, and the other cats in their own colours.
static func options(animal: String, breed := "") -> Dictionary:
	if animal == "dog":
		return DOG_COATS.get(breed, DOG)
	if breed != "" and breed != BREEDS[animal].keys()[0]:
		return {"natural": "Natural coat"}
	return CAT


## The folder holding a breed's pictures.
static func breed_dir(animal: String, breed: String) -> String:
	if animal == "dog":
		return "res://assets/sprites/dog/" if breed in ["", "hound"] or not BREEDS["dog"].has(breed) else "res://assets/sprites/dog_breeds/%s/" % breed
	return "res://assets/sprites/animals/cat_small/" if breed in ["", "tabby"] or not BREEDS["cat"].has(breed) else "res://assets/sprites/animals/cat_breeds/%s/small/" % breed


static func recolour(tex: Texture2D, animal: String, coat: String, breed := "") -> Texture2D:
	if animal in ["hen", "goat"]:
		return _recolour_livestock(tex, animal, coat)
	if animal == "dog" and breed in DOG_COATS and breed != "hound":
		if coat == "natural" or not DOG_COATS[breed].has(coat):
			return tex
		return Recolour.apply(tex, "coat:%s:%s" % [breed, coat], func(c: Color, _down: float) -> Color:
			return breed_pixel(breed, coat, c))
	if coat in ["", "natural"] or coat == options(animal).keys()[0]:
		return tex
	return Recolour.apply(tex, "coat:" + coat, func(c: Color, _down: float) -> Color:
		return c if c.h < 0.02 or c.h > 0.16 or c.s < 0.3 else _shift(c, coat))


## One pixel of a dog breed other than the farm hound in one of its coats, from that breed's own fur colours.
static func breed_pixel(breed: String, coat: String, c: Color) -> Color:
	match breed:
		"molossian":
			if c.h < 0.04 or c.h > 0.12:
				return c
			# The low, dark pixels are the black mask and outline, which stay dark in every coat.
			var body := c.s >= 0.27 and c.v >= 0.32
			match coat:
				"fawn":
					if body: return Color.from_hsv(0.095, c.s * 0.95, minf(1.0, c.v * 1.4), c.a)
				"grey":
					return Color.from_hsv(0.6, 0.07 if body else 0.06, c.v * (0.92 if body else 1.0), c.a)
				"black":
					if body: return Color.from_hsv(0.07, 0.2, c.v * 0.42 + 0.05, c.a)
		"sighthound":
			# The olive tinge on its tail is part of the coat too.
			if c.h < 0.02 or c.h > 0.2:
				return c
			if c.s >= 0.4 or (c.s >= 0.3 and c.v < 0.45):
				match coat:
					"black": return Color.from_hsv(c.h, c.s * 0.25, c.v * 0.32 + 0.05, c.a)
					"grey": return Color.from_hsv(0.6, c.s * 0.08, c.v * 0.82, c.a)
			elif c.v >= 0.6:
				# Its pale muzzle, chest and feet turn white beside a dark coat.
				return Color.from_hsv(0.1, c.s * 0.4, minf(1.0, c.v * 1.03), c.a)
		"lapdog":
			var fur := (c.h >= 0.05 and c.h <= 0.13 and c.s < 0.4) or (c.s < 0.05 and c.v > 0.95)
			if not fur:
				return c
			match coat:
				"apricot": return Color.from_hsv(0.075, minf(1.0, c.s * 1.6 + 0.2), c.v * 0.96, c.a)
				"grey": return Color.from_hsv(0.6, 0.05, c.v * 0.75, c.a)
				"black": return Color.from_hsv(0.62, 0.1, 0.07 + c.v * 0.3, c.a)
		"sheepdog":
			# Only the grey fur changes; its white coat stays white.
			if c.h < 0.04 or c.h > 0.13 or c.s >= 0.2 or c.v > 0.66:
				return c
			match coat:
				"black": return Color.from_hsv(0.62, 0.1, 0.06 + c.v * 0.38, c.a)
				"brown": return Color.from_hsv(0.06, 0.5, c.v * 0.78, c.a)
	return c


## Hens change only their brown feathers, so the red comb and yellow beak and legs stay; goats change their brown
## patches, and a black goat its pale coat too.
static func _recolour_livestock(tex: Texture2D, animal: String, coat: String) -> Texture2D:
	if coat == "" or coat == (HEN if animal == "hen" else GOAT)[0]:
		return tex
	return Recolour.apply(tex, "%s:%s" % [animal, coat], func(c: Color, _down: float) -> Color:
		return _livestock_pixel(c, animal, coat))


static func _livestock_pixel(c: Color, animal: String, coat: String) -> Color:
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
