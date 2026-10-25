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
	"toggle_strip": {"name": "Desktop strip", "key": KEY_F10, "pad": -1},
	"reset_strip": {"name": "Re-centre the strip", "key": KEY_F9, "pad": -1},
}

var offline_progress := true
var notifications := true
var large_text := false
var reduced_motion := false
## Ready plants get a clear marker above them, not just a twinkle, for players who find the twinkle hard to see.
var strong_cues := false
var low_power := false
var language := "en"
var intro_seen := false
var show_tutorial := true
var keys := {}


func _ready() -> void:
	_load()
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var pad := int(ACTIONS[action]["pad"])
		if pad >= 0:
			var ev := InputEventJoypadButton.new()
			ev.button_index = pad
			InputMap.action_add_event(action, ev)
		_bind(action, int(keys.get(action, ACTIONS[action]["key"])))
	TranslationServer.set_locale(language)


func key_for(action: String) -> int:
	return int(keys.get(action, ACTIONS[action]["key"]))


func rebind(action: String, keycode: int) -> void:
	keys[action] = keycode
	_bind(action, keycode)
	save()


func set_value(name: String, value: Variant) -> void:
	set(name, value)
	if name == "language":
		TranslationServer.set_locale(String(value))
	save()
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
	for name in ["offline_progress", "notifications", "large_text", "reduced_motion", "strong_cues", "low_power", "intro_seen", "show_tutorial"]:
		if d.has(name):
			set(name, bool(d[name]))
	language = String(d.get("language", language))
	for action in d.get("keys", {}):
		keys[action] = int(d["keys"][action])


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"offline_progress": offline_progress, "notifications": notifications, "large_text": large_text,
			"reduced_motion": reduced_motion, "strong_cues": strong_cues, "low_power": low_power, "language": language,
			"intro_seen": intro_seen, "show_tutorial": show_tutorial, "keys": keys,
		}))
