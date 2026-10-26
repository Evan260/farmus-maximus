extends SceneTree
## Loads the player's real save into the current rules without writing anything, to check old saves still work.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	root.get_node("Saves").enabled = false
	var path := ProjectSettings.globalize_path(root.get_node("Saves").path_for(root.get_node("Saves").slot))
	if not FileAccess.file_exists(path):
		print("no save at ", path)
		quit()
		return
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	game.from_dict(d)
	print("coins ", game.coins, " stored ", game.stored_total(), " villa ", game.villa_stage, " helpers ", game.helpers, " zones ", game.zones_owned)
	var s: Dictionary = game.simulate_offline(3600.0)
	print("an hour later: ", s)
	print("tip: ", game.journal.tutorial_step().get("id", "none"))
	quit()
