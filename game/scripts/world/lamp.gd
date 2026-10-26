class_name Lamp
extends Node2D
## A warm light for the night: it brightens the walls and ground around it, and can have a soft halo of its own on
## the glow layer, which the night tint does not darken. Its owner sets how brightly it burns.

const SIZE := 64

static var _light_tex: Texture2D
static var _halo_tex: Texture2D

var radius := 40.0
var colour := Color(1.0, 0.7, 0.36)
## How strong the light is when fully lit.
var power := 1.0
## Where the halo goes; without one the lamp only lights its surroundings.
var halo_layer: Node
var halo_size := 14.0
var _light: PointLight2D
var _halo: Sprite2D


func _ready() -> void:
	_light = PointLight2D.new()
	_light.texture = _light_texture()
	_light.texture_scale = radius * 2.0 / SIZE
	_light.color = colour
	_light.energy = 0.0
	_light.visible = false
	add_child(_light)
	if halo_layer:
		_halo = Sprite2D.new()
		_halo.texture = _halo_texture()
		_halo.scale = Vector2.ONE * halo_size * 2.0 / SIZE
		_halo.modulate = Color(colour, 0.0)
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_halo.material = add
		halo_layer.add_child(_halo)
		_halo.global_position = global_position


func _exit_tree() -> void:
	if _halo:
		_halo.queue_free()


## 0 is out, 1 is fully lit.
func shine(amount: float) -> void:
	if _light == null:
		return
	_light.visible = amount > 0.01
	_light.energy = amount * power
	if _halo:
		_halo.global_position = global_position
		_halo.modulate.a = amount * 0.55


## A round light that fades smoothly from the middle to nothing at its edge.
static func _light_texture() -> Texture2D:
	if _light_tex == null:
		_light_tex = _radial([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)], [0.0, 0.3, 0.65, 1.0])
	return _light_tex


static func _halo_texture() -> Texture2D:
	if _halo_tex == null:
		_halo_tex = _radial([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)], [0.0, 0.35, 1.0])
	return _halo_tex


static func _radial(colours: Array, offsets: Array) -> Texture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray(colours)
	g.offsets = PackedFloat32Array(offsets)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = SIZE
	t.height = SIZE
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
