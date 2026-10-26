extends Node
## All game audio: sound effects from a small player pool, ambience that follows the time of day, and the volume settings.

## Sound effects are found by file name, so a new sound is added by dropping a file named after it into this folder.
## Files named like cluck_1, cluck_2 are takes of one sound, "cluck", and one is picked at random each time.
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const BUSES := ["Music", "Ambience", "Effects"]
const SETTINGS_PATH := "user://settings.json"

## Volume per bus, 0 to 1.
var volumes := {"Music": 0.7, "Ambience": 0.45, "Effects": 0.8}
var _sounds := {}
var _takes := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _tracks: Array = []
var _music_gap := 20.0
var _rain: AudioStreamPlayer
var _next := 0
var _day: AudioStreamPlayer
var _night: AudioStreamPlayer


func _ready() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		_players.append(p)
	_sounds = _scan(SFX_DIR)
	for file in _sounds.keys():
		var base := String(file).rsplit("_", true, 1)
		if base.size() == 2 and base[1].is_valid_int():
			if not _takes.has(base[0]):
				_takes[base[0]] = []
			_takes[base[0]].append(_sounds[file])
	_day = _ambience("res://assets/audio/ambience/day.wav")
	_night = _ambience("res://assets/audio/ambience/night.wav")
	_rain = _ambience("res://assets/audio/ambience/rain.wav")
	_tracks = _scan(MUSIC_DIR).values()
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.finished.connect(func(): _music_gap = randf_range(120.0, 300.0))
	add_child(_music)
	_load_settings()


func _process(delta: float) -> void:
	var night := Lighting.night_amount(Game.day_time)
	var rain := 1.0 if Game.calendar.raining() else 0.0
	if _day:
		_day.volume_db = linear_to_db(maxf((1.0 - night) * (1.0 - rain * 0.6), 0.001))
	if _night:
		_night.volume_db = linear_to_db(maxf(night * (1.0 - rain * 0.6), 0.001))
	if _rain:
		_rain.volume_db = move_toward(_rain.volume_db, 0.0 if rain > 0.0 else -60.0, delta * 15.0)
	# Music plays a track, then leaves several minutes of plain ambience before the next, so it never wears thin.
	if not _tracks.is_empty() and not _music.playing:
		_music_gap -= delta
		if _music_gap <= 0.0:
			_music.stream = _tracks[randi() % _tracks.size()]
			_music.play()


func play(sound: String, volume_db := 0.0, pitch_jitter := 0.06) -> AudioStreamPlayer:
	var stream: AudioStream = null
	if _takes.has(sound):
		stream = _takes[sound][randi() % _takes[sound].size()]
	elif _sounds.has(sound):
		stream = _sounds[sound]
	if stream == null:
		return null
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
	return p


## Lets a sound that is still playing die away, such as the cart's wheels as the scene changes.
func fade_out(p: AudioStreamPlayer, seconds := 1.0) -> void:
	if p == null or not p.playing:
		return
	var stream := p.stream
	var fade := p.create_tween()
	fade.tween_property(p, "volume_db", -40.0, seconds).set_ease(Tween.EASE_IN)
	fade.tween_callback(func(): if p.stream == stream: p.stop())


func set_volume(bus: String, value: float) -> void:
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply(bus)
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"volumes": volumes}))


func _apply(bus: String) -> void:
	var idx := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(volumes[bus], 0.0001)))
	AudioServer.set_bus_mute(idx, volumes[bus] <= 0.001)


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			for bus in parsed.get("volumes", {}):
				if volumes.has(bus):
					volumes[bus] = float(parsed["volumes"][bus])
	for bus in BUSES:
		_apply(bus)


func _scan(dir: String) -> Dictionary:
	var found := {}
	if not DirAccess.dir_exists_absolute(dir):
		return found
	for file in ResourceLoader.list_directory(dir):
		if file.get_extension() in ["wav", "ogg", "mp3"]:
			found[file.get_basename()] = load(dir + file)
	return found


func _ambience(path: String) -> AudioStreamPlayer:
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	# The loops are made seamless when synthesized, so they repeat end to start without a gap.
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	elif "loop" in stream:
		stream.set("loop", true)
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Ambience"
	add_child(p)
	p.play()
	return p
