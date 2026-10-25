extends Node2D
## The root of the estate inside its pixel-art viewport. Input reaches the estate here, already in estate pixels,
## and is handed to the scene script.

## Supplied by the scene: what to do with input that the interface did not use.
var on_input: Callable


func _unhandled_input(event: InputEvent) -> void:
	if on_input.is_valid():
		on_input.call(event)
