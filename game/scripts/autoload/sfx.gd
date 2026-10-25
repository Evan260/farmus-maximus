extends Node
## Plays short sound effects from a small pool of players, with a little random pitch so repeats never sound identical.

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

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String, volume_db := 0.0, pitch_jitter := 0.06) -> void:
	if not SOUNDS.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = SOUNDS[sound]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
