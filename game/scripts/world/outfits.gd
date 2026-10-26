class_name Outfits
## Builders in different clothes: the same drawings with the tunic, cap, apron and skin recoloured, so a team of
## builders does not look like one man copied. Each picture is recoloured once per outfit and kept.

## Each outfit names the hue and saturation for the tunic, cap and apron, and a brightness for the skin; a missing
## part keeps its drawn colour.
const OUTFITS := [
	{},
	{"tunic": Vector2(0.6, 0.28), "cap": Vector2(0.03, 0.55), "skin": 0.72},
	{"tunic": Vector2(0.22, 0.32), "apron": Vector2(0.06, 0.45)},
	{"tunic": Vector2(0.0, 0.38), "cap": Vector2(0.08, 0.45), "skin": 1.05},
]


static func dress(tex: Texture2D, outfit: int) -> Texture2D:
	var look: Dictionary = OUTFITS[outfit % OUTFITS.size()]
	if look.is_empty():
		return tex
	return Recolour.apply(tex, "outfit:%d" % outfit, func(c: Color, down: float) -> Color:
		return _dress_pixel(c, down, look))


static func _dress_pixel(c: Color, down: float, look: Dictionary) -> Color:
	if c.s < 0.18 and c.v > 0.4 and c.v < 0.8 and look.has("tunic"):
		c = Color.from_hsv(look["tunic"].x, look["tunic"].y, c.v * 0.95, c.a)
	# The cap is the pale cloth in the top third of the figure; lower down the same colours are the tunic's trim.
	elif c.s > 0.2 and c.s < 0.42 and c.v > 0.68 and down < 0.3 and look.has("cap"):
		c = Color.from_hsv(look["cap"].x, look["cap"].y, c.v * 0.8, c.a)
	elif c.s >= 0.45 and c.v > 0.78 and look.has("skin"):
		c = Color.from_hsv(c.h, c.s, clampf(c.v * float(look["skin"]), 0.0, 1.0), c.a)
	elif c.s > 0.55 and c.v < 0.58 and look.has("apron"):
		c = Color.from_hsv(look["apron"].x, look["apron"].y, c.v * 0.85, c.a)
	return c
