class_name Rise
## Scaffolding going up: the new look of a sprite is uncovered from the ground upwards over the old one, row by row.


## The sprite already shows its new look; the old look stays underneath until the new one has risen over it.
static func reveal(sprite: Sprite2D, old_texture: Texture2D, old_region: Rect2, old_position: Vector2, seconds := 2.0) -> void:
	var under := Sprite2D.new()
	under.centered = false
	under.region_enabled = true
	under.texture = old_texture
	under.region_rect = old_region
	under.position = old_position
	sprite.get_parent().add_child(under)
	sprite.get_parent().move_child(under, sprite.get_index())
	var full := sprite.region_rect
	var top := sprite.position.y
	var grow := func(share: float) -> void:
		var h := roundf(full.size.y * share)
		sprite.region_rect = Rect2(full.position.x, full.end.y - h, full.size.x, h)
		sprite.position.y = top + full.size.y - h
	grow.call(0.0)
	var tween := sprite.create_tween()
	tween.tween_method(grow, 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(under.queue_free)
