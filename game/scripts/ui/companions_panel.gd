extends "res://scripts/ui/window_panel.gd"
## Naming the farm's dog and cat and choosing their breeds and coats: offered once on a new farm, and any time later
## from the settings.

var _choice := {}
var _pictures := {}
var _coat_labels := {}
var _breed_labels := {}
## Each pet's column is this wide, so the two sit side by side and the window fits them.
const COLUMN := 118
## The pet's picture, which on a phone stands beside its choices rather than above them.
const PICTURE := Vector2(52, 52)
var _names := {}


func _init() -> void:
	super("Your companions")


func open() -> void:
	_choice = Game.pets.duplicate(true)
	super()


func signature() -> String:
	return "companions"


func build() -> void:
	# A phone's screen is short, so there each picture stands beside its choices and the whole choice fits without scrolling.
	var beside := Windowing.phone
	var width := _column() + (int(PICTURE.x) + 4 if beside else 0)
	Ui.para(body, tr("Every farm needs a dog and a cat. Choose their breeds and coats and give them names."), width * 2 + 12 if beside else 240)
	var pair := Ui.row(body)
	pair.add_theme_constant_override("separation", 12)
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	for kind in ["dog", "cat"]:
		var col := Ui.column(pair)
		col.custom_minimum_size = Vector2(width, 0)
		Ui.section(col, tr("Your dog") if kind == "dog" else tr("Your cat"))
		var pic := TextureRect.new()
		pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		var choices := col
		if beside:
			var r := Ui.row(col)
			r.add_theme_constant_override("separation", 4)
			pic.custom_minimum_size = PICTURE
			r.add_child(pic)
			choices = Ui.column(r)
			choices.custom_minimum_size = Vector2(_column(), 0)
			choices.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		else:
			pic.custom_minimum_size = Vector2(_column(), PICTURE.y)
			col.add_child(pic)
		_pictures[kind] = pic
		_breed_labels[kind] = _chooser(choices, func(by): _step_breed(kind, by))
		_coat_labels[kind] = _chooser(choices, func(by): _step(kind, by))
		var name := LineEdit.new()
		name.text = String(_choice[kind]["name"])
		name.max_length = 14
		name.placeholder_text = tr("Name")
		name.custom_minimum_size = Vector2(width, 0)
		name.text_changed.connect(func(t): _choice[kind]["name"] = t.strip_edges())
		col.add_child(name)
		_names[kind] = name
		_show(kind)
	Ui.button(body, tr("That's them"), _done)


## A phone's arrows are a fingertip wide, and the column widens by as much so the breed's name still fits between them.
func _column() -> int:
	return COLUMN + 2 * maxi(0, Windowing.touch_px() - 13)


## A row with arrows either side of a label, for stepping through a list of choices.
func _chooser(parent: Node, step: Callable) -> Label:
	var r := Ui.row(parent)
	var back := Ui.button(r, "<", func(): step.call(-1))
	var label := Ui.label(r)
	# The label takes the room between the arrows, so both rows are the same width and their arrows line up.
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var on := Ui.button(r, ">", func(): step.call(1))
	for arrow in [back, on]:
		arrow.custom_minimum_size.x = Windowing.touch_px()
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
	_pictures[kind].texture = Coats.recolour(load(picture), kind, coat, _breed(kind)) if ResourceLoader.exists(picture) else null
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
