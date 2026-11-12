extends "res://tests/test_case.gd"
## Checks of interface behaviour that needs no farm scene: achievement cards, the default interface size and the demo's
## wishlist button.


func test_an_achievement_waits_for_an_open_window() -> void:
	var popup: Control = load("res://scripts/ui/achievement_popup.gd").new()
	popup.theme = UiTheme.build()
	var windows := {"open": true}
	popup.window_open = func(): return windows["open"]
	root.add_child(popup)
	popup.add({"name": "First harvest", "desc": "Harvest a crop"})
	await create_timer(0.3).timeout
	check(popup._card == null, "a card earned with a window open waits rather than covering it")
	windows["open"] = false
	await create_timer(0.3).timeout
	check(popup._card != null, "and slides in once the window has closed")
	popup.free()
