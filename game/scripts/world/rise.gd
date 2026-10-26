class_name Rise
## Scaffolding coming up out of the ground and going back down into it. Only the part above the ground line is
## shown, so the picture looks pushed up from below or lowered away, top last.


## The sprite already shows its new look (the scaffold), which climbs up out of the ground over the old look.
static func rise(sprite: Sprite2D, old_texture: Texture2D, old_region: Rect2, old_position: Vector2, seconds := 2.0) -> void:
	var under := _copy(sprite, old_texture, old_region, old_position)
	sprite.get_parent().move_child(under, sprite.get_index())
	var tween := _slide(sprite, sprite.region_rect, sprite.position.y, 0.0, 1.0, seconds)
	tween.tween_callback(under.queue_free)


## The sprite already shows its new look (the finished building); the old look (the scaffold) sinks into the ground
## in front of it.
static func sink(sprite: Sprite2D, old_texture: Texture2D, old_region: Rect2, old_position: Vector2, seconds := 2.0) -> void:
	var over := _copy(sprite, old_texture, old_region, old_position)
	sprite.get_parent().move_child(over, sprite.get_index() + 1)
	var tween := _slide(over, old_region, old_position.y, 1.0, 0.0, seconds)
	tween.tween_callback(over.queue_free)


static func _copy(sprite: Sprite2D, texture: Texture2D, region: Rect2, at: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.region_enabled = true
	s.texture = texture
	s.region_rect = region
	s.position = at
	sprite.get_parent().add_child(s)
	return s


## Shows only the top rows of the picture, as many as have come up out of the ground, standing on the ground line.
static func _slide(s: Sprite2D, full: Rect2, top: float, from: float, to: float, seconds: float) -> Tween:
	var show := func(share: float) -> void:
		var h := roundf(full.size.y * share)
		s.region_rect = Rect2(full.position.x, full.position.y, full.size.x, h)
		s.position.y = top + full.size.y - h
	show.call(from)
	var tween := s.create_tween()
	tween.tween_method(show, from, to, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween
