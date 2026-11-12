extends "res://tests/test_case.gd"
## The settings live in one settings.cfg, made once from the three files they were kept in before.

const DIR := "user://test_settings"


func _write(name: String, data: Dictionary) -> void:
	var f := FileAccess.open(DIR.path_join(name), FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()


func _clear() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR.path_join(f)))


func test_old_settings_files_become_one() -> void:
	var settings: Node = root.get_node("Settings")
	var persist: bool = settings.persist
	_clear()
	_write("prefs.json", {"large_text": true, "day_minutes": 30, "ui_scale_step": 0, "ui_sizes": 2, "language": "de", "keys": {"open_journal": KEY_K}})
	_write("settings.json", {"volumes": {"Music": 0.3, "Master": 0.5}})
	_write("window.json", {"dock": "top", "strip_scale": 3})
	settings.persist = true
	settings.load_from(DIR)
	check(settings.large_text and settings.day_minutes == 30 and settings.ui_scale_step == 0 and settings.language == "de",
		"the old preferences carry over")
	check(settings.keys.get("open_journal", 0) == KEY_K, "and so do the player's keys")
	var cfg := ConfigFile.new()
	check(cfg.load(DIR.path_join("settings.cfg")) == OK, "settings.cfg is written once they have")
	check(is_equal_approx(float(cfg.get_value("sound", "music", 0.0)), 0.3) and is_equal_approx(float(cfg.get_value("sound", "master", 0.0)), 0.5),
		"the volumes move into it")
	check(cfg.get_value("window", "dock", "") == "top" and int(cfg.get_value("window", "strip_scale", 0)) == 3, "and the strip's settings")
	_write("prefs.json", {"large_text": false})
	settings.load_from(DIR)
	check(settings.large_text, "once settings.cfg exists the old files are no longer read")
	_write("prefs.json", {"ui_scale_step": 1})
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR.path_join("settings.cfg")))
	settings.load_from(DIR)
	check(settings.ui_scale_step == 2, "an interface size saved before Normal became smaller keeps its size on screen")
	settings.persist = false
	_clear()
	settings.load_from(DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR))
	settings.folder = "user://"
	settings.persist = persist
	check(not settings.large_text and settings.keys.is_empty(), "the tests go back to the game's own settings")


func test_keys_are_named_as_this_keyboard_names_them() -> void:
	var settings: Node = root.get_node("Settings")
	var panel: Node = load("res://scripts/ui/settings_panel.gd").new()
	for action in settings.ACTIONS:
		var code: int = settings.key_for(action)
		var shown: String = panel._key_name(action)
		var named := code if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(code)
		check(shown != "" and shown == OS.get_keycode_string(named), "%s is named %s, as the key on this layout" % [action, shown])
	panel.free()


func test_focus_mode_slows_only_the_strip() -> void:
	var windowing: Node = root.get_node("Windowing")
	var settings: Node = root.get_node("Settings")
	var was := [windowing.strip, windowing.focus_mode, windowing._focused, settings.low_power]
	windowing.strip = false
	windowing.focus_mode = true
	windowing._focused = true
	settings.low_power = true
	var fps: int = windowing.fps_for(false)
	check(fps == 30, "low power with the strip's focus mode left on runs the full window at 30 fps (%d)" % fps)
	windowing.strip = was[0]
	windowing.focus_mode = was[1]
	windowing._focused = was[2]
	settings.low_power = was[3]
