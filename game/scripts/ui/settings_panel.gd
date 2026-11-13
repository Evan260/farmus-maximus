extends "res://scripts/ui/window_panel.gd"
## Settings: sound, the window and desktop strip, how the game plays, accessibility and key bindings.

## Each language's name in that language, for the language list.
const NATIVE_NAMES := {"en": "English", "fr": "Français", "de": "Deutsch", "es": "Español", "it": "Italiano", "pt_BR": "Português (BR)",
	"pl": "Polski", "tr": "Türkçe", "ru": "Русский", "uk": "Українська", "ja": "日本語", "ko": "한국어", "zh_CN": "简体中文", "zh_TW": "繁體中文"}

var tab := "Sound"
var _waiting_for := ""


func _init() -> void:
	super("Settings")
	fixed_size = Vector2(264, 190)


## A key left waiting when the window closed is not still waiting when it opens again.
func open() -> void:
	_waiting_for = ""
	super()


func signature() -> String:
	return "%s|%s|%s|%s|%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [tab, _waiting_for, Windowing.strip, Windowing.transparent, Windowing.strip_scale,
		Windowing.dock, str(Windowing.focus_mode) + str(Windowing.follow), Settings.offline_progress, str(Settings.notifications) + str(Windowing.is_fullscreen()), Settings.large_text, Settings.reduced_motion,
		Settings.strong_cues, str(Settings.low_power) + str(Settings.tooltips), Settings.background_sound + str(Settings.show_tutorial) + str(Settings.show_title) + str(Settings.ui_scale_step) + str(Settings.day_minutes), JSON.stringify(Settings.keys) + Settings.language]


func build() -> void:
	var tabs := Ui.tab_row(top)
	for t in ["Sound", "Display", "Gameplay", "Keys"]:
		Ui.tab_button(tabs, tr(t), func(): tab = t; show_page()).button_pressed = t == tab
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 7)
	top.add_child(gap)
	match tab:
		"Sound":
			for bus in [["Master", "Everything"], ["Music", "Music"], ["Effects", "Effects"], ["Ambience", "Ambience"]]:
				var r := Ui.row(body)
				Ui.label(r, tr(bus[1])).custom_minimum_size = Vector2(70, 0)
				var slider := HSlider.new()
				slider.min_value = 0.0
				slider.max_value = 1.0
				slider.step = 0.05
				slider.value = Audio.volumes[bus[0]]
				slider.custom_minimum_size = Vector2(120, 8)
				slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				r.add_child(slider)
				var amount := Ui.label(r, _percent(slider.value))
				amount.custom_minimum_size = Vector2(30, 0)
				amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				amount.add_theme_color_override("font_color", UiTheme.MUTED)
				slider.value_changed.connect(func(v):
					amount.text = _percent(v)
					Audio.set_volume(bus[0], v))
			var music := Ui.setting(body, tr("Your own music"), tr("Open folder"), func(): Audio.open_music_folder())
			Ui.tip_on(music, "Music you put in this folder (.ogg, .mp3 or .wav) plays between the game's own tracks.")
			var sounds := {"full": "Full volume", "quieter": "Quieter", "muted": "Muted"}
			Ui.setting(body, tr("While you use other windows"), tr(sounds.get(Settings.background_sound, "Full volume")),
				func(): Settings.set_value("background_sound", {"full": "quieter", "quieter": "muted", "muted": "full"}.get(Settings.background_sound, "full")))
		"Display":
			var sizes := {-1: "Smaller", 0: "Normal", 1: "Larger", 2: "Largest"}
			Ui.setting(body, tr("Interface size"), tr(sizes.get(Settings.ui_scale_step, "Normal")), func(): Settings.set_value("ui_scale_step", (Settings.ui_scale_step + 2) % 4 - 1))
			_toggle("Full screen (F11)", Windowing.is_fullscreen(), func(_v): Windowing.toggle_fullscreen())
			_toggle(tr("Desktop strip (%s)") % _key_name("toggle_strip"), Windowing.strip, func(_v): Windowing.toggle_strip())
			_toggle("Focus mode: a quieter, slower strip", Windowing.focus_mode, func(v): Windowing.set_focus_mode(v))
			_toggle("Strip follows the busiest zone", Windowing.follow, func(v): Windowing.set_follow(v))
			_toggle("Low power", Settings.low_power, func(v): Settings.set_value("low_power", v); Windowing._update_fps())
			Ui.para(body, tr("Point at the strip to change its size, width, place and sky. %s puts it back in the middle.") % _key_name("reset_strip"), 230).add_theme_color_override("font_color", UiTheme.MUTED)
		"Gameplay":
			var locales := TranslationServer.get_loaded_locales()
			if locales.size() > 1:
				Ui.section(body, tr("Language"))
				var grid := GridContainer.new()
				grid.columns = 3
				body.add_child(grid)
				# Each language is named in its own words and its own font, so a player can find theirs whatever is showing now.
				for loc in NATIVE_NAMES.keys().filter(func(l: String) -> bool: return l in locales):
					var b := Ui.button(grid, NATIVE_NAMES[loc], func(): Settings.set_value("language", loc))
					b.toggle_mode = true
					b.button_pressed = TranslationServer.get_locale() == loc
					b.custom_minimum_size = Vector2(76, 0)
					b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
					b.add_theme_font_override("font", UiTheme.ui_font(loc))
					b.add_theme_font_size_override("font_size", UiTheme.text_size(loc))
			_toggle("Uncle Marcus's advice", Settings.show_tutorial, func(v): Settings.set_value("show_tutorial", v))
			_toggle("Tips when you point at a button", Settings.tooltips, func(v): Settings.set_value("tooltips", v))
			_toggle("Larger text for messages", Settings.large_text, func(v): Settings.set_value("large_text", v))
			_toggle("Reduced motion", Settings.reduced_motion, func(v): Settings.set_value("reduced_motion", v))
			Ui.setting(body, tr("Your dog and cat: names and coats"), tr("Change"), func(): get_tree().call_group("hud", "open_window", "companions"))
			Ui.setting(body, tr("Length of a day"), tr("%d minutes") % Settings.day_minutes, func(): Settings.set_value("day_minutes", {10: 20, 20: 30, 30: 60, 60: 10}.get(Settings.day_minutes, 20)))
			_toggle("Progress while the game is closed", Settings.offline_progress, func(v): Settings.set_value("offline_progress", v))
			_toggle("Flash the taskbar when something needs you", Settings.notifications, func(v): Settings.set_value("notifications", v))
			_toggle("Open on the title screen", Settings.show_title, func(v): Settings.set_value("show_title", v))
			_toggle("Clear marker on ready plants", Settings.strong_cues, func(v): Settings.set_value("strong_cues", v))
		"Keys":
			for action in Settings.ACTIONS:
				var r := Ui.row(body)
				Ui.label(r, tr(String(Settings.ACTIONS[action]["name"]))).custom_minimum_size = Vector2(130, 0)
				var text := tr("Press a key...") if _waiting_for == action else _key_name(action)
				Ui.button(r, text, func(): _waiting_for = action; refresh()).custom_minimum_size = Vector2(80, 0)
				var pad := int(Settings.ACTIONS[action]["pad"])
				# The right stick scrolls the estate, which has no button of its own.
				if action in ["pan_left", "pan_right"]:
					pad = JOY_BUTTON_RIGHT_STICK
				if pad >= 0:
					Ui.pad_glyph(r, pad as JoyButton)


func _toggle(text: String, on: bool, action: Callable) -> void:
	Ui.setting(body, tr(text), tr("On") if on else tr("Off"), func(): action.call(not on))


func _percent(v: float) -> String:
	return "%d%%" % int(roundf(v * 100.0))


func _key_name(action: String) -> String:
	# Keys are bound by where they sit on the keyboard, so the name shown is what that key says on this layout.
	var code := Settings.key_for(action)
	return OS.get_keycode_string(code if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(code))


func _input(event: InputEvent) -> void:
	if _waiting_for == "" or not visible:
		return
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	# Escape or the pad's B keeps the old key, except for closing panels, whose usual key Escape is.
	if event.is_action_pressed("ui_cancel") and not (key and _waiting_for == "close_panel"):
		_waiting_for = ""
	elif key:
		Settings.rebind(_waiting_for, event.physical_keycode)
		_waiting_for = ""
	else:
		return
	get_viewport().set_input_as_handled()
	refresh()
