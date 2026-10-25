extends Node
## Every tunable number lives in data/balance.json, so balancing never needs a code change.

var data: Dictionary = {}


func _init() -> void:
	# Loaded in _init so other autoloads can read values in their own _ready.
	load_data()


func load_data() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("data/balance.json could not be parsed")
		return
	data = parsed


func get_value(path: String, fallback: Variant = null) -> Variant:
	var node: Variant = data
	for key in path.split("."):
		if typeof(node) == TYPE_ARRAY and key.is_valid_int() and int(key) < node.size():
			node = node[int(key)]
		elif typeof(node) == TYPE_DICTIONARY and node.has(key):
			node = node[key]
		else:
			return fallback
	return node
