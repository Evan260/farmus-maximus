class_name Dissolve
## Going between the estate and the market town: the old screen breaks away in pixel blocks over the new one.

const SHADER := preload("res://assets/shaders/dissolve.gdshader")


## Calls change to swap the screens, then dissolves a picture of how things looked before it away.
static func play(host: Node, change: Callable, seconds := 0.6) -> void:
	# A headless run draws nothing, so it has no picture of the old screen to dissolve.
	if Settings.reduced_motion or DisplayServer.get_name() == "headless":
		change.call()
		return
	var shot := ImageTexture.create_from_image(host.get_viewport().get_texture().get_image())
	var layer := CanvasLayer.new()
	layer.layer = 50
	host.get_tree().root.add_child(layer)
	var picture := TextureRect.new()
	picture.texture = shot
	picture.size = host.get_viewport().get_visible_rect().size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := ShaderMaterial.new()
	look.shader = SHADER
	look.set_shader_parameter("cell", 2.0 * Windowing.scale)
	picture.material = look
	layer.add_child(picture)
	change.call()
	var tween := layer.create_tween()
	tween.tween_method(func(p: float) -> void: look.set_shader_parameter("progress", p), 0.0, 1.0, seconds)
	tween.tween_callback(layer.queue_free)
