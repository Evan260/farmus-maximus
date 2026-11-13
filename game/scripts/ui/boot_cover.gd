extends CanvasLayer
## The game's first frames repeat the boot splash, the logo on its background colour where Godot drew them, then fade
## into the title, so the start never jumps from the splash straight to the bright estate.

const SPLASH := preload("res://assets/splash/boot_splash.png")
const HOLD := 0.2
const FADE := 0.6


func _ready() -> void:
	layer = 100
	var cover := ColorRect.new()
	cover.color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color.BLACK)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	var logo := TextureRect.new()
	logo.texture = SPLASH
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(logo)
	# Godot centres the splash at its own size on whole pixels, so the logo here lands on the same pixels.
	var place := func(): logo.position = ((cover.size - SPLASH.get_size()) / 2.0).floor()
	cover.resized.connect(place)
	place.call()
	var fade := create_tween()
	fade.tween_interval(HOLD)
	fade.tween_property(cover, "modulate:a", 0.0, FADE)
	fade.tween_callback(queue_free)
