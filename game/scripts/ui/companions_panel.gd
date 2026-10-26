extends "res://scripts/ui/window_panel.gd"
## Naming the farm's dog and cat and choosing their coats: offered once on a new farm, and any time later from the settings.

const PICTURES := {"dog": "res://assets/sprites/dog/east.png", "cat": "res://assets/sprites/animals/cat_small/east.png"}

var _choice := {}
var _pictures := {}
var _coat_labels := {}
var _names := {}


func _init() -> void:
	super("Your companions")
	fixed_size = Vector2(250, 200)


func open() -> void:
	_choice = Game.pets.duplicate(true)
	super()


func signature() -> String:
	return "companions"


func build() -> void:
	UiKit.para(body, tr("Every farm needs a dog and a cat. Choose their coats and give them names."), 240)
	var pair := UiKit.row(body)
	pair.add_theme_constant_override("separation", 12)
	for kind in ["dog", "cat"]:
		var col := UiKit.column(pair)
		col.custom_minimum_size = Vector2(115, 0)
		UiKit.section(col, tr("Your dog") if kind == "dog" else tr("Your cat"))
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(110, 52)
		pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		col.add_child(pic)
		_pictures[kind] = pic
		var coat := UiKit.row(col)
		UiKit.button(coat, "<", func(): _step(kind, -1))
		var label := UiKit.label(coat)
		label.custom_minimum_size = Vector2(80, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_coat_labels[kind] = label
		UiKit.button(coat, ">", func(): _step(kind, 1))
		var name := LineEdit.new()
		name.text = String(_choice[kind]["name"])
		name.max_length = 14
		name.placeholder_text = tr("Name")
		name.custom_minimum_size = Vector2(110, 0)
		name.text_changed.connect(func(t): _choice[kind]["name"] = t.strip_edges())
		col.add_child(name)
		_names[kind] = name
		_show(kind)
	UiKit.button(body, tr("That's them"), _done)


func _step(kind: String, by: int) -> void:
	var coats := Coats.options(kind).keys()
	var now := coats.find(String(_choice[kind]["coat"]))
	_choice[kind]["coat"] = coats[posmod(now + by, coats.size())]
	_show(kind)


func _show(kind: String) -> void:
	var coat := String(_choice[kind]["coat"])
	_pictures[kind].texture = Coats.recolour(load(PICTURES[kind]), kind, coat)
	_coat_labels[kind].text = tr(String(Coats.options(kind).get(coat, coat)))


func _done() -> void:
	var defaults := Game.default_pets()
	for kind in _choice:
		if String(_choice[kind]["name"]) == "":
			_choice[kind]["name"] = defaults[kind]["name"]
	Game.pets = _choice
	Game.pets_changed.emit()
	close()
