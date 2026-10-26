extends Node
## Saves the farm every minute and on exit, keeps rolling backups, and runs the offline catch-up on load. A player can
## keep several farms, each in its own slot; the one played last opens again next time.

const SLOTS := 3
const BACKUPS := 3
## Remembers which farm was played last.
const FARMS_PATH := "user://farms.json"

## Filled on load when time passed while the game was closed; the HUD shows it once.
var pending_summary := {}
## Off in demo mode, so screenshots never overwrite a real save.
var enabled := true
## The farm being played, from 1 to SLOTS.
var slot := 1
## False while there is no farm yet, so the empty estate behind the title screen is never saved.
var has_farm := false
## Set once the player has chosen a farm on the title screen, so the scene reloading with that farm skips it.
var title_done := false
var _timer := 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	# A "new farm" run starts from nothing and never touches the real save.
	if "--new-farm" in args:
		enabled = false
		Game.new_game()
		return
	# Read-only runs load the real farm for checking without ever writing to it.
	if "--readonly" in args:
		enabled = false
	# Older saves are brought over only on the very first start; once farms.json exists a deleted farm stays deleted.
	if enabled and not FileAccess.file_exists(FARMS_PATH):
		_migrate_from_old_name()
		_migrate_to_slots()
		_remember_slot()
	slot = clampi(int(_farms().get("last", 1)), 1, SLOTS)
	load_game(slot)


func path_for(n: int) -> String:
	return "user://farm_%d.json" % n


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


## Before there were several farms the one farm lived in save.json; it becomes the first farm, backups and all.
func _migrate_to_slots() -> void:
	if not FileAccess.file_exists("user://save.json") or FileAccess.file_exists(path_for(1)):
		return
	var pairs := [["user://save.json", path_for(1)]]
	for i in range(1, BACKUPS + 1):
		pairs.append(["user://save.json.bak%d" % i, "%s.bak%d" % [path_for(1), i]])
	for pair in pairs:
		if FileAccess.file_exists(pair[0]):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(pair[0]), ProjectSettings.globalize_path(pair[1]))


func _farms() -> Dictionary:
	if not FileAccess.file_exists(FARMS_PATH):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(FARMS_PATH))
	return d if typeof(d) == TYPE_DICTIONARY else {}


func _remember_slot() -> void:
	if not enabled:
		return
	var f := FileAccess.open(FARMS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"last": slot}))


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= float(Balance.get_value("save.interval_seconds", 60)):
		_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func save_game() -> void:
	if not enabled or not has_farm:
		return
	var path := path_for(slot)
	var data := Game.to_dict()
	data["version"] = 2
	data["saved_at"] = Time.get_unix_time_from_system()
	_rotate_backups(path)
	# Writing to a temporary file first means a crash mid-write never leaves a half-written save.
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


func load_game(n: int) -> void:
	slot = n
	pending_summary = {}
	for path in _candidates(n):
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("Save %s is unreadable, trying the next backup" % path)
			continue
		Game.from_dict(parsed)
		has_farm = true
		var away := Time.get_unix_time_from_system() - float(parsed.get("saved_at", Time.get_unix_time_from_system()))
		# With offline progress switched off, the estate simply waits exactly as it was left.
		if Settings.offline_progress and away >= float(Balance.get_value("offline.min_seconds_for_summary", 30)):
			pending_summary = Game.simulate_offline(away)
		return
	has_farm = false
	Game.new_game()


## What the farm in a slot is, for the farm list: its name, day and villa, or an empty dictionary for an empty slot.
func slot_info(n: int) -> Dictionary:
	for path in _candidates(n):
		if not FileAccess.file_exists(path):
			continue
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var cal: Dictionary = d.get("calendar", {})
		return {"name": String(d.get("farm_name", "")), "day": int(cal.get("day", 0)) + 1, "villa": int(d.get("villa_stage", 1)), "saved_at": float(d.get("saved_at", 0))}
	return {}


## The first empty slot, or 0 when every slot holds a farm.
func free_slot() -> int:
	for n in range(1, SLOTS + 1):
		if slot_info(n).is_empty():
			return n
	return 0


## Plays the farm in a slot: the scene starts again around it.
func play(n: int) -> void:
	save_game()
	load_game(n)
	_remember_slot()
	title_done = true
	get_tree().reload_current_scene()


## Starts a new farm with its name in an empty slot and plays it from the uncle's letter.
func create(n: int, farm_name: String) -> void:
	save_game()
	slot = n
	Game.new_game()
	Game.farm_name = farm_name
	has_farm = true
	pending_summary = {}
	save_game()
	_remember_slot()
	title_done = true
	get_tree().reload_current_scene()


## Deletes the farm in a slot and its backups for good.
func delete(n: int) -> void:
	for path in _candidates(n):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if n == slot:
		has_farm = false
		Game.new_game()


func reset() -> void:
	delete(slot)


func _candidates(n: int) -> Array:
	var list := [path_for(n)]
	for i in range(1, BACKUPS + 1):
		list.append("%s.bak%d" % [path_for(n), i])
	return list


func _rotate_backups(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	for i in range(BACKUPS - 1, 0, -1):
		var older := "%s.bak%d" % [path, i]
		if FileAccess.file_exists(older):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(older), ProjectSettings.globalize_path("%s.bak%d" % [path, i + 1]))
	DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak1"))
