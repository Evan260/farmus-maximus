extends Node2D
## Rain and morning mist, drawn over the whole view on their own layer so they stay put while the estate pans.

var _drops: Array = []
var _rain := 0.0
var _mist := 0.0
var _t := 0.0
var _fog: ColorRect


func _ready() -> void:
	_fog = ColorRect.new()
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := ShaderMaterial.new()
	look.shader = preload("res://assets/shaders/mist.gdshader")
	_fog.material = look
	_fog.visible = false
	add_child(_fog)
	for i in 140:
		_drops.append(Vector2(randf_range(0, 520), randf_range(0, 270)))


func _process(delta: float) -> void:
	_t += delta
	_rain = move_toward(_rain, 1.0 if Game.calendar.raining() else 0.0, delta / 4.0)
	_mist = move_toward(_mist, 1.0 if Game.calendar.weather == "mist" else 0.0, delta / 8.0)
	var size := get_viewport_rect().size
	_fog.visible = _mist > 0.01
	if _fog.visible:
		var look := _fog.material as ShaderMaterial
		var camera := get_viewport().get_camera_2d()
		_fog.size = size
		look.set_shader_parameter("amount", _mist)
		look.set_shader_parameter("view_size", size)
		look.set_shader_parameter("camera", camera.position if camera else Vector2.ZERO)
		# The mist takes on the colour of the light, rosy at dawn and white by mid morning.
		look.set_shader_parameter("tint", Color(0.95, 0.95, 0.98).lerp(Lighting.color_at(Game.day_time), 0.45))
		look.set_shader_parameter("motion", 0.3 if Settings.reduced_motion else 1.0)
	var fall := Vector2(-18, 150) * (0.3 if Settings.reduced_motion else 1.0)
	for i in _drops.size():
		var d: Vector2 = _drops[i] + fall * delta
		# Carrying on from the top by the overshoot keeps the drops spread out even after one very long frame.
		if d.y > size.y:
			d = Vector2(randf_range(0, size.x + 40), fposmod(d.y + 4.0, size.y + 4.0) - 4.0)
		_drops[i] = d
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	if _rain > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.4, 0.5, 0.12 * _rain))
		var shown := int(_drops.size() * _rain)
		for i in shown:
			var d: Vector2 = _drops[i].round()
			# Each drop is a short slanted streak of single pixels, which stays crisp at any scale.
			var c := Color(0.85, 0.9, 1.0, 0.45)
			draw_rect(Rect2(d, Vector2(1, 2)), c)
			draw_rect(Rect2(d + Vector2(-1, 2), Vector2(1, 2)), c)
