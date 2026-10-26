class_name Belly
## A woman expecting a child: her dress rounded out at the front, a little more each day. The bump is only drawn over
## her dress or empty air, so an arm or a basket held in front stays in front of it.

static var _cache := {}


## The picture with a bump of up to this many pixels; she faces right, so it grows out on the right.
static func round_out(tex: Texture2D, size: int) -> Texture2D:
	if size <= 0:
		return tex
	var key := "%s|%d" % [tex.resource_path, size]
	if _cache.has(key):
		return _cache[key]
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var used := img.get_used_rect()
	var top := int(used.position.y + used.size.y * 0.54)
	var bottom := int(used.position.y + used.size.y * 0.76)
	var src := img.duplicate() as Image
	var is_cloth := func(c: Color) -> bool: return c.a > 0.0 and (c.h < 0.05 or c.h > 0.95) and c.s > 0.35
	# Where the dress reaches furthest forward in these rows, and its colour there: the bump grows from that line as a
	# smooth half circle, rather than from each row's own edge, so it reads as one round belly.
	var fronts := {}
	var base := -1
	var cloth := Color()
	for y in range(top, bottom + 1):
		for x in range(used.end.x - 1, used.position.x - 1, -1):
			var c := src.get_pixel(x, y)
			if is_cloth.call(c):
				fronts[y] = x
				if x > base:
					base = x
					cloth = c
				break
	if base < 0:
		_cache[key] = tex
		return tex
	# The bump takes the dress's commonest colour here, not whatever shadow happens to lie at its edge.
	var counts := {}
	for y in range(top, bottom + 1):
		for x in range(used.position.x, used.end.x):
			var c := src.get_pixel(x, y)
			if is_cloth.call(c):
				counts[c.to_html()] = int(counts.get(c.to_html(), 0)) + 1
	var best := 0
	for html in counts:
		if int(counts[html]) > best:
			best = int(counts[html])
			cloth = Color.html(html)
	for y in range(top, bottom + 1):
		if not fronts.has(y):
			continue
		var t := float(y - top) / float(maxi(1, bottom - top))
		var reach := base + int(roundf(size * sqrt(maxf(0.0, sin(PI * t)))))
		var shade := cloth.darkened(0.12) if t > 0.6 else cloth
		for x in range(int(fronts[y]) + 1, mini(reach + 1, img.get_width())):
			var under := src.get_pixel(x, y)
			# An arm or a basket held in front stays in front of the belly.
			if under.a > 0.0 and not is_cloth.call(under):
				continue
			img.set_pixel(x, y, shade.darkened(0.2) if x == reach else shade)
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out
