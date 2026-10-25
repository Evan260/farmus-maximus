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


static func color_at(hour: float) -> Color:
	for k in range(KEYS.size() - 1):
		var a: Array = KEYS[k]
		var b: Array = KEYS[k + 1]
		if hour >= a[0] and hour <= b[0]:
			return (a[1] as Color).lerp(b[1], (hour - a[0]) / (b[0] - a[0]))
	return KEYS[0][1]


## 0 in daylight, 1 in full night; used for fireflies, lamps and when the dog prefers to sleep.
static func night_amount(hour: float) -> float:
	var c := color_at(hour)
	return clampf((1.0 - c.g) / (1.0 - 0.37), 0.0, 1.0)


static func ellipse_texture(w: int, h: int, color: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		for y in h:
			if pow((x - w / 2.0 + 0.5) / (w / 2.0), 2) + pow((y - h / 2.0 + 0.5) / (h / 2.0), 2) <= 1.0:
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)


static func heart_texture() -> ImageTexture:
	var rows := [".X.X.", "XXXXX", "XXXXX", ".XXX.", "..X.."]
	var img := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 5:
			if rows[y][x] == "X":
				img.set_pixel(x, y, Color(0.93, 0.36, 0.45))
	return ImageTexture.create_from_image(img)
