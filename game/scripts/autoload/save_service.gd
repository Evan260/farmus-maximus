extends Node
## Saves the farm every minute and on exit, keeps rolling backups, and runs the offline catch-up on load. A player can
## keep several farms, each in its own slot; the one played last opens again next time.

const SLOTS := 3
const BACKUPS := 3
## Seconds the newest backup must have aged before the backups move along, so each really is an older copy.
const BACKUP_EVERY := 300.0

## Filled on load when time passed while the game was closed; the HUD shows it once.
var pending_summary := {}
## Off for trial runs such as demo farms and read-only checks, which never write, move or delete a farm's files.
var enabled := true
## Where the farms are kept; tests point it at a folder of their own so the player's farms are never touched.
var folder := "user://"
## The farm being played, from 1 to SLOTS.
var slot := 1
## False while the estate is not yet a farm: the empty one behind the title screen is never saved.
var has_farm := false
## Set once the player has chosen a farm on the title screen, so the scene reloading with that farm skips it.
var title_done := false
var _timer := 0.0


func _ready() -> void:
	# A "new farm" run, and the tests and bots, start from nothing and never touch the real save.
	if Dev.has("new-farm") or Dev.checking():
		enabled = false
		Game.new_game()
		return
	# Read-only runs and demo farms may load the real farm, but never write to it.
	if not Settings.persist:
		enabled = false
	# Older saves are brought over only on the very first start; once farms.json exists a deleted farm stays deleted.
	if enabled and not FileAccess.file_exists(_farms_path()):
		_migrate_from_old_name()
		_migrate_to_slots()
		_remember_slot()
	slot = clampi(int(_farms().get("last", 1)), 1, SLOTS)
	load_game(slot)


func path_for(n: int) -> String:
	return folder.path_join("farm_%d.json" % n)


## The file that remembers which farm was played last.
func _farms_path() -> String:
	return folder.path_join("farms.json")


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
			_move(pair[0], pair[1])


func _farms() -> Dictionary:
	if not FileAccess.file_exists(_farms_path()):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(_farms_path()))
	return d if typeof(d) == TYPE_DICTIONARY else {}


func _remember_slot() -> void:
	if enabled:
		_write(_farms_path(), JSON.stringify({"last": slot}))


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= float(Data.get_value("save.interval_seconds", 60)):
		_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func save_game() -> void:
	# An empty estate becomes a farm in its slot once it is played, which begins with the first-day welcome.
	if not enabled or not (has_farm or Game.intro_seen):
		return
	has_farm = true
	var path := path_for(slot)
	var data := Game.to_dict()
	data["version"] = 2
	data["saved_at"] = Time.get_unix_time_from_system()
	# Writing to a temporary file first means a crash mid-write never leaves a half-written save.
	var tmp := path + ".tmp"
	if not _write(tmp, JSON.stringify(data, "\t")) or not _set_aside_unreadable(slot):
		return
	_rotate_backups(path)
	_move(tmp, path)


## Writes a file and reads it back, so a full disk or a failed write is caught before it can replace anything.
func _write(path: String, text: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Could not write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	var stored := f.store_string(text)
	f.close()
	if not stored or FileAccess.get_file_as_string(path) != text:
		push_error("Could not write %s" % path)
		return false
	return true


func _move(from: String, to: String) -> bool:
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(from), ProjectSettings.globalize_path(to))
	if err != OK:
		push_error("Could not move %s to %s: %s" % [from, to, error_string(err)])
	return err == OK


func _readable(path: String) -> bool:
	return typeof(JSON.parse_string(FileAccess.get_file_as_string(path))) == TYPE_DICTIONARY


func _files(n: int) -> Array:
	return _candidates(n).filter(func(path): return FileAccess.file_exists(path))


## A farm none of whose files can be read is moved aside under a plain name rather than saved over, so it can be rescued.
func _set_aside_unreadable(n: int) -> bool:
	var found := _files(n)
	if found.is_empty() or found.any(_readable):
		return true
	var stamp := int(Time.get_unix_time_from_system())
	for path in found:
		if not _move(path, "%s.unreadable-%d" % [path, stamp]):
			return false
	push_error("Farm %d could not be read, so its files were kept beside it as .unreadable copies" % n)
	return true


func load_game(n: int) -> void:
	slot = n
	pending_summary = {}
	for path in _load_order(n):
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("Save %s is unreadable, trying the next backup" % path)
			continue
		Game.from_dict(parsed)
		has_farm = true
		var away := Time.get_unix_time_from_system() - float(parsed.get("saved_at", Time.get_unix_time_from_system()))
		# With offline progress switched off, the estate simply waits exactly as it was left. Any time away is caught up,
		# so work that finished while the game was closed is finished on opening; only a longer absence gets a summary.
		if Settings.offline_progress and away > 0.0:
			var summary := Game.simulate_offline(away)
			if away >= float(Data.get_value("offline.min_seconds_for_summary", 30)):
				pending_summary = summary
		return
	has_farm = false
	Game.new_game()


## What the farm in a slot is, for the farm list: its name, day and villa, or an empty dictionary for an empty slot.
func slot_info(n: int) -> Dictionary:
	for path in _load_order(n):
		if not FileAccess.file_exists(path):
			continue
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var cal: Dictionary = d.get("calendar", {})
		return {"name": String(d.get("farm_name", "")), "day": int(cal.get("day", 0)) + 1, "villa": int(d.get("villa_stage", 1)), "saved_at": float(d.get("saved_at", 0))}
	return {}


## The first slot with nothing in it, or 0 when every slot holds a farm; a farm that cannot be read still holds its slot.
func free_slot() -> int:
	for n in range(1, SLOTS + 1):
		if _files(n).is_empty() and slot_info(n).is_empty():
			return n
	return 0


## Whether any slot holds a farm that can be played.
func any_farm() -> bool:
	return range(1, SLOTS + 1).any(func(n): return not slot_info(n).is_empty())


## Plays the farm in a slot: the scene starts again around it. The farm already open carries on with its summary of time away.
func play(n: int) -> void:
	if n != slot or not has_farm:
		save_game()
		load_game(n)
		_remember_slot()
	title_done = true
	get_tree().reload_current_scene()


## Starts a new farm with its name in an empty slot and plays it from the first-day welcome.
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


## Deletes the farm in a slot and its backups for good; deleting the farm being played moves on to another, if any.
func delete(n: int) -> void:
	_remove(n)
	if n != slot:
		return
	for other in range(1, SLOTS + 1):
		if not slot_info(other).is_empty():
			load_game(other)
			_remember_slot()
			return
	has_farm = false
	Game.new_game()


## Starts the farm being played over from nothing, in the same slot.
func reset() -> void:
	_remove(slot)
	has_farm = false
	Game.new_game()


func _remove(n: int) -> void:
	if not enabled:
		return
	for path in _candidates(n) + [path_for(n) + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _candidates(n: int) -> Array:
	var list := [path_for(n)]
	for i in range(1, BACKUPS + 1):
		list.append("%s.bak%d" % [path_for(n), i])
	return list


## The files a farm is read from, best first: a save cut off before its .tmp replaced the farm file leaves the newest copy there.
func _load_order(n: int) -> Array:
	var list := _candidates(n)
	var tmp := path_for(n) + ".tmp"
	if FileAccess.file_exists(tmp) and _saved_at(tmp) > _saved_at(path_for(n)):
		list.push_front(tmp)
	return list


## When a save was made, or -1 for a file that is missing or not whole, so a half-written .tmp never wins.
func _saved_at(path: String) -> float:
	if not FileAccess.file_exists(path):
		return -1.0
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return float(d.get("saved_at", 0)) if typeof(d) == TYPE_DICTIONARY else -1.0


## Moves each backup one along, the save itself becoming the newest, once the newest backup has aged.
func _rotate_backups(path: String) -> void:
	var newest := path + ".bak1"
	if FileAccess.file_exists(newest) and Time.get_unix_time_from_system() - FileAccess.get_modified_time(newest) < BACKUP_EVERY:
		return
	if not FileAccess.file_exists(path) or not _readable(path):
		return
	# Renaming rather than copying leaves each older copy's contents untouched on the disk.
	for i in range(BACKUPS - 1, 0, -1):
		var older := "%s.bak%d" % [path, i]
		if FileAccess.file_exists(older) and not _move(older, "%s.bak%d" % [path, i + 1]):
			return
	_move(path, newest)
