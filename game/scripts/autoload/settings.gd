extends Node
## Player preferences that belong to this computer rather than to the farm: accessibility, notifications, language and key bindings.

signal changed

const PATH := "user://prefs.json"
## Every rebindable action with its default key, and the gamepad button that also does it.
const ACTIONS := {
	"pan_left": {"name": "Scroll left", "key": KEY_A, "pad": -1},
	"pan_right": {"name": "Scroll right", "key": KEY_D, "pad": -1},
	"prev_zone": {"name": "Previous zone", "key": KEY_Q, "pad": JOY_BUTTON_LEFT_SHOULDER},
	"next_zone": {"name": "Next zone", "key": KEY_E, "pad": JOY_BUTTON_RIGHT_SHOULDER},
	"open_journal": {"name": "Journal", "key": KEY_J, "pad": JOY_BUTTON_Y},
	"open_market": {"name": "Market town", "key": KEY_M, "pad": JOY_BUTTON_X},
	"close_panel": {"name": "Close panel", "key": KEY_ESCAPE, "pad": JOY_BUTTON_B},
	"dig_up": {"name": "Dig up a plant", "key": KEY_X, "pad": JOY_BUTTON_RIGHT_STICK},
	"toggle_strip": {"name": "Desktop strip", "key": KEY_F10, "pad": -1},
	"reset_strip": {"name": "Re-centre the strip", "key": KEY_F9, "pad": -1},
}

var offline_progress := true
var notifications := true
var large_text := false
var reduced_motion := false
## Whether the full window fills the screen; F11 changes it.
var fullscreen := false
## Ready plants get a clear marker above them, not just a twinkle, for players who find the twinkle hard to see.
var strong_cues := false
var low_power := false
## How loud the game is while another window has the focus: "full", "quieter" or "muted".
var background_sound := "full"
## A language code such as "fr" or "zh_CN"; empty until chosen, when the computer's own language is used if the game has it.
var language := ""
## Whether the game opens on the title screen; players who want straight in can turn it off.
var show_title := true
## How much bigger or smaller than the estate the interface is drawn, in whole steps.
var ui_scale_step := 0
## Minutes in one in-game day.
var day_minutes := 20
var show_tutorial := true
var keys := {}
## Off for trial runs (see trial_run), which never write the player's preferences, volumes or window settings.
var persist := true


func _ready() -> void:
	persist = not trial_run()
	_load()
	if "--new-farm" in OS.get_cmdline_user_args():
		show_tutorial = true
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var pad := int(ACTIONS[action]["pad"])
		if pad >= 0:
			var ev := InputEventJoypadButton.new()
			ev.button_index = pad
			InputMap.action_add_event(action, ev)
		_bind(action, int(keys.get(action, ACTIONS[action]["key"])))
	_load_translations()
	TranslationServer.set_locale(language if language != "" else _system_language())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--locale="):
			TranslationServer.set_locale(arg.trim_prefix("--locale="))


## Every language column of the strings sheet becomes a translation file when imported; all of them are loaded.
func _load_translations() -> void:
	for file in ResourceLoader.list_directory("res://translations/"):
		if file.get_extension() == "translation":
			var t: Translation = load("res://translations/" + file)
			# A language column still waiting for its translations is not offered yet; the compressed translation files
			# cannot count their lines, so it is judged by whether the word for the language list itself is there.
			if t.locale == "en" or t.get_message("Language") != "":
				TranslationServer.add_translation(t)


## The computer's own language if the game has it, matching "fr_CA" to "fr" and "zh_Hans_CN" to "zh_CN"; otherwise English.
func _system_language() -> String:
	var have := TranslationServer.get_loaded_locales()
	var os := OS.get_locale()
	if os in have:
		return os
	if os.begins_with("zh"):
		var traditional := os.contains("Hant") or os.ends_with("TW") or os.ends_with("HK") or os.ends_with("MO")
		var zh := "zh_TW" if traditional else "zh_CN"
		return zh if zh in have else "en"
	var lang := OS.get_locale_language()
	for loc in have:
		if loc.get_slice("_", 0) == lang:
			return loc
	return "en"


## Demo farms, new-farm trials, read-only checks and tests, which leave the player's farms and settings as they were.
func trial_run() -> bool:
	for arg in OS.get_cmdline_args():
		if String(arg).begins_with("res://tests/"):
			return true
	for flag in ["--demo", "--new-farm", "--readonly"]:
		if flag in OS.get_cmdline_user_args():
			return true
	return false


func key_for(action: String) -> int:
	return int(keys.get(action, ACTIONS[action]["key"]))


func rebind(action: String, keycode: int) -> void:
	keys[action] = keycode
	_bind(action, keycode)
	save()


func set_value(name: String, value: Variant) -> void:
	set(name, value)
	save()
	if name == "language":
		TranslationServer.set_locale(String(value))
		# The interface's font depends on the language, so the scene is rebuilt around the new one.
		Saves.save_game()
		get_tree().reload_current_scene()
		return
	changed.emit()


func _bind(action: String, keycode: int) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	InputMap.action_add_event(action, key)


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	for name in ["offline_progress", "notifications", "large_text", "reduced_motion", "strong_cues", "low_power", "show_title", "show_tutorial", "fullscreen"]:
		if d.has(name):
			set(name, bool(d[name]))
	language = String(d.get("language", language))
	background_sound = String(d.get("background_sound", background_sound))
	ui_scale_step = int(d.get("ui_scale_step", 0))
	# Normal became one step smaller, so settings saved before that keep the same size on screen.
	if d.has("ui_scale_step") and not d.has("ui_sizes"):
		ui_scale_step = mini(ui_scale_step + 1, 2)
	day_minutes = int(d.get("day_minutes", 20))
	for action in d.get("keys", {}):
		keys[action] = int(d["keys"][action])


func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"offline_progress": offline_progress, "notifications": notifications, "large_text": large_text,
			"reduced_motion": reduced_motion, "strong_cues": strong_cues, "low_power": low_power, "language": language,
			"show_title": show_title, "show_tutorial": show_tutorial, "background_sound": background_sound, "keys": keys, "ui_scale_step": ui_scale_step, "ui_sizes": 2, "day_minutes": day_minutes, "fullscreen": fullscreen,
		}))
