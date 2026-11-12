extends Node
## Tells whether the interface is worked with the keyboard or a gamepad, so its buttons take the focus only then.

## A key that moves through the buttons was pressed while none of them was chosen, or the keyboard was just picked up.
signal wanted(event: InputEvent)

const KEYS := ["ui_focus_next", "ui_focus_prev", "ui_left", "ui_right", "ui_up", "ui_down", "ui_accept"]

## True from the first Tab, arrow key, Enter or Space until the mouse is clicked.
var keyboard := false


## Whether buttons take the focus: while the keyboard is in use, or whenever a gamepad is connected.
func active() -> bool:
	return keyboard or not Input.get_connected_joypads().is_empty()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		keyboard = false
		_drop_button_focus.call_deferred()
	elif event is InputEventKey and event.pressed and KEYS.any(func(a: String) -> bool: return event.is_action_pressed(a, true)):
		var was := keyboard
		keyboard = true
		if not was or get_viewport().gui_get_focus_owner() == null:
			wanted.emit(event)


## A clicked button keeps no focus, so Space or Enter never presses a button the player cannot see is chosen.
func _drop_button_focus() -> void:
	if not Input.get_connected_joypads().is_empty():
		return
	var held := get_viewport().gui_get_focus_owner()
	if held is BaseButton:
		held.release_focus()
