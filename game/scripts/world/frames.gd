class_name Frames
## Animations built from folders of numbered pictures (frame_00.png, frame_01.png, ...), and where a figure's feet are.


## Adds an animation of every numbered picture in a folder from `first` on, each passed through `look` when one is
## given; returns how many pictures it added, 0 when the folder has none.
static func add_folder(f: SpriteFrames, anim: String, folder: String, fps: float, loop := true, look := Callable(), first := 0) -> int:
	if not ResourceLoader.exists("%sframe_%02d.png" % [folder, first]):
		return 0
	if not f.has_animation(anim):
		f.add_animation(anim)
	f.set_animation_speed(anim, fps)
	f.set_animation_loop(anim, loop)
	var i := first
	while ResourceLoader.exists("%sframe_%02d.png" % [folder, i]):
		var tex: Texture2D = load("%sframe_%02d.png" % [folder, i])
		f.add_frame(anim, look.call(tex) if look.is_valid() else tex)
		i += 1
	return i - first


## The row just below the lowest drawn pixel, where the figure stands.
static func feet_line(tex: Texture2D) -> int:
	return Hit.used_rect(tex).end.y


## The offset that stands a figure's feet on its node's position, centred across, whatever the picture's size.
static func anchor(tex: Texture2D) -> Vector2:
	return Vector2(-roundf(tex.get_width() / 2.0), -feet_line(tex))
