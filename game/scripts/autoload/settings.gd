extends Node
## Player preferences that belong to this computer rather than to the farm: accessibility, notifications, language and key bindings.

signal changed

const FILE := "settings.cfg"
## The settings kept in each section of settings.cfg; the volumes and the strip's own are kept there by Sfx and Windowing.
const PLAY := ["offline_progress", "notifications", "large_text", "reduced_motion", "strong_cues", "show_title", "show_tutorial", "tooltips", "language", "day_minutes"]
const DISPLAY := ["ui_scale_step", "fullscreen", "low_power"]
const SOUND := ["background_sound"]
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
## The tips shown when the pointer rests on a button.
var tooltips := true
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
## Where settings.cfg is kept; tests point it at a folder of their own.
var folder := "user://"
## Everything in settings.cfg, the volumes and the strip's settings included.
var cfg := ConfigFile.new()
var _defaults := {}


func _init() -> void:
	for name in PLAY + DISPLAY + SOUND:
		_defaults[name] = get(name)


func _ready() -> void:
	persist = not trial_run()
	# The tests start from the game's own settings every time, whatever the player has chosen.
	if not Dev.checking():
		load_from(folder)
	if Dev.has("new-farm"):
		show_tutorial = true
	# --ui-size=-1 (Smaller), 0 (Normal), 1 (Larger) or 2 (Largest) tries an interface size without keeping it.
	if Dev.has("ui-size"):
		ui_scale_step = clampi(int(Dev.num("ui-size", 0)), -1, 2)
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
	TranslationServer.set_locale(language if language in TranslationServer.get_loaded_locales() else _system_language())
	if Dev.has("locale"):
		TranslationServer.set_locale(Dev.get_arg("locale"))


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


## Demo farms, new-farm trials, read-only checks, --no-save and tests, which leave the player's farms and settings as they were.
func trial_run() -> bool:
	return Dev.no_save()


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


## Reads settings.cfg from a folder; the first time, it is made from the three files the settings used to be kept in.
func load_from(dir: String) -> void:
	folder = dir
	cfg = ConfigFile.new()
	if cfg.load(dir.path_join(FILE)) != OK:
		cfg = ConfigFile.new()
		_bring_old_files()
	for list in [[PLAY, "play"], [DISPLAY, "display"], [SOUND, "sound"]]:
		for name in list[0]:
			set(name, cfg.get_value(list[1], name, _defaults[name]))
	keys = {}
	if cfg.has_section("keys"):
		for action in cfg.get_section_keys("keys"):
			keys[action] = int(cfg.get_value("keys", action))


## The preferences, volumes and strip settings were once three JSON files, which settings.cfg takes over once.
func _bring_old_files() -> void:
	var prefs := _old_file("prefs.json")
	for list in [[PLAY, "play"], [DISPLAY, "display"], [SOUND, "sound"]]:
		for name in list[0]:
			if prefs.has(name):
				cfg.set_value(list[1], name, type_convert(prefs[name], typeof(_defaults[name])))
	# Normal became one step smaller, so settings saved before that keep the same size on screen.
	if prefs.has("ui_scale_step") and not prefs.has("ui_sizes"):
		cfg.set_value("display", "ui_scale_step", mini(int(prefs["ui_scale_step"]) + 1, 2))
	for action in prefs.get("keys", {}):
		cfg.set_value("keys", action, int(prefs["keys"][action]))
	var volumes: Dictionary = _old_file("settings.json").get("volumes", {})
	for bus in volumes:
		cfg.set_value("sound", String(bus).to_lower(), float(volumes[bus]))
	var window := _old_file("window.json")
	for key in window:
		cfg.set_value("window", key, window[key])
	if not (prefs.is_empty() and volumes.is_empty() and window.is_empty()):
		_write()


func _old_file(name: String) -> Dictionary:
	var path := folder.path_join(name)
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if typeof(d) == TYPE_DICTIONARY else {}


func save() -> void:
	for list in [[PLAY, "play"], [DISPLAY, "display"], [SOUND, "sound"]]:
		for name in list[0]:
			cfg.set_value(list[1], name, get(name))
	for action in keys:
		cfg.set_value("keys", action, int(keys[action]))
	_write()


## Keeps values for another part of the game, such as the volumes or the strip's place, in a section of settings.cfg.
func store(section: String, values: Dictionary) -> void:
	for key in values:
		cfg.set_value(section, key, values[key])
	_write()


func _write() -> void:
	if persist:
		cfg.save(folder.path_join(FILE))
