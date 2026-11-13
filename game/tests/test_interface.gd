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


func test_small_screens_get_a_bigger_default_interface() -> void:
	var w: GDScript = load("res://scripts/autoload/windowing.gd")
	check(w.ui_scale_for(Vector2i(1280, 720), 0) == 2, "a 1280x720 window shows the interface at twice its size")
	check(w.ui_scale_for(Vector2i(1280, 800), 0) == 2, "and so does the Steam Deck's screen")
	check(w.ui_scale_for(Vector2i(1280, 800), -1) == 1, "where Smaller is still smaller")
	check(w.ui_scale_for(Vector2i(1920, 1080), 0) == 3, "a 1080p screen keeps its size")
	check(w.ui_scale_for(Vector2i(2560, 1440), 0) == 4, "and so does a 1440p screen")
	check(w.ui_scale_for(Vector2i(640, 400), 2) == 1, "the smallest window never outgrows its room")
