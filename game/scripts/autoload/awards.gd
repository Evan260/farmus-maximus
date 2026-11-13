extends Node
## The link to the store and the desktop: Steam achievements and rich presence when the game runs through Steam, the
## demo's store page, and taskbar alerts.

## How often, in seconds, the rich presence is looked at; Steam is only told when it has changed.
const PRESENCE_EVERY := 2.0

var _steam: Object = null
## The rich presence keys last sent to Steam.
var _presence := {}
var _presence_wait := 0.0


func _ready() -> void:
	if Engine.has_singleton("Steam"):
		var steam: Object = Engine.get_singleton("Steam")
		var started: Dictionary = steam.call("steamInitEx")
		# Without the Steam client running the game plays on, and achievements stay in the save until a later start.
		if int(started.get("status", -1)) == 0:
			_steam = steam
		else:
			print_verbose("Steam unavailable: ", started.get("verbal", ""))
	Game.achievement_unlocked.connect(_on_achievement)
	Game.cart_returned.connect(func(_c): alert())
	Game.storage_full.connect(alert)
	Game.order_added.connect(alert)
	sync_achievements.call_deferred()


func _process(delta: float) -> void:
	if _steam:
		_steam.call("run_callbacks")
		_presence_wait -= delta
		if _presence_wait <= 0.0:
			_presence_wait = PRESENCE_EVERY
			update_presence()


## What a Steam friend sees the player doing, as tokens of tools/steam/rich_presence.vdf and the values they fill in.
func presence() -> Dictionary:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.title_open():
		return {"steam_display": "#Title"}
	if is_instance_valid(Dev.m) and Dev.m.market.visible:
		return {"steam_display": "#Town"}
	if is_instance_valid(Dev.m) and Dev.m.interior.visible:
		return {"steam_display": "#Inside"}
	# The values come before steam_display, which Steam shows as soon as it is set.
	return {"stage": str(clampi(Game.villa_stage, 1, Game.villa_stages().size())), "day": str(Game.calendar.day + 1),
		"steam_display": "#Estate"}


## Sends Steam only the rich presence keys that changed since the last time.
func update_presence() -> void:
	if not _steam:
		return
	var now := presence()
	for key in now:
		if _presence.get(key) != now[key]:
			_steam.call("setRichPresence", key, now[key])
	_presence = now


## Sends every achievement in the save to Steam, so ones earned offline or before Steam was available still count.
func sync_achievements() -> void:
	for id in Game.journal.achievements:
		_unlock_on_steam(String(id))


func _on_achievement(a: Dictionary) -> void:
	_unlock_on_steam(String(a["id"]))


func _unlock_on_steam(id: String) -> void:
	# The demo and maxed farms, tests and other trial runs grant achievements freely, so none of theirs reach Steam.
	if _steam and not Dev.no_save():
		_steam.call("setAchievement", id)
		_steam.call("storeStats")


## The full game's Steam app id, which the demo's wishlist buttons open; 0, which hides them, until Steamworks gives it.
func full_game_app_id() -> int:
	return int(Dev.get_arg("app-id", str(Data.get_value("demo.full_game_app_id", 0))))


## The full game's store page: in the Steam client when Steam is running, otherwise on the Steam website.
func store_url() -> String:
	return ("steam://store/%d" if _steam else "https://store.steampowered.com/app/%d/") % full_game_app_id()


func open_store() -> void:
	OS.shell_open(store_url())


## Flashes the taskbar button when something happens while the player is in another window.
func alert() -> void:
	if Settings.notifications and not get_window().has_focus():
		DisplayServer.window_request_attention()
