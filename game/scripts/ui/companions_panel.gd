extends "res://scripts/ui/window_panel.gd"
## Naming the farm's dog and cat and choosing their breeds and coats: offered once on a new farm, and any time later
## from the settings.

var _choice := {}
var _pictures := {}
var _coat_labels := {}
var _breed_labels := {}
## Each pet's column is this wide, so the two sit side by side and the window fits them.
const COLUMN := 118
var _names := {}


func _init() -> void:
	super("Your companions")


func open() -> void:
	_choice = Game.pets.duplicate(true)
	super()


func signature() -> String:
	return "companions"


func build() -> void:
	UiKit.para(body, tr("Every farm needs a dog and a cat. Choose their breeds and coats and give them names."), 240)
	var pair := UiKit.row(body)
	pair.add_theme_constant_override("separation", 12)
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	for kind in ["dog", "cat"]:
		var col := UiKit.column(pair)
		col.custom_minimum_size = Vector2(COLUMN, 0)
		UiKit.section(col, tr("Your dog") if kind == "dog" else tr("Your cat"))
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(COLUMN, 52)
		pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		col.add_child(pic)
		_pictures[kind] = pic
		_breed_labels[kind] = _chooser(col, func(by): _step_breed(kind, by))
		_coat_labels[kind] = _chooser(col, func(by): _step(kind, by))
		var name := LineEdit.new()
		name.text = String(_choice[kind]["name"])
		name.max_length = 14
		name.placeholder_text = tr("Name")
		name.custom_minimum_size = Vector2(COLUMN, 0)
		name.text_changed.connect(func(t): _choice[kind]["name"] = t.strip_edges())
		col.add_child(name)
		_names[kind] = name
		_show(kind)
	UiKit.button(body, tr("That's them"), _done)


## A row with arrows either side of a label, for stepping through a list of choices.
func _chooser(parent: Node, step: Callable) -> Label:
	var r := UiKit.row(parent)
	UiKit.button(r, "<", func(): step.call(-1))
	var label := UiKit.label(r)
	# The label takes the room between the arrows, so both rows are the same width and their arrows line up.
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.button(r, ">", func(): step.call(1))
	return label


func _breed(kind: String) -> String:
	return String(_choice[kind].get("breed", Coats.BREEDS[kind].keys()[0]))


func _step_breed(kind: String, by: int) -> void:
	var breeds: Array = Coats.BREEDS[kind].keys()
	var now := breeds.find(_breed(kind))
	_choice[kind]["breed"] = breeds[posmod(now + by, breeds.size())]
	# Each breed has its own coats, so the coat starts again from that breed's first.
	_choice[kind]["coat"] = Coats.options(kind, _breed(kind)).keys()[0]
	_show(kind)


func _step(kind: String, by: int) -> void:
	var coats := Coats.options(kind, _breed(kind)).keys()
	var now := coats.find(String(_choice[kind]["coat"]))
	_choice[kind]["coat"] = coats[posmod(now + by, coats.size())]
	_show(kind)


func _show(kind: String) -> void:
	var coat := String(_choice[kind]["coat"])
	var picture := Coats.breed_dir(kind, _breed(kind)) + "east.png"
	_pictures[kind].texture = Coats.recolour(load(picture), kind, coat) if ResourceLoader.exists(picture) else null
	_coat_labels[kind].text = tr(String(Coats.options(kind, _breed(kind)).get(coat, coat)))
	_breed_labels[kind].text = tr(String(Coats.BREEDS[kind].get(_breed(kind), "")))


func _done() -> void:
	var defaults := Game.default_pets()
	for kind in _choice:
		if String(_choice[kind]["name"]) == "":
			_choice[kind]["name"] = defaults[kind]["name"]
	Game.pets = _choice
	Game.pets_chosen = true
	Game.pets_changed.emit()
	close()
