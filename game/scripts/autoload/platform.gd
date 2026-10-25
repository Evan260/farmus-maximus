extends Node
## The link to the store and the desktop: Steam achievements when the game runs through Steam, and taskbar alerts.

var _steam: Object = null


func _ready() -> void:
	# GodotSteam adds a "Steam" singleton; without it (an itch build, or the editor) achievements stay in the save only.
	if Engine.has_singleton("Steam"):
		_steam = Engine.get_singleton("Steam")
		_steam.call("steamInit")
	Game.achievement_unlocked.connect(_on_achievement)
	Game.cart_returned.connect(func(_c): alert())
	Game.storage_full.connect(alert)
	Game.order_added.connect(alert)
	sync_achievements.call_deferred()


func _process(_delta: float) -> void:
	if _steam:
		_steam.call("run_callbacks")


## Sends every achievement in the save to Steam, so ones earned offline or before Steam was available still count.
func sync_achievements() -> void:
	for id in Game.journal.achievements:
		_unlock_on_steam(String(id))


func _on_achievement(a: Dictionary) -> void:
	_unlock_on_steam(String(a["id"]))


func _unlock_on_steam(id: String) -> void:
	if _steam:
		_steam.call("setAchievement", id)
		_steam.call("storeStats")


## Flashes the taskbar button when something happens while the player is in another window.
func alert() -> void:
	if Settings.notifications and not get_window().has_focus():
		DisplayServer.window_request_attention()
