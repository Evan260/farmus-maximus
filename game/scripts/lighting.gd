class_name Lighting
## Colour of the light at each hour of the day; the scene is multiplied by it, so the painting stays as painted at midday.

const KEYS := [
	[0.0, Color(0.33, 0.37, 0.62)],
	[4.5, Color(0.33, 0.37, 0.62)],
	[6.0, Color(0.86, 0.72, 0.82)],
	[8.0, Color(1.0, 1.0, 1.0)],
	[16.5, Color(1.0, 1.0, 1.0)],
	[18.5, Color(0.95, 0.76, 0.74)],
	[20.0, Color(0.33, 0.37, 0.62)],
	[24.0, Color(0.33, 0.37, 0.62)],
]


static var _hours: Array = []
static var _colours: Array = []
static var _slopes: Array = []


static func color_at(hour: float) -> Color:
	if _slopes.is_empty():
		_hours = KEYS.map(func(k): return float(k[0]))
		_colours = KEYS.map(func(k): return k[1])
		_slopes = key_slopes(_hours, _colours)
	return eased(_hours, _colours, _slopes, hour)


## Each colour channel's slope at each key hour, for easing between keys: flat where the colour levels off or turns
## back, so dusk and dawn begin and end gently rather than all at once (a monotone cubic, after Fritsch and Carlson).
static func key_slopes(hours: Array, colours: Array) -> Array:
	var slopes := []
	for k in hours.size():
		var m := Color(0, 0, 0, 0)
		if k > 0 and k < hours.size() - 1:
			var before: float = hours[k] - hours[k - 1]
			var after: float = hours[k + 1] - hours[k]
			for c in 4:
				var d0: float = (colours[k][c] - colours[k - 1][c]) / before
				var d1: float = (colours[k + 1][c] - colours[k][c]) / after
				m[c] = 0.0 if d0 * d1 <= 0.0 else 3.0 * (before + after) / ((2.0 * after + before) / d0 + (after + 2.0 * before) / d1)
		slopes.append(m)
	return slopes


## The colour at `hour` between colour keys, eased through each key with the slopes from key_slopes.
static func eased(hours: Array, colours: Array, slopes: Array, hour: float) -> Color:
	for k in hours.size() - 1:
		if hour >= hours[k] and hour <= hours[k + 1]:
			var span: float = hours[k + 1] - hours[k]
			var t: float = (hour - hours[k]) / span
			var t2 := t * t
			var t3 := t2 * t
			var start := (colours[k] as Color) * (2.0 * t3 - 3.0 * t2 + 1.0) + (slopes[k] as Color) * (span * (t3 - 2.0 * t2 + t))
			return start + (colours[k + 1] as Color) * (3.0 * t2 - 2.0 * t3) + (slopes[k + 1] as Color) * (span * (t3 - t2))
	return colours[0]


## 0 in daylight, 1 in full night; used for fireflies, lamps and when the dog prefers to sleep.
static func night_amount(hour: float) -> float:
	var c := color_at(hour)
	return clampf((1.0 - c.g) / (1.0 - 0.37), 0.0, 1.0)


## Shadows of one size and colour share one picture.
static var _ellipses := {}


static func ellipse_texture(w: int, h: int, color: Color) -> ImageTexture:
	var key := "%d %d %s" % [w, h, color]
	if _ellipses.has(key):
		return _ellipses[key]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		for y in h:
			if pow((x - w / 2.0 + 0.5) / (w / 2.0), 2) + pow((y - h / 2.0 + 0.5) / (h / 2.0), 2) <= 1.0:
				img.set_pixel(x, y, color)
	_ellipses[key] = ImageTexture.create_from_image(img)
	return _ellipses[key]


static func heart_texture() -> ImageTexture:
	var rows := [".X.X.", "XXXXX", "XXXXX", ".XXX.", "..X.."]
	var img := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 5:
			if rows[y][x] == "X":
				img.set_pixel(x, y, Color(0.93, 0.36, 0.45))
	return ImageTexture.create_from_image(img)
