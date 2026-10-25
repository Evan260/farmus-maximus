extends Node
## All game audio: sound effects from a small player pool, ambience that follows the time of day, and the volume settings.

const SOUNDS := {
	"plant": preload("res://assets/audio/sfx/plant.wav"),
	"harvest": preload("res://assets/audio/sfx/harvest.wav"),
	"coins": preload("res://assets/audio/sfx/coins.wav"),
	"cart": preload("res://assets/audio/sfx/cart.wav"),
	"unlock": preload("res://assets/audio/sfx/unlock.wav"),
	"pet": preload("res://assets/audio/sfx/pet.wav"),
	"hammer": preload("res://assets/audio/sfx/hammer.wav"),
	"villa_complete": preload("res://assets/audio/sfx/villa_complete.wav"),
	"click": preload("res://assets/audio/sfx/click.wav"),
	"nope": preload("res://assets/audio/sfx/nope.wav"),
}
const BUSES := ["Music", "Ambience", "Effects"]
const SETTINGS_PATH := "user://settings.json"

## Volume per bus, 0 to 1.
var volumes := {"Music": 0.7, "Ambience": 0.6, "Effects": 0.8}
var _players: Array[AudioStreamPlayer] = []
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
	_day = _ambience("res://assets/audio/ambience/day.wav")
	_night = _ambience("res://assets/audio/ambience/night.wav")
	_load_settings()


func _process(_delta: float) -> void:
	var night := Lighting.night_amount(Game.day_time)
	_day.volume_db = linear_to_db(maxf(1.0 - night, 0.001))
	_night.volume_db = linear_to_db(maxf(night, 0.001))


func play(sound: String, volume_db := 0.0, pitch_jitter := 0.06) -> void:
	if not SOUNDS.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = SOUNDS[sound]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


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


func _ambience(path: String) -> AudioStreamPlayer:
	var stream: AudioStreamWAV = load(path)
	# The loops are made seamless when synthesized, so they repeat end to start without a gap.
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Ambience"
	add_child(p)
	p.play()
	return p
