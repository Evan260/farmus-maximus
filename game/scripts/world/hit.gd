class_name Hit
## Where an animated creature can be clicked: the visible pixels of the frame it is showing right now, so a dog lying
## down is low and wide and a dog standing is tall.

static var _used := {}
static var _images := {}


## The frame's visible area in the parent's coordinates, a little larger so it is easy to click.
static func frame_rect(owner: Node2D, s: AnimatedSprite2D) -> Rect2:
	var tex := s.sprite_frames.get_frame_texture(s.animation, s.frame)
	if tex == null:
		return Rect2()
	var used := Rect2(used_rect(tex))
	var size := tex.get_size()
	var left := size.x - used.end.x if s.flip_h else used.position.x
	var origin := s.offset - (size / 2.0 if s.centered else Vector2.ZERO)
	return Rect2(_base(owner, s) + origin + Vector2(left, used.position.y), used.size).grow(2.0)


## The picture's visible area, worked out once for each picture since reading a picture's pixels back is slow.
static func used_rect(tex: Texture2D) -> Rect2i:
	var key := tex.get_instance_id()
	if not _used.has(key):
		_used[key] = tex.get_image().get_used_rect()
	return _used[key]


## True only on the frame's own pixels, so a click just past an animal's outline goes to whatever is behind it.
static func frame_has_pixel(owner: Node2D, s: AnimatedSprite2D, point: Vector2) -> bool:
	var tex := s.sprite_frames.get_frame_texture(s.animation, s.frame)
	if tex == null:
		return false
	var origin := s.offset - (tex.get_size() / 2.0 if s.centered else Vector2.ZERO)
	return texture_has_pixel(tex, _base(owner, s) + origin, point, s.flip_h)


## True only on a picture's own pixels, for a picture drawn with its top-left corner at `corner`.
static func texture_has_pixel(tex: Texture2D, corner: Vector2, point: Vector2, flip := false) -> bool:
	if tex == null:
		return false
	var key := tex.get_instance_id()
	if not _images.has(key):
		_images[key] = tex.get_image()
	var img: Image = _images[key]
	var size := tex.get_size()
	var local := (point - corner).floor()
	if flip:
		local.x = size.x - 1 - local.x
	if local.x < 0 or local.y < 0 or local.x >= size.x or local.y >= size.y:
		return false
	return img.get_pixelv(Vector2i(local)).a > 0.1


## Where a sprite stands in its owner's parent; a sprite that stands alone is its own owner and counts its position once.
static func _base(owner: Node2D, s: AnimatedSprite2D) -> Vector2:
	return owner.position + (s.position if s != owner else Vector2.ZERO)


## Of the figures whose pictures cover a point, the one drawn in front: someone whose own pixels are under the pointer
## beats someone whose picture merely has an empty corner there, and among those the one drawn last is on top.
static func front_most(figures: Array, point: Vector2) -> Node2D:
	if figures.is_empty():
		return null
	var solid := figures.filter(func(f): return frame_has_pixel(f, f.sprite, point))
	var pool := solid if not solid.is_empty() else figures
	var front: Node2D = pool[0]
	for f in pool:
		if f.is_greater_than(front):
			front = f
	return front
