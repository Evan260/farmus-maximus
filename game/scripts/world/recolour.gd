class_name Recolour
## Recolours pictures pixel by pixel and keeps each result, so a picture is worked out only once for each look.

static var _cache := {}


## The picture with `rule` applied to every visible pixel. The rule takes the colour and how far down the figure the
## pixel is (0 at the top, 1 at the feet) and returns the new colour; `look` names the result, such as "coat:black".
static func apply(tex: Texture2D, look: String, rule: Callable) -> Texture2D:
	var key := "%s|%s" % [tex.resource_path, look]
	if _cache.has(key):
		return _cache[key]
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var used := img.get_used_rect()
	for y in img.get_height():
		var down := float(y - used.position.y) / maxf(1.0, used.size.y)
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, rule.call(c, down))
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out
