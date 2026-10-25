extends "res://scripts/ui/window_panel.gd"
## Settings: sound, the window and desktop strip, how the game plays, accessibility and key bindings.

var tab := "Sound"
var _waiting_for := ""


func _init() -> void:
	super("Settings")


func signature() -> String:
	return "%s|%s|%s|%s|%d|%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [tab, _waiting_for, Windowing.strip, Windowing.transparent, Windowing.size_index, Windowing.height_index,
		Windowing.dock, str(Windowing.focus_mode) + str(Windowing.follow), Settings.offline_progress, Settings.notifications, Settings.large_text, Settings.reduced_motion,
		Settings.strong_cues, Settings.low_power, Settings.show_tutorial, JSON.stringify(Settings.keys) + Settings.language]


func build() -> void:
	var tabs := UiKit.row(body)
	for t in ["Sound", "Display", "Play", "Keys"]:
		var b := UiKit.button(tabs, tr(t), func(): tab = t; refresh())
		b.toggle_mode = true
		b.button_pressed = t == tab
	match tab:
		"Sound":
			for bus in ["Music", "Ambience", "Effects"]:
				var r := UiKit.row(body)
				UiKit.label(r, tr(bus)).custom_minimum_size = Vector2(70, 0)
				var slider := HSlider.new()
				slider.min_value = 0.0
				slider.max_value = 1.0
				slider.step = 0.05
				slider.value = Sfx.volumes[bus]
				slider.custom_minimum_size = Vector2(120, 8)
				slider.value_changed.connect(func(v): Sfx.set_volume(bus, v))
				r.add_child(slider)
			UiKit.para(body, tr("Music and sound files dropped into the game's audio folders are picked up by name."), 230).add_theme_color_override("font_color", UiKit.FADED)
		"Display":
			UiKit.button(body, tr("Full window  (%s)") % _key_name("toggle_strip") if Windowing.strip else tr("Desktop strip  (%s)") % _key_name("toggle_strip"), func(): Windowing.toggle_strip())
			UiKit.button(body, tr("Strip: transparent") if Windowing.transparent else tr("Strip: painted sky"), func(): Windowing.set_transparent(not Windowing.transparent))
			UiKit.button(body, tr("Strip scale: %s") % tr(Windowing.SIZES[Windowing.size_index]), func(): Windowing.cycle_size())
			UiKit.button(body, tr("Strip height: %s") % tr(Windowing.HEIGHT_NAMES[Windowing.height_index]), func(): Windowing.cycle_height())
			UiKit.button(body, tr("Strip at the top of the screen") if Windowing.dock == "top" else tr("Strip at the bottom of the screen"), func(): Windowing.toggle_dock())
			_toggle("Focus mode: quieter and slower strip", Windowing.focus_mode, func(v): Windowing.set_focus_mode(v))
			_toggle("Strip follows the busiest zone", Windowing.follow, func(v): Windowing.set_follow(v))
			_toggle("Low power", Settings.low_power, func(v): Settings.set_value("low_power", v); Windowing._update_fps())
			UiKit.para(body, tr("Drag the strip with the right mouse button. %s puts it back in the middle.") % _key_name("reset_strip"), 230).add_theme_color_override("font_color", UiKit.FADED)
		"Play":
			_toggle("Progress while the game is closed", Settings.offline_progress, func(v): Settings.set_value("offline_progress", v))
			_toggle("Flash the taskbar when something needs you", Settings.notifications, func(v): Settings.set_value("notifications", v))
			_toggle("Show tips", Settings.show_tutorial, func(v): Settings.set_value("show_tutorial", v))
			_toggle("Larger text for messages", Settings.large_text, func(v): Settings.set_value("large_text", v))
			_toggle("Reduced motion", Settings.reduced_motion, func(v): Settings.set_value("reduced_motion", v))
			_toggle("Clear marker on ready plants", Settings.strong_cues, func(v): Settings.set_value("strong_cues", v))
			var locales := TranslationServer.get_loaded_locales()
			if locales.size() > 1:
				var r := UiKit.row(body)
				UiKit.label(r, tr("Language"))
				for loc in locales:
					var b := UiKit.button(r, TranslationServer.get_locale_name(loc), func(): Settings.set_value("language", loc))
					b.toggle_mode = true
					b.button_pressed = Settings.language == loc
		"Keys":
			var list := UiKit.scroll(body, Vector2(240, 130))
			for action in Settings.ACTIONS:
				var r := UiKit.row(list)
				UiKit.label(r, tr(String(Settings.ACTIONS[action]["name"]))).custom_minimum_size = Vector2(130, 0)
				var text := tr("Press a key...") if _waiting_for == action else _key_name(action)
				UiKit.button(r, text, func(): _waiting_for = action; refresh())


func _toggle(text: String, on: bool, action: Callable) -> void:
	UiKit.button(body, "%s: %s" % [tr(text), tr("on") if on else tr("off")], func(): action.call(not on))


func _key_name(action: String) -> String:
	return OS.get_keycode_string(Settings.key_for(action))


func _input(event: InputEvent) -> void:
	if _waiting_for == "" or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		Settings.rebind(_waiting_for, event.physical_keycode)
		_waiting_for = ""
		get_viewport().set_input_as_handled()
		refresh()
