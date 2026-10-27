extends "res://scripts/ui/window_panel.gd"
## The farms a player keeps, one per slot: play one, start a new farm in an empty slot, or delete one for good.

## Supplied by the title screen: asks for a name and starts a new farm in the given slot.
var on_new: Callable
## Supplied by the title screen: called after a farm is deleted, so the title's menu matches.
var on_change: Callable
## The slot whose delete button has been pressed, waiting for the player to type the word that confirms it.
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
	return "%s  -  %s  -  %s" % [name, TranslationServer.translate("day %d") % int(info["day"]), TranslationServer.translate(stage)]


## Each visit to the list starts with no farm half way through being deleted.
func open() -> void:
	_deleting = 0
	super()


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
		if _deleting != n:
			UiKit.button(r, tr("Delete"), func(): _deleting = n; refresh())
			continue
		_confirm_delete(card, n)


## A farm cannot be brought back, so deleting one asks for the word typed out, which no stray click can do.
func _confirm_delete(card: VBoxContainer, n: int) -> void:
	var word := tr("delete")
	var ask := UiKit.para(card, tr("Type \"%s\" to delete this farm for good.") % word, 220)
	ask.add_theme_color_override("font_color", UiKit.SHORT)
	var r := UiKit.row(card)
	var field := LineEdit.new()
	field.placeholder_text = word
	field.max_length = 20
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(field)
	var gone := func():
		if field.text.strip_edges().to_lower() != word.to_lower():
			return
		_deleting = 0
		var current := n == Saves.slot
		Saves.delete(n)
		# The estate behind the title belonged to that farm, so it starts again empty.
		if current:
			get_tree().reload_current_scene()
			return
		if on_change.is_valid():
			on_change.call()
		refresh()
	var del := UiKit.button(r, tr("Delete"), gone)
	del.disabled = true
	field.text_changed.connect(func(t: String): del.disabled = t.strip_edges().to_lower() != word.to_lower())
	field.text_submitted.connect(func(_t): gone.call())
	UiKit.button(r, tr("Cancel"), func(): _deleting = 0; refresh())
	field.grab_focus.call_deferred()
