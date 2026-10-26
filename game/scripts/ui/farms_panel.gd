extends "res://scripts/ui/window_panel.gd"
## The farms a player keeps, one per slot: play one, start a new farm in an empty slot, or delete one for good.

## Supplied by the title screen: asks for a name and starts a new farm in the given slot.
var on_new: Callable
## Supplied by the title screen: called after a farm is deleted, so the title's menu matches.
var on_change: Callable
## The slot whose delete button has been pressed once, waiting for the second press that confirms it.
var _deleting := 0


func _init() -> void:
	super("Your farms")


## A farm's name, its day and how far its villa has come, for the farm list and the title screen.
static func describe(info: Dictionary) -> String:
	if info.is_empty():
		return TranslationServer.translate("Empty")
	var stages: Array = Balance.get_value("villa.stages", [])
	var stage: String = String(stages[clampi(int(info["villa"]) - 1, 0, stages.size() - 1)].get("name", "")) if not stages.is_empty() else ""
	var name: String = String(info["name"]) if String(info["name"]) != "" else TranslationServer.translate("Your farm")
	return "%s  -  %s %d  -  %s" % [name, TranslationServer.translate("day"), int(info["day"]), TranslationServer.translate(stage)]


func signature() -> String:
	var parts := [str(_deleting)]
	for n in range(1, Saves.SLOTS + 1):
		parts.append(JSON.stringify(Saves.slot_info(n)))
	return "|".join(parts)


func build() -> void:
	for n in range(1, Saves.SLOTS + 1):
		var info := Saves.slot_info(n)
		var card := UiKit.card(body)
		var r := UiKit.row(card)
		var text := UiKit.para(r, describe(info), 150)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not info.is_empty():
			text.add_theme_color_override("font_color", UiKit.HEADING if n == Saves.slot else UiKit.INK)
		if info.is_empty():
			UiKit.button(r, tr("New farm"), func(): on_new.call(n))
			continue
		UiKit.button(r, tr("Play"), func(): Saves.play(n))
		# Deleting asks twice, since a farm cannot be brought back.
		var sure := _deleting == n
		var del := UiKit.button(r, tr("Sure?") if sure else tr("Delete"), func():
			if _deleting == n:
				_deleting = 0
				var current := n == Saves.slot
				Saves.delete(n)
				# The estate behind the title belonged to that farm, so it starts again empty.
				if current:
					get_tree().reload_current_scene()
					return
				if on_change.is_valid():
					on_change.call()
			else:
				_deleting = n
			refresh())
		if sure:
			del.add_theme_color_override("font_color", UiKit.SHORT)
