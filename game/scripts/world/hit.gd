class_name Hit
## Where an animated creature can be clicked: the visible pixels of the frame it is showing right now, so a dog lying
## down is low and wide and a dog standing is tall.

static var _used := {}


## The frame's visible area in the parent's coordinates, a little larger so it is easy to click.
static func frame_rect(owner: Node2D, s: AnimatedSprite2D) -> Rect2:
	var tex := s.sprite_frames.get_frame_texture(s.animation, s.frame)
	if tex == null:
		return Rect2()
	var key := tex.get_instance_id()
	if not _used.has(key):
		_used[key] = Rect2(tex.get_image().get_used_rect())
	var used: Rect2 = _used[key]
	var size := tex.get_size()
	var left := size.x - used.end.x if s.flip_h else used.position.x
	var origin := s.offset - (size / 2.0 if s.centered else Vector2.ZERO)
	return Rect2(owner.position + s.position + origin + Vector2(left, used.position.y), used.size).grow(2.0)
