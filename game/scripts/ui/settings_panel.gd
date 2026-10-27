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


func signature() -> String:
	return "%s|%s|%s|%s|%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [tab, _waiting_for, Windowing.strip, Windowing.transparent, Windowing.size_index,
		Windowing.dock, str(Windowing.focus_mode) + str(Windowing.follow), Settings.offline_progress, Settings.notifications, Settings.large_text, Settings.reduced_motion,
		Settings.strong_cues, Settings.low_power, str(Settings.show_tutorial) + str(Settings.show_title) + str(Settings.ui_scale_step) + str(Settings.day_minutes), JSON.stringify(Settings.keys) + Settings.language]


func build() -> void:
	var tabs := UiKit.row(top)
	for t in ["Sound", "Display", "Gameplay", "Keys"]:
		var b := UiKit.tab_button(tabs, tr(t), func(): tab = t; show_page())
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
			UiKit.setting(body, tr("Your own music"), tr("Open folder"), func(): Sfx.open_music_folder())
			UiKit.para(body, tr("Music you put in this folder (.ogg, .mp3 or .wav) plays between the game's own tracks."), 230).add_theme_color_override("font_color", UiKit.FADED)
		"Display":
			var sizes := {-1: "Smaller", 0: "Normal", 1: "Larger", 2: "Largest"}
			UiKit.setting(body, tr("Interface size"), tr(sizes.get(Settings.ui_scale_step, "Normal")), func(): Settings.set_value("ui_scale_step", (Settings.ui_scale_step + 2) % 4 - 1))
			_toggle(tr("Desktop strip (%s)") % _key_name("toggle_strip"), Windowing.strip, func(_v): Windowing.toggle_strip())
			UiKit.setting(body, tr("Strip background"), tr("Clear") if Windowing.transparent else tr("Painted sky"), func(): Windowing.set_transparent(not Windowing.transparent))
			UiKit.setting(body, tr("Strip size"), tr(Windowing.SIZES[Windowing.size_index]), func(): Windowing.cycle_size())
			UiKit.setting(body, tr("Where the strip sits"), tr("Top") if Windowing.dock == "top" else tr("Bottom"), func(): Windowing.toggle_dock())
			_toggle("Focus mode: a quieter, slower strip", Windowing.focus_mode, func(v): Windowing.set_focus_mode(v))
			_toggle("Strip follows the busiest zone", Windowing.follow, func(v): Windowing.set_follow(v))
			_toggle("Low power", Settings.low_power, func(v): Settings.set_value("low_power", v); Windowing._update_fps())
			UiKit.para(body, tr("Drag the strip with the right mouse button. %s puts it back in the middle.") % _key_name("reset_strip"), 230).add_theme_color_override("font_color", UiKit.FADED)
		"Gameplay":
			var locales := TranslationServer.get_loaded_locales()
			if locales.size() > 1:
				UiKit.section(body, tr("Language"))
				var grid := GridContainer.new()
				grid.columns = 3
				body.add_child(grid)
				locales.sort()
				for loc in locales:
					# Each language is named in its own words, so a player can find theirs whatever is showing now.
					var b := UiKit.button(grid, NATIVE_NAMES.get(loc, TranslationServer.get_locale_name(loc)), func(): Settings.set_value("language", loc))
					b.toggle_mode = true
					b.button_pressed = TranslationServer.get_locale() == loc
					b.custom_minimum_size = Vector2(76, 0)
					# A name the 8-pixel font cannot spell is drawn in the 10-pixel font at its own size, so it stays crisp in any language.
					if loc.get_slice("_", 0) in UiKit.TEN_PIXEL:
						b.add_theme_font_override("font", UiKit.ten_pixel_font())
						b.add_theme_font_size_override("font_size", 10)
			UiKit.setting(body, tr("Your dog and cat: names and coats"), tr("Change"), func(): get_tree().call_group("hud", "open_window", "companions"))
			UiKit.setting(body, tr("Length of a day"), tr("%d minutes") % Settings.day_minutes, func(): Settings.set_value("day_minutes", {10: 20, 20: 30, 30: 60, 60: 10}.get(Settings.day_minutes, 20)))
			_toggle("Progress while the game is closed", Settings.offline_progress, func(v): Settings.set_value("offline_progress", v))
			_toggle("Flash the taskbar when something needs you", Settings.notifications, func(v): Settings.set_value("notifications", v))
			_toggle("Show tips", Settings.show_tutorial, func(v): Settings.set_value("show_tutorial", v))
			_toggle("Open on the title screen", Settings.show_title, func(v): Settings.set_value("show_title", v))
			UiKit.setting(body, tr("Who made the game"), tr("Credits"), func(): get_tree().call_group("hud", "open_window", "credits"))
			_toggle("Larger text for messages", Settings.large_text, func(v): Settings.set_value("large_text", v))
			_toggle("Reduced motion", Settings.reduced_motion, func(v): Settings.set_value("reduced_motion", v))
			_toggle("Clear marker on ready plants", Settings.strong_cues, func(v): Settings.set_value("strong_cues", v))
		"Keys":
			for action in Settings.ACTIONS:
				var r := UiKit.row(body)
				UiKit.label(r, tr(String(Settings.ACTIONS[action]["name"]))).custom_minimum_size = Vector2(130, 0)
				var text := tr("Press a key...") if _waiting_for == action else _key_name(action)
				UiKit.button(r, text, func(): _waiting_for = action; refresh()).custom_minimum_size = Vector2(80, 0)


func _toggle(text: String, on: bool, action: Callable) -> void:
	UiKit.setting(body, tr(text), tr("On") if on else tr("Off"), func(): action.call(not on))


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
