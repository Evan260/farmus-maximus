extends Node
## Saves the farm every minute and on exit, keeps rolling backups, and runs the offline catch-up on load.

const PATH := "user://save.json"
const BACKUPS := 3

## Filled on load when time passed while the game was closed; the HUD shows it once.
var pending_summary := {}
## Off in demo mode, so screenshots never overwrite a real save.
var enabled := true
var _timer := 0.0


func _ready() -> void:
	_migrate_from_old_name()
	load_game()


## Godot keeps saves in a folder named after the game, so the files from before the rename to Farmus Maximus are copied over once.
func _migrate_from_old_name() -> void:
	var old_dir := OS.get_user_data_dir().get_base_dir().path_join("Otium")
	if not DirAccess.dir_exists_absolute(old_dir):
		return
	var files := ["save.json", "settings.json", "window.json"]
	for i in range(1, BACKUPS + 1):
		files.append("save.json.bak%d" % i)
	for f in files:
		var from := old_dir.path_join(f)
		var to := OS.get_user_data_dir().path_join(f)
		if FileAccess.file_exists(from) and not FileAccess.file_exists(to):
			DirAccess.copy_absolute(from, to)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= float(Balance.get_value("save.interval_seconds", 60)):
		_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func save_game() -> void:
	if not enabled:
		return
	var data := Game.to_dict()
	data["version"] = 1
	data["saved_at"] = Time.get_unix_time_from_system()
	_rotate_backups()
	# Writing to a temporary file first means a crash mid-write never leaves a half-written save.
	var tmp := PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(PATH))


func load_game() -> void:
	for path in _candidates():
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("Save %s is unreadable, trying the next backup" % path)
			continue
		Game.from_dict(parsed)
		var away := Time.get_unix_time_from_system() - float(parsed.get("saved_at", Time.get_unix_time_from_system()))
		if away >= float(Balance.get_value("offline.min_seconds_for_summary", 30)):
			pending_summary = Game.simulate_offline(away)
		return
	Game.new_game()


func reset() -> void:
	for path in _candidates():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Game.new_game()


func _candidates() -> Array:
	var list := [PATH]
	for i in range(1, BACKUPS + 1):
		list.append("%s.bak%d" % [PATH, i])
	return list


func _rotate_backups() -> void:
	if not FileAccess.file_exists(PATH):
		return
	for i in range(BACKUPS - 1, 0, -1):
		var older := "%s.bak%d" % [PATH, i]
		if FileAccess.file_exists(older):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(older), ProjectSettings.globalize_path("%s.bak%d" % [PATH, i + 1]))
	DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(PATH + ".bak1"))
